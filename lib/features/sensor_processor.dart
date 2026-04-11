// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../bmlib/bm_lib.dart';

class SensorProcessor {
  final BmLib _lib;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  Timer? _orientationTimer;
  MagnetometerEvent? _lastMag;
  AccelerometerEvent? _lastAccel;

  int _orientationIntervalMs = 50;
  bool _orientationEnabled = false;
  int _accelMsg = 0;
  int _accelIntervalMs = 100;
  int _gyroIntervalMs = 100;
  int _lastAccelSentAt = 0;
  int _lastGyroSentAt = 0;

  int controlReliability = 0;

  ffi.Pointer<ffi.Void> Function()? getEngine;
  String? Function()? getActiveGameDeviceId;
  void Function(List<BmAction>)? sendActions;

  SensorProcessor(this._lib);

  void startAccel() {
    if (_accelSub != null) return;
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
          _lastAccel = event;
          final now = DateTime.now().millisecondsSinceEpoch;
          final aligned = gridAlign(now, _lastAccelSentAt, _accelIntervalMs);
          if (aligned < 0) return;
          _lastAccelSentAt = aligned;
          final fx = event.x / -9.80665;
          final fy = event.y / -9.80665;
          final fz = event.z / -9.80665;
          double x = fx, y = fy, z = fz;
          if (_accelMsg == 1) {
            x = -fy;
            y = fx;
          } else if (_accelMsg == 2) {
            x = -fx;
            y = -fy;
          } else if (_accelMsg == 3) {
            x = fy;
            y = -fx;
          }
          final gameDeviceId = getActiveGameDeviceId?.call();
          if (gameDeviceId == null) return;
          final actions = _lib.makeAccel(
            getEngine!(),
            gameDeviceId,
            x,
            y,
            z,
            controlReliability,
          );
          sendActions?.call(actions);
        });
  }

  void stopAccel() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void startMag() {
    if (_magSub != null) return;
    _magSub =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen((event) {
          _lastMag = event;
        });
  }

  void stopMag() {
    _magSub?.cancel();
    _magSub = null;
  }

  void startGyro() {
    if (_gyroSub != null) return;
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((event) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final aligned = gridAlign(now, _lastGyroSentAt, _gyroIntervalMs);
          if (aligned < 0) return;
          _lastGyroSentAt = aligned;
          final gameDeviceId = getActiveGameDeviceId?.call();
          if (gameDeviceId == null) return;
          double x = event.x, y = event.y, z = event.z;
          if (_accelMsg == 1) {
            x = -event.y;
            y = event.x;
          } else if (_accelMsg == 2) {
            x = -event.x;
            y = -event.y;
          } else if (_accelMsg == 3) {
            x = event.y;
            y = -event.x;
          }
          final actions = _lib.makeGyro(
            getEngine!(),
            gameDeviceId,
            x,
            y,
            z,
            controlReliability,
          );
          sendActions?.call(actions);
        });
  }

  void stopGyro() {
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  void startOrientation() {
    if (_orientationTimer != null) return;
    startAccel();
    startMag();
    _orientationTimer = Timer.periodic(
      Duration(milliseconds: _orientationIntervalMs),
      (_) {
        if (!_orientationEnabled) return;
        final gameDeviceId = getActiveGameDeviceId?.call();
        if (gameDeviceId == null) return;
        final accel = _lastAccel;
        if (accel == null) return;
        final quat = _computeQuaternion(accel, _lastMag);

        final actions = _lib.makeOrientation(
          getEngine!(),
          gameDeviceId,
          quat[0],
          quat[1],
          quat[2],
          quat[3],
          controlReliability,
        );
        sendActions?.call(actions);
      },
    );
  }

  void stopOrientation() {
    _orientationTimer?.cancel();
    _orientationTimer = null;
  }

  void setDisplayRotation(int rotation) {
    _accelMsg = rotation.clamp(0, 3);
  }

  void setAccelIntervalMs(int ms) {
    _accelIntervalMs = ms;
  }

  void setGyroIntervalMs(int ms) {
    _gyroIntervalMs = ms;
  }

  bool get orientationEnabled => _orientationEnabled;

  void setOrientationEnabled(bool enabled) {
    _orientationEnabled = enabled;
    if (enabled) {
      startOrientation();
    } else {
      stopOrientation();
    }
  }

  void setOrientationIntervalMs(int ms) {
    _orientationIntervalMs = ms.clamp(10, 1000);
    if (_orientationTimer != null) {
      stopOrientation();
      if (_orientationEnabled) {
        startOrientation();
      }
    }
  }

  void enableAccelerometer(bool enabled) {
    if (enabled) {
      startAccel();
    } else {
      stopAccel();
    }
  }

  void enableGyro(bool enabled) {
    if (enabled) {
      startGyro();
    } else {
      stopGyro();
    }
  }

  void stopAll() {
    stopAccel();
    stopGyro();
    stopMag();
    stopOrientation();
  }

  static int gridAlign(int now, int lastDispatch, int intervalMs) {
    final nextAt = lastDispatch + intervalMs;
    if (now >= nextAt) {
      if (intervalMs > 0) {
        return (((now - nextAt) ~/ intervalMs) * intervalMs) + nextAt;
      }
      return now;
    }
    return -1;
  }

  List<double> _computeQuaternion(
    AccelerometerEvent accel,
    MagnetometerEvent? mag,
  ) {
    final ax = accel.x;
    final ay = accel.y;
    final az = accel.z;

    final g = sqrt(ax * ax + ay * ay + az * az);
    if (g == 0) return [0, 0, 0, 1];

    final nx = ax / g;
    final ny = ay / g;
    final nz = az / g;

    double yaw = 0;
    if (mag != null) {
      final mx = mag.x;
      final my = mag.y;
      final mz = mag.z;
      final hx = my * nz - mz * ny;
      final hy = mz * nx - mx * nz;
      final hz = mx * ny - my * nx;
      final h = sqrt(hx * hx + hy * hy + hz * hz);
      if (h != 0) {
        final vx = hx / h;
        final vy = hy / h;
        yaw = atan2(vy, vx);
      }
    }

    final pitch = atan2(-nx, sqrt(ny * ny + nz * nz));
    final roll = atan2(ny, nz);

    final cy = cos(yaw * 0.5);
    final sy = sin(yaw * 0.5);
    final cp = cos(pitch * 0.5);
    final sp = sin(pitch * 0.5);
    final cr = cos(roll * 0.5);
    final sr = sin(roll * 0.5);

    final w = cr * cp * cy + sr * sp * sy;
    final x = sr * cp * cy - cr * sp * sy;
    final y = cr * sp * cy + sr * cp * sy;
    final z = cr * cp * sy - sr * sp * cy;

    return [x, y, z, w];
  }
}
