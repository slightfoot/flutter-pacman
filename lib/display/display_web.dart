import 'dart:async';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:flutter/material.dart';
import 'package:pacman/display/display.dart' as display;
import 'package:pacman/emulator.dart';
import 'package:pacman/utils/platform_view_web.dart';

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
  final _key = UniqueKey();
  CanvasElement _canvas;
  CanvasRenderingContext2D _context2d;

  final _video = Uint8ClampedList(VIDEO_WIDTH * VIDEO_HEIGHT * 4);
  ImageData _imageData;

  static const FRAME_COUNT = 8;
  var _lastFrameIndex = FRAME_COUNT - 1;
  var _writePos = 0;

  AudioContext _audioCtx;
  int _frameSize;
  ScriptProcessorNode _scriptNode;
  StreamSubscription _scriptSub;
  Float32List _audioFrame;
  Float32List _audioBuffer;

  @override
  void initState() {
    super.initState();
    _canvas = CanvasElement(width: VIDEO_WIDTH, height: VIDEO_HEIGHT);
    _context2d = _canvas.getContext('2d') as CanvasRenderingContext2D;
    _context2d.imageSmoothingEnabled = false;
    _imageData = _context2d.createImageData(VIDEO_WIDTH, VIDEO_HEIGHT);

    registerViewFactory('pacman-display-${_key.hashCode}', (int viewId) {
      return _canvas;
    });

    _audioCtx = AudioContext();
    debugPrint('sampleRate: ${_audioCtx.sampleRate}');

    _frameSize = 1024; //_audioCtx.sampleRate ~/ 60;
    _audioFrame = Float32List(_frameSize);
    _audioBuffer = Float32List(_frameSize * FRAME_COUNT);

    _scriptNode = _audioCtx.createScriptProcessor(_frameSize, 0, 1);
    _scriptNode.connectNode(_audioCtx.destination);
    _scriptSub = _scriptNode.onAudioProcess.listen(_onAudioProcess);
  }

  @override
  void dispose() {
    _scriptSub.cancel();
    super.dispose();
  }

  @override
  void outputAudioFrame(Duration elapsed, Duration delta) {
    if (widget.emulator.paused) {
      return;
    }
    widget.emulator.renderSound(_audioFrame, _audioCtx.sampleRate);
    var max = _frameSize * _lastFrameIndex;
    var i = 0;
    var j = _writePos;
    var len = _frameSize * FRAME_COUNT;
    while (i < _audioFrame.length) {
      if (j == max) {
        break;
      }
      _audioBuffer[j] = _audioFrame[i];
      i++;
      j = (j + 1) % len;
    }
    _writePos = j;
  }

  void _onAudioProcess(AudioProcessingEvent audioEvent) {
    try {
      final channelData = audioEvent.outputBuffer.getChannelData(0);
      _lastFrameIndex = (_lastFrameIndex + 1) % FRAME_COUNT;
      var j = _lastFrameIndex * _frameSize;
      for (var i = 0; i < _frameSize; i++, j++) {
        channelData[i] = _audioBuffer[j];
        _audioBuffer[j] = 0;
      }
    } catch (e) {
      debugPrint('Web Audio API error playing back audio: $e');
    }
  }

  @override
  void outputVideoFrame(Duration elapsed, Duration delta) {
    if (!widget.emulator.paused) {
      widget.emulator.renderVideo(_video.buffer.asUint32List());
      _imageData.data.setAll(0, _video);
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
