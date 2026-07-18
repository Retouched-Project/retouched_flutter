// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

final class DeviceInfo {
  static String generateAppId() {
    return 'c3eeomasdq211sxtlh89wjl2'; // Secret
  }

  static int platformDeviceTypeCode() {
    if (Platform.isAndroid) return 4;
    if (Platform.isIOS) return 2;
    return 0;
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
