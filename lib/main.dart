import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderErrorBox;
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:pacman/assets.dart';
import 'package:pacman/emulator.dart';

import 'config/configure.dart';
import 'display/display.dart';

void main() {
  configureApp();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pacman Emulator in Flutter',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFE311),
          background: Colors.black,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Game(),
    );
  }
}

@immutable
class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> with SingleTickerProviderStateMixin {
  final _displayKey = GlobalKey<DisplayState>();
  bool _loaded = false;
  bool _started = false;
  late ArcadeMachineEmu _emulator;
  late Future<void> _loading;
  late FocusNode _focusNode;
  late Ticker _ticker;
  Duration? _last;

  @override
  void initState() {
    super.initState();
    _emulator = ArcadeMachineEmu();
    _focusNode = FocusNode();
    _ticker = createTicker(_onTick);
    _loading = _emulator.init().then((_) {
      setState(() => _loaded = true);
    });
  }

  void _onStart() {
    if (!_loaded) return;
    setState(() => _started = true);
    _focusNode.requestFocus();
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - (_last ?? elapsed);
    if (delta > Duration.zero) {
      _emulator.tick();
      _displayKey.currentState!.outputVideoFrame(elapsed, delta);
      if (!_emulator.paused) {
        _displayKey.currentState!.outputAudioFrame(elapsed, delta);
      }
    }
    _last = elapsed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Material(
        color: Colors.black,
        child: Builder(
          builder: (BuildContext context) {
            if (_started) {
              return RawKeyboardListener(
                focusNode: _focusNode,
                onKey: (RawKeyEvent event) {
                  if (event is RawKeyDownEvent) {
                    _emulator.onKeyDown(event.logicalKey);
                  } else if (event is RawKeyUpEvent) {
                    _emulator.onKeyUp(event.logicalKey);
                  }
                },
                child: Display(
                  key: _displayKey,
                  emulator: _emulator,
                ),
              );
            } else {
              return Ink.image(
                image: const AssetImage(Assets.backgroundImage),
                repeat: ImageRepeat.repeat,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onStart,
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(Assets.logoImage),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            'Pacman Emulator',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 48.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        FutureBuilder<void>(
                          future: _loading,
                          builder: (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.hasError) {
                              return const Text('Sorry, cannot load game.');
                            } else if (snapshot.connectionState != ConnectionState.done) {
                              return const CircularProgressIndicator();
                            } else {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.0),
                                child: Text(
                                  'Press space to insert coin.\n'
                                  'Press 1 or 2 to start one or two player game.\n'
                                  'Use the arrow keys to move pacman.\n'
                                  'Press P to pause the game.\n'
                                  'Press numpad +/- changes volume.\n'
                                  '\n'
                                  'Cheaters:\nF1 for extra-life and F2 to skip level.\n\n'
                                  'Click to start\n\n',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
