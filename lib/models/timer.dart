import 'dart:async';

import 'package:flutter/material.dart';

class TimerModel extends ChangeNotifier {
  Timer _timer;
  int _remainingSeconds;

  // getters
  Timer get timer => _timer;
  int get remainingSeconds => _remainingSeconds;

  // kickOffTimer decrements remainingSeconds once per second until 0
  void kickOff({
    required durationSeconds,
    void Function() callback,
  }) {
    // cancel any previous timers
    cancel();
    _remainingSeconds = durationSeconds;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) {
        // when there is no remaining seconds
        if (_remainingSeconds == 0) {
          // cancel timer
          t.cancel();
          // set timer to null
          _timer = null;
          // execute callback if it exists
          if (callback != null) {
            callback();
          }
        } else {
          _remainingSeconds--;
          notifyListeners();
        }
      },
    );
    notifyListeners();
  }

  void cancel() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }
}
