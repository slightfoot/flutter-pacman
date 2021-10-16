import 'dart:typed_data';

import 'package:flutter/services.dart' show LogicalKeyboardKey, rootBundle;
import 'package:pacman/assets.dart';
import 'package:z80/z80.dart';

const int VIDEO_WIDTH = 224; // pixels
const int VIDEO_HEIGHT = 288; // pixels
const int VIDEO_FREQ = 60; // 60Hhz
const int CPU_CLOCK = 3072000; // 3MHz
const int CPU_CYCLES_PER_FRAME = CPU_CLOCK ~/ VIDEO_FREQ;
const int SOUND_FREQ = CPU_CLOCK ~/ 32; // = 96000 (96kHz)

const int R220 = 0x97;
const int R470 = 0x47;
const int R1000 = 0x21;

const int CHEAT_EXTRALIFE1 = 0x4E14;
const int CHEAT_EXTRALIFE2 = 0x4E15;
const int CHEAT_LEVELEND = 0x4E0E; // 0xF4

const int R0_ROM = 0x0000;
const int R0_ROMMAX = 0x4000;
const int R0_ROMCHARSET = 0x4000;
const int R0_ROMSPRITESET = 0x5000;
const int R0_RAMMAX = 0x5000;
const int R0_RAMMASK = 0x7FFF;
const int R0_RANGEMASK = 0xFFC0;

const int RW_VRAM_CHAR = 0x4000;
const int RW_VRAM_COLOR = 0x4400;
const int RW_RAM = 0x4800;
const int R0_IN0 = 0x5000;
const int R0_IN1 = 0x5040;
const int R0_DSW1 = 0x5080;
const int R0_WATCHDOG = 0x50C0;
const int RW_CHARMAP = 0x8000;
const int RW_SPRITEMAP = 0xC000;
const int RW_INTVAL = 0xFFFF;

const int W0_INTENABLE = 0x5000;
const int W0_SNDENABLE = 0x5001;
const int W0_AUXENABLE = 0x5002;
const int W0_SCREENFLIP = 0x5003;
const int W0_PLAY1LAMP = 0x5004;
const int W0_PLAY2LAMP = 0x5005;
const int W0_COINLOCK = 0x5006;
const int W0_COINCOUNT = 0x5007;
const int W0_WATCHDOG = 0x50C0;
const int W0_SNDREGS = 0x5040;
const int W0_SPRITEPOS = 0x5060;
const int W0_SPRITESHAPE = 0x4FF0;

const int DSW1_PLAYFREE = 0x00; // coins per play
const int DSW1_PLAY1COIN1GAME = 0x01;
const int DSW1_PLAY1COIN2GAMES = 0x02;
const int DSW1_PLAY2COINS1GAME = 0x03;
const int DSW1_PLAYMASK = 0x03;

const int DSW1_LIVES1 = 0x00; // lives per game
const int DSW1_LIVES2 = 0x04;
const int DSW1_LIVES3 = 0x08;
const int DSW1_LIVES5 = 0x0C;
const int DSW1_LIVESMASK = 0x0C;

const int DSW1_BONUS10000 = 0x00; // bonus life
const int DSW1_BONUS15000 = 0x10;
const int DSW1_BONUS20000 = 0x20;
const int DSW1_BONUSNONE = 0x30;
const int DSW1_BONUSMASK = 0x30;

const int DSW1_DIFFHARD = 0x00; // difficulty
const int DSW1_DIFFNORMAL = 0x40;
const int DSW1_DIFFMASK = 0x40;

const int DSW1_GHOSTNAMESALT = 0x00; // ghost names
const int DSW1_GHOSTNAMESNORMAL = 0x80;
const int DSW1_GHOSTNAMESMASK = 0x80;

const int IN0_UP = 0x01;
const int IN0_LEFT = 0x02;
const int IN0_RIGHT = 0x04;
const int IN0_DOWN = 0x08;
const int IN0_DIP6 = 0x10;
const int IN0_COIN1 = 0x20;
const int IN0_COIN2 = 0x40;
const int IN0_CREDIT = 0x60;

const int IN1_UP = 0x01;
const int IN1_LEFT = 0x02;
const int IN1_RIGHT = 0x04;
const int IN1_DOWN = 0x08;
const int IN1_TEST = 0x10;
const int IN1_START1 = 0x20;
const int IN1_START2 = 0x40;
const int IN1_TABLE = 0x60;

const int SND_WAVFM = 0x05;
const int SND_FREQ1 = 0x10;
const int SND_FREQ2 = 0x11;
const int SND_FREQ3 = 0x12;
const int SND_FREQ4 = 0x13;
const int SND_FREQ5 = 0x14;
const int SND_VOL = 0x15;

class ArcadeMachineEmu implements Z80Core {
  ArcadeMachineEmu() {
    _cpu = Z80CPU(this);
    _ram = Uint8ClampedList(0x10000); // 64KB
  }

  Z80CPU _cpu;
  Uint8ClampedList _ram;
  Uint8ClampedList _soundData;
  List<int> _palette;
  int _cycles = 0;
  bool _paused = false;

  bool _muted = false;
  double _masterVolume = 0.5;

  bool get paused => _paused;

  Future<void> init() async {
    var base = 0x0000;
    for (final asset in [
      Assets.rom_data_6e,
      Assets.rom_data_6f,
      Assets.rom_data_6h,
      Assets.rom_data_6j,
      Assets.rom_data_5e,
      Assets.rom_data_5f,
    ]) {
      _ram.setAll(base, await loadAsset(asset));
      base += 0x1000;
    }

    createPalette(
      await loadAsset(Assets.palette_data),
      await loadAsset(Assets.color_data),
    );

    decodeVideoRoms(
      await loadAsset(Assets.rom_data_5e),
      await loadAsset(Assets.rom_data_5f),
    );

    _soundData = await loadAsset(Assets.sound_data);

    _ram[W0_INTENABLE] = 0x00;
    _ram[RW_INTVAL] = 0x00;
    _ram[R0_IN0] = 0xFF;
    _ram[R0_IN1] = 0xFF;
    _ram[R0_DSW1] = DSW1_PLAY1COIN1GAME |
        DSW1_BONUS10000 |
        DSW1_LIVES3 |
        DSW1_DIFFNORMAL |
        DSW1_GHOSTNAMESNORMAL;

    muteSound();
  }

  Future<Uint8ClampedList> loadAsset(String asset) async {
    final data = await rootBundle.load(asset);
    return data.buffer.asUint8ClampedList();
  }

  void createPalette(List<int> palRom, List<int> colorRom) {
    final palette = List.filled(16, 0, growable: false);
    for (int i = 0; i < 16; i++) {
      int v = palRom[i];
      int r = R1000 * ((v >> 0) & 1) + R470 * ((v >> 1) & 1) + R220 * ((v >> 2) & 1);
      int g = R1000 * ((v >> 3) & 1) + R470 * ((v >> 4) & 1) + R220 * ((v >> 5) & 1);
      int b = R1000 * 0 + R470 * ((v >> 6) & 1) + R220 * ((v >> 7) & 1);
      palette[i] = 0xff000000 | (r & 0xff) | ((g & 0xff) << 8) | ((b & 0xff) << 16);
    }
    _palette = List.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      _palette[i] = palette[colorRom[i] & 0x0F];
    }
  }

  void decodeVideoRoms(List<int> charSet, List<int> spriteSet) {
    for (int i = 0; i < 256; i++) {
      final src = charSet.sublist(i * 16);
      final dst = _ram.buffer.asUint8ClampedList(RW_CHARMAP + i * 64);
      decodePixels(src, 0, dst, 0, 4, 8);
      decodePixels(src, 8, dst, 0, 0, 8);
    }
    for (int i = 0; i < 64; i++) {
      final src = spriteSet.sublist(i * 64);
      final dst = _ram.buffer.asUint8ClampedList(RW_SPRITEMAP + i * 256);
      decodePixels(src, 0, dst, 8, 12, 16);
      decodePixels(src, 8, dst, 8, 0, 16);
      decodePixels(src, 16, dst, 8, 4, 16);
      decodePixels(src, 24, dst, 8, 8, 16);
      decodePixels(src, 32, dst, 0, 12, 16);
      decodePixels(src, 40, dst, 0, 0, 16);
      decodePixels(src, 48, dst, 0, 4, 16);
      decodePixels(src, 56, dst, 0, 8, 16);
    }
  }

  void decodePixels(
      List<int> srcData, int srcOffset, List<int> charBuffer, int x, int y, int width) {
    int offset = srcOffset;
    for (int dx = 7; dx >= 0; dx--) {
      int b = srcData[offset++];
      for (int dy = 3; dy >= 0; dy--) {
        charBuffer[(y + dy) * width + (x + dx)] = ((b >> 3) & 2) | (b & 1);
        b >>= 1;
      }
    }
  }

  void renderVideo(Uint32List videoBuffer) {
    final vrChar = _ram.buffer.asUint8ClampedList(RW_VRAM_CHAR);
    final vrColor = _ram.buffer.asUint8ClampedList(RW_VRAM_COLOR);
    for (int i = 2, x = (27 * 8); i < 30; i++, x -= 8) {
      _renderChar(videoBuffer, vrChar[0x3C0 + i], x, (0 * 8), vrColor[0x3C0 + i], VIDEO_WIDTH);
      _renderChar(videoBuffer, vrChar[0x3E0 + i], x, (1 * 8), vrColor[0x3E0 + i], VIDEO_WIDTH);
      _renderChar(videoBuffer, vrChar[0x000 + i], x, (34 * 8), vrColor[0x000 + i], VIDEO_WIDTH);
      _renderChar(videoBuffer, vrChar[0x020 + i], x, (35 * 8), vrColor[0x020 + i], VIDEO_WIDTH);
    }
    for (int i = 0x40, x = (28 * 8), y = 0; i < 0x3C0; i++, y += 8) {
      if (i % 0x20 == 0) {
        y = (2 * 8);
        x -= 8;
      }
      _renderChar(videoBuffer, vrChar[i], x, y, vrColor[i], VIDEO_WIDTH);
    }
    for (int i = 7; i >= 0; i--) {
      _renderSprite(videoBuffer, i);
    }
  }

  void _renderChar(List<int> buffer, int index, int ox, int oy, int color, int pitch) {
    int offset = (oy * pitch) + ox;
    index *= 64;
    color = (color & 0x3F) * 4;
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        buffer[offset + x] = _palette[_ram[RW_CHARMAP + index] + color];
        index++;
      }
      offset += pitch;
    }
  }

  void _renderSprite(List<int> buffer, int index) {
    final spriteShape = _ram[W0_SPRITESHAPE + (index * 2) + 0] >> 2; // Shape
    final spriteMode = _ram[W0_SPRITESHAPE + (index * 2) + 0] & 3; // Shape
    final spriteColor = _ram[W0_SPRITESHAPE + (index * 2) + 1]; // Color
    final spriteY = (256 + 16) - _ram[W0_SPRITEPOS + (index * 2) + 1]; // Pos Y
    int spriteX = (256 - 17) - _ram[W0_SPRITEPOS + (index * 2) + 0]; // Pos X
    if (index <= 2) {
      spriteX--;
    }
    if ((spriteColor == 0) ||
        (spriteX >= VIDEO_WIDTH) ||
        (spriteY < 16) ||
        (spriteY >= (VIDEO_HEIGHT - 32))) {
      return;
    }

    final startX = (spriteX < 0) ? 0 : spriteX;
    final endX = (spriteX < (VIDEO_WIDTH - 16)) ? spriteX + 16 : VIDEO_WIDTH;
    final color = (spriteColor & 0x3F) * 4;
    final spriteMap = _ram.buffer.asUint8ClampedList(RW_SPRITEMAP + (spriteShape & 0x3F) * 256);

    int offset = VIDEO_WIDTH * spriteY;
    for (int y = 0; y < 16; y++) {
      for (int x = startX; x < endX; x++) {
        int c = 0, o = (x - spriteX);
        switch (spriteMode) {
          case 0:
            c = spriteMap[o + y * 16];
            break;
          case 1:
            c = spriteMap[o + (15 - y) * 16];
            break;
          case 2:
            c = spriteMap[15 - o + y * 16];
            break;
          case 3:
            c = spriteMap[15 - o + (15 - y) * 16];
            break;
        }
        if (c != 0) {
          buffer[offset + x] = _palette[(color + c & 0xFF)];
        }
      }
      offset += VIDEO_WIDTH;
    }
  }

  void onKeyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) {
      _ram[R0_IN0] &= ~IN0_COIN1;
    } else if (key == LogicalKeyboardKey.digit1) {
      _ram[R0_IN1] &= ~IN1_START1;
    } else if (key == LogicalKeyboardKey.digit2) {
      _ram[R0_IN1] &= ~IN1_START2;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _ram[R0_IN0] &= ~IN0_UP;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _ram[R0_IN0] &= ~IN0_DOWN;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _ram[R0_IN0] &= ~IN0_RIGHT;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _ram[R0_IN0] &= ~IN0_LEFT;
    }
  }

  void onKeyUp(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) {
      _ram[R0_IN0] |= IN0_COIN1;
    } else if (key == LogicalKeyboardKey.digit1) {
      _ram[R0_IN1] |= IN1_START1;
    } else if (key == LogicalKeyboardKey.digit2) {
      _ram[R0_IN1] |= IN1_START2;
    } else if (key == LogicalKeyboardKey.keyP) {
      _paused = !_paused;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _ram[R0_IN0] |= IN0_UP;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _ram[R0_IN0] |= IN0_DOWN;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      _ram[R0_IN0] |= IN0_RIGHT;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _ram[R0_IN0] |= IN0_LEFT;
    } else if (key == LogicalKeyboardKey.f1) {
      _ram[CHEAT_EXTRALIFE1]++;
      _ram[CHEAT_EXTRALIFE2]++;
    } else if (key == LogicalKeyboardKey.f2) {
      _ram[CHEAT_LEVELEND] = 0xF4;
    } else if (key == LogicalKeyboardKey.audioVolumeDown ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _masterVolume = (_masterVolume - 0.1).clamp(0.0, 1.0);
    } else if (key == LogicalKeyboardKey.audioVolumeUp ||
        key == LogicalKeyboardKey.numpadAdd) {
      _masterVolume = (_masterVolume + 0.1).clamp(0.0, 1.0);
    } else if (key == LogicalKeyboardKey.audioVolumeMute || //
        key == LogicalKeyboardKey.numpad0) {
      _muted = !_muted;
    }
  }

  void tick() {
    if (!_paused) {
      if (_ram[W0_INTENABLE] != 0) {
        _cpu.interrupt(false, _ram[RW_INTVAL]);
      }
      _cycles += CPU_CYCLES_PER_FRAME;
      while (_cycles > 0) {
        _cycles -= _cpu.runInstruction();
      }
    }
  }

  final List<int> waveOffset = [0, 0, 0];

  void muteSound() {
    int baseReg = 0;
    for (int voice = 0; voice < 3; voice++) {
      _ram[W0_SNDREGS + (baseReg + SND_VOL)] = 0;
      baseReg += 5;
    }
  }

  /// Generates floating point PCM at sampleRate
  void renderSound(Float32List buf, int sampleRate) {
    _ram[W0_SNDREGS];

    final divisor = ((SOUND_FREQ << 10) ~/ sampleRate);
    buf.fillRange(0, buf.length, 0.0);
    int baseReg = 0;
    for (int voice = 0; voice < 3; voice++) {
      final waveform = (_ram[W0_SNDREGS + (baseReg + SND_WAVFM)] & 0x07);
      final volume = _muted ? 0 : (_ram[W0_SNDREGS + (baseReg + SND_VOL)] & 0x0F);
      int freq = ((_ram[W0_SNDREGS + (baseReg + SND_FREQ5)] & 0x0F) << 16);
      freq |= ((_ram[W0_SNDREGS + (baseReg + SND_FREQ4)] & 0x0F) << 12);
      freq |= ((_ram[W0_SNDREGS + (baseReg + SND_FREQ3)] & 0x0F) << 8);
      freq |= ((_ram[W0_SNDREGS + (baseReg + SND_FREQ2)] & 0x0F) << 4);
      if (voice == 0) {
        freq |= (_ram[W0_SNDREGS + (baseReg + SND_FREQ1)] & 0x0F);
      }
      if (freq > 0 && volume > 0) {
        final waveSample = _soundData.sublist(32 * waveform);
        final step = (freq * divisor);
        int offset = waveOffset[voice];
        for (int i = 0; i < buf.length; i++) {
          buf[i] += (waveSample[(offset >> 25) & 0x1F] * volume * _masterVolume);
          offset += step;
        }
        waveOffset[voice] = offset;
      }
      baseReg += 5;
    }
    for (int i = 0; i < buf.length; i++) {
      buf[i] /= 0xFF;
    }
  }

  @override
  int memRead(int address) {
    address &= R0_RAMMASK;
    if (address < R0_RAMMAX) return _ram[address];
    switch (address & R0_RANGEMASK) {
      case R0_IN0:
        return _ram[R0_IN0];
      case R0_IN1:
        return _ram[R0_IN1] & 0xF0 | _ram[R0_IN0] & 0x0F;
      case R0_DSW1:
        return _ram[R0_DSW1];
      case R0_WATCHDOG:
        return 0xFF;
      default:
        return _ram[address];
    }
  }

  @override
  void memWrite(int address, int value) {
    address &= R0_RAMMASK;
    if (address >= R0_ROM && address < R0_ROMMAX) {
      return;
    }
    if (address == R0_DSW1 || address == R0_IN0 || address == R0_IN1) {
      return;
    }
    _ram[address] = value;
  }

  @override
  int ioRead(int port) => 0;

  @override
  void ioWrite(int port, int value) {
    if ((port >> 8) == value) {
      _ram[RW_INTVAL] = value;
    }
  }
}
