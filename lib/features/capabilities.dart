// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class Capabilities {
  int? _override;
  int? _cached;

  void setOverride(int? mask) {
    _override = mask;
  }

  Future<int> get() async {
    if (_override != null) return _override!;
    if (_cached != null) return _cached!;

    final results = await Future.wait([
      _checkSensor(gyroscopeEventStream()),
      _checkSensor(magnetometerEventStream()),
    ]);

    int caps = 0;
    if (results[0] == true) caps |= 1;
    if (results[1] == true) caps |= 2;

    if (results.every((r) => r != null)) _cached = caps;
    return caps;
  }

  static Future<bool?> _checkSensor(Stream<dynamic> stream) async {
    final completer = Completer<bool?>();
    StreamSubscription? subscription;

    subscription = stream.listen(
      (event) {
        if (!completer.isCompleted) completer.complete(true);
      },
      onError: (error) {
        if (!completer.isCompleted) completer.complete(false);
      },
      cancelOnError: true,
    );

    try {
      return await completer.future.timeout(const Duration(milliseconds: 2000));
    } on TimeoutException {
      return null;
    } finally {
      await subscription.cancel();
    }
  }
}
