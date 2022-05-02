import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:pacman/win32_sound/win32_sound.dart';

Future<void> main() async {
  final count = WaveOut.deviceCount;
  for (var i = 0; i < count; i++) {
    final device = WaveOut(i);
    print('${device.deviceId}: ${device.name} -> ${device.supportsVolumeControl}');
    device.dispose();
  }

  final data = File('example/starwars.wav').readAsBytesSync().buffer.asUint8List(0x2C);
  final device = WaveOut.defaultDevice;
  for (final format in device.waveFormats) {
    print('$format');
  }

  try {
    if (device.isFormatSupported(SupportedWaveFormat.formatFloat44kM32b)) {
      device.open(SupportedWaveFormat.formatFloat44kM32b);
      device.volume = 0.5;
      //await device.write(data);
      for (var i = 0; i < data.length; i += 2048) {
        await device.write(data.sublist(i, math.min(i + 2048, data.length)));
        //print(
        //  'pos:${device.position}: '
        //  '${device.volume.toStringAsFixed(2)} '
        //  '${device.playbackRate.toStringAsFixed(2)}',
        //);
      }
      await device.wait();
    }
  } finally {
    await device.dispose();
  }
}
