// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../bmlib/bm_lib.dart' show DeviceType;

final class DeviceInfo {
  static String generateAppId() {
    return 'c3eeomasdq211sxtlh89wjl2'; // Secret
  }

  static DeviceType platformDeviceType() {
    if (Platform.isAndroid) return DeviceType.Android;
    if (Platform.isIOS) return DeviceType.IPhone;
    return DeviceType.Palm;
  }

  Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.name;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    } else {
      return 'Unknown';
    }
  }
}
