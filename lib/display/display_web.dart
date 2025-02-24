import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pacman/display/display.dart' as display;
import 'package:pacman/emulator.dart';
import 'package:pacman/utils/platform_view_web.dart';
import 'package:web/web.dart'
    show
        AudioContext,
        AudioProcessingEvent,
        CanvasRenderingContext2D,
        HTMLCanvasElement,
        ImageData,
        ScriptProcessorNode;

class Display extends StatefulWidget implements display.Display {
  const Display({
    super.key,
    required this.emulator,
  });

  final ArcadeMachineEmu emulator;

  @override
  display.DisplayState createState() => _DisplayState();
}

class _DisplayState extends display.DisplayState<Display> {
  final _key = UniqueKey();
  late HTMLCanvasElement _canvas;
  late CanvasRenderingContext2D _context2d;

  final _video = Uint8ClampedList(VIDEO_WIDTH * VIDEO_HEIGHT * 4);
  late ImageData _imageData;

  late AudioContext _audioCtx;
  late ScriptProcessorNode _scriptNode;

  @override
  void initState() {
    super.initState();
    _canvas = HTMLCanvasElement()
      ..width = VIDEO_WIDTH
      ..height = VIDEO_HEIGHT;
    _context2d = _canvas.getContext('2d') as CanvasRenderingContext2D;
    _context2d.imageSmoothingEnabled = false;
    _imageData = _context2d.createImageData(VIDEO_WIDTH.toJS, VIDEO_HEIGHT);

    registerViewFactory('pacman-display-${_key.hashCode}', (int viewId) {
      return _canvas;
    });

    _audioCtx = AudioContext();
    _scriptNode = _audioCtx.createScriptProcessor(1024, 0, 1);
    _scriptNode.connect(_audioCtx.destination);
    _scriptNode.onaudioprocess = _onAudioProcess.toJS;
  }

  @override
  void dispose() {
    _scriptNode.onaudioprocess = null;
    _audioCtx.close();
    super.dispose();
  }

  @override
  void outputAudioFrame(Duration elapsed, Duration delta) {
    // Skipping un-front rendering
  }

  void _onAudioProcess(AudioProcessingEvent audioEvent) {
    try {
      final channelData = audioEvent.outputBuffer.getChannelData(0).toDart;
      if (widget.emulator.paused) {
        channelData.fillRange(0, channelData.length, 0);
      } else {
        widget.emulator.renderSound(channelData, _audioCtx.sampleRate.toInt());
      }
    } catch (e) {
      debugPrint('Web Audio API error playing back audio: $e');
    }
  }

  @override
  void outputVideoFrame(Duration elapsed, Duration delta) {
    if (!widget.emulator.paused) {
      widget.emulator.renderVideo(_video.buffer.asUint32List());
      _imageData.data.toDart.setAll(0, _video);
      _context2d.putImageData(_imageData, 0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(
          width: VIDEO_WIDTH.toDouble(),
          height: VIDEO_HEIGHT.toDouble(),
        ),
        child: HtmlElementView(
          key: _key,
          viewType: 'pacman-display-${_key.hashCode}',
        ),
      ),
    );
  }
}
