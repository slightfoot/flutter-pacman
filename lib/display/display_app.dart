import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pacman/display/display.dart' as display;
import 'package:pacman/emulator.dart';
import 'package:pacman/win32_sound/win32_sound.dart';

class Display extends StatefulWidget implements display.Display {
  const Display({
    Key key,
    @required this.emulator,
  }) : super(key: key);

  final ArcadeMachineEmu emulator;

  @override
  display.DisplayState createState() => _DisplayState();
}

class _DisplayState extends display.DisplayState<Display> {
  final _video = Uint32List(VIDEO_WIDTH * VIDEO_HEIGHT);
  final _frame = ValueNotifier<ui.Image>(null);
  final _audioFrame = Float32List(44100 ~/ 60);

  double _frameCount = 0.0;
  Duration _elapsed = Duration.zero;
  Completer _completer;

  double get fps => (_frameCount / (_elapsed.inMicroseconds / Duration.microsecondsPerSecond));

  final WaveOut device = WaveOut(WAVE_MAPPER, bufferCount: 8, bufferSizeInBytes: 4 * (44100 ~/ 60));

  @override
  void initState() {
    super.initState();
    if (device.isFormatSupported(SupportedWaveFormat.formatFloat44kM32b)) {
      device.open(SupportedWaveFormat.formatFloat44kM32b);
      device.volume = 0.5;
    }
  }

  @override
  void dispose() {
    device.dispose();
    super.dispose();
  }

  @override
  void outputVideoFrame(Duration elapsed, Duration delta) {
    _elapsed = elapsed;
    if (!widget.emulator.paused) {
      if (_completer?.isCompleted ?? true) {
        _completer = Completer();
        _render().then((_) {
          _completer.complete();
          _frameCount++;
        }).catchError(_completer.completeError);
      }
    } else {
      _frameCount++;
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      _frame.notifyListeners();
    }
  }

  @override
  void outputAudioFrame(Duration elapsed, Duration delta) {
    widget.emulator.renderSound(_audioFrame, 44100);
    device.write(_audioFrame.buffer.asUint8List());
  }

  Future<void> _render() async {
    widget.emulator.renderVideo(_video);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(_video.buffer.asUint8List(), VIDEO_WIDTH, VIDEO_HEIGHT,
        ui.PixelFormat.rgba8888, completer.complete);
    _frame.value = await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ui.Image>(
      valueListenable: _frame,
      builder: (BuildContext context, ui.Image image, Widget child) {
        return Stack(
          children: [
            if (image != null)
              Positioned.fill(
                child: RepaintBoundary(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RawImage(
                      image: image,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8.0,
              top: 8.0,
              child: RepaintBoundary(
                child: SafeArea(
                  child: Text(
                    fps.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                      //shadows: <Shadow>[
                      //  Shadow(offset: Offset(2.0, 2.0), blurRadius: 3.0),
                      //],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
