import 'package:flutter/cupertino.dart';
import 'package:pacman/emulator.dart';

import 'display_app.dart' if (dart.library.html) 'display_web.dart' as display;

abstract class Display extends StatefulWidget {
  factory Display({
    Key? key,
    required ArcadeMachineEmu emulator,
  }) {
    return display.Display(
      key: key,
      emulator: emulator,
    );
  }

  @override
  DisplayState createState();
}

abstract class DisplayState<T extends Display> extends State<T> {
  void outputVideoFrame(Duration elapsed, Duration delta);

  void outputAudioFrame(Duration elapsed, Duration delta);
}
