// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class DeviceTypeCodes {
  static const int any = 0;
  static const int unity = 1;
  static const int iphone = 2;
  static const int flash = 3;
  static const int android = 4;
  static const int native = 5;
  static const int palm = 6;
  static const int server = 7;
}

class PacketTypeCodes {
  static const int data = 0;
  static const int ping = 1;
  static const int ack = 2;
  static const int echo = 3;
  static const int analysis = 4;
  static const int keepAlive = 5;
}

class RegistryEventKindCodes {
  static const int onRegister = 0;
  static const int onList = 1;
  static const int onHostConnected = 2;
  static const int onHostUpdate = 3;
  static const int onHostDisconnected = 4;
  static const int deviceConnectRequested = 5;
}

class ActionKindCodes {
  static const int send = 0;
  static const int updateRegistry = 1;
  static const int chunkSetComplete = 2;
  static const int chunkProgress = 3;
  static const int log = 4;
  static const int registryEvent = 5;
  static const int invoke = 6;
  static const int controlConfig = 7;
  static const int handshake = 8;
}

class BmRegistryInfo {
  final int slotId;
  final String appId;
  final int currentPlayers;
  final int maxPlayers;
  final int deviceType;
  final String deviceId;
  final String deviceName;
  final String address;
  final int unreliablePort;
  final int reliablePort;

  const BmRegistryInfo({
    required this.slotId,
    required this.appId,
    required this.currentPlayers,
    required this.maxPlayers,
    required this.deviceType,
    required this.deviceId,
    required this.deviceName,
    required this.address,
    required this.unreliablePort,
    required this.reliablePort,
  });
}

abstract class BmAction {
  const BmAction();
}

class BmSendAction extends BmAction {
  final String targetDeviceId;
  final int channel;
  final int reliability;
  final Uint8List payload;
  const BmSendAction(
    this.targetDeviceId,
    this.channel,
    this.reliability,
    this.payload,
  );
}

class BmChunkProgressAction extends BmAction {
  final String deviceId;
  final String setId;
  final int current;
  final int total;
  const BmChunkProgressAction(
    this.deviceId,
    this.setId,
    this.current,
    this.total,
  );
}

class BmChunkCompleteAction extends BmAction {
  final String deviceId;
  final String setId;
  final Uint8List blob;
  const BmChunkCompleteAction(this.deviceId, this.setId, this.blob);
}

class BmRegistryEventAction extends BmAction {
  final int kind;
  final bool? success;
  final List<BmRegistryInfo> infos;
  const BmRegistryEventAction(this.kind, this.success, this.infos);
}

class BmLogAction extends BmAction {
  final int level;
  final String message;
  const BmLogAction(this.level, this.message);
}

class BmInvokeAction extends BmAction {
  final String method;
  final String? returnMethod;
  final Uint8List rawBytes;
  const BmInvokeAction(this.method, this.returnMethod, this.rawBytes);
}

class BmHandshakeAction extends BmAction {
  final int current;
  final int minimum;
  const BmHandshakeAction(this.current, this.minimum);
}

class BmControlConfigAction extends BmAction {
  final bool? touchEnabled;
  final bool? accelEnabled;
  final bool? gyroEnabled;
  final bool? orientationEnabled;
  final int? touchIntervalMs;
  final int? accelIntervalMs;
  final int? gyroIntervalMs;
  final int? orientationIntervalMs;
  final int? touchReliability;
  final int? controlReliability;
  final int? controlMode;
  final String? portalId;
  final String? returnAppId;

  const BmControlConfigAction({
    required this.touchEnabled,
    required this.accelEnabled,
    required this.gyroEnabled,
    required this.orientationEnabled,
    required this.touchIntervalMs,
    required this.accelIntervalMs,
    required this.gyroIntervalMs,
    required this.orientationIntervalMs,
    required this.touchReliability,
    required this.controlReliability,
    required this.controlMode,
    required this.portalId,
    required this.returnAppId,
  });
}

class BmLib {
  BmLib._();

  static final BmLib instance = BmLib._();

  late final ffi.DynamicLibrary _lib = _openLibrary();
  bool _initialized = false;

  late final _bmLibraryInit = _lib
      .lookupFunction<ffi.Uint8 Function(), int Function()>('bm_library_init');
  late final _bmHandshakeBytes = _lib
      .lookupFunction<
        ffi.IntPtr Function(
          ffi.Uint8,
          ffi.Uint8,
          ffi.Uint16,
          ffi.Uint8,
          ffi.Uint8,
          ffi.Uint16,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
        ),
        int Function(int, int, int, int, int, int, ffi.Pointer<ffi.Uint8>, int)
      >('bm_handshake_bytes');

  late final _bmEngineNew = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Void> Function(),
        ffi.Pointer<ffi.Void> Function()
      >('bm_engine_new');
  late final _bmEngineFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_engine_free');
  late final _bmEngineInitLocalDevice = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DeviceCoreC>),
        int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DeviceCoreC>)
      >('bm_engine_init_local_device');
  late final _bmEngineRegisterDevice = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DeviceCoreC>),
        int Function(ffi.Pointer<ffi.Void>, ffi.Pointer<DeviceCoreC>)
      >('bm_engine_register_device');
  late final _bmEngineProcessIncoming = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_process_incoming');
  late final _bmEngineProcessIncomingUdp = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_process_incoming_udp');
  late final _bmEngineMakeRegistryRegister = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<BMRegistryInfoC>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<BMRegistryInfoC>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_registry_register');
  late final _bmEngineMakeRegistryList = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_registry_list');
  late final _bmEngineMakeDeviceConnectRequested = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<BMRegistryInfoC>,
          ffi.Pointer<BMRegistryInfoC>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<BMRegistryInfoC>,
          ffi.Pointer<BMRegistryInfoC>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_device_connect_requested');
  late final _bmEngineMakeRequestXml = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Int32,
          ffi.Int32,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          int,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_request_xml');
  late final _bmEngineMakeOnControlSchemeParsed = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_on_control_scheme_parsed');
  late final _bmEngineMakeSimpleInvoke = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_simple_invoke');
  late final _bmEngineMakeButtonInvoke = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Uint8,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_button_invoke');
  late final _bmEngineMakeDpadUpdate = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Int16,
          ffi.Int16,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_dpad_update');
  late final _bmEngineMakeTouchSet = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<TouchPointC>,
          ffi.IntPtr,
          ffi.Int32,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<TouchPointC>,
          int,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_touch_set');
  late final _bmEngineMakeAccel = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Double,
          ffi.Double,
          ffi.Double,
          ffi.Int32,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          double,
          double,
          double,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_accel');
  late final _bmEngineMakeGyro = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Float,
          ffi.Float,
          ffi.Float,
          ffi.Int32,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          double,
          double,
          double,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_gyro');
  late final _bmEngineMakeOrientation = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Float,
          ffi.Float,
          ffi.Float,
          ffi.Float,
          ffi.Int32,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          double,
          double,
          double,
          double,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_orientation');
  late final _bmEngineActionsFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ActionListC>),
        void Function(ffi.Pointer<ActionListC>)
      >('bm_engine_actions_free');

  late final _bmEngineMakeVibrate = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_vibrate');
  late final _bmEngineMakeUpdateWallet = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_update_wallet');
  late final _bmEngineMakeGetCookie = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_get_cookie');
  late final _bmEngineMakeSetCookie = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_cookie');
  late final _bmEngineMakePromptTrialUpsell = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_prompt_trial_upsell');
  late final _bmEngineMakeWaitForNewHost = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_wait_for_new_host');
  late final _bmEngineMakeSetControlMode = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Int32,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_control_mode');
  late final _bmEngineMakeEnableAccelerometer = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Uint8,
          ffi.Double,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          double,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_enable_accelerometer');
  late final _bmEngineMakeEnableTouch = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Uint8,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_enable_touch');
  late final _bmEngineMakeSetTouchInterval = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Double,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          double,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_touch_interval');
  late final _bmEngineMakeEnableGyro = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Uint8,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_enable_gyro');
  late final _bmEngineMakeSetGyroInterval = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Double,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          double,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_gyro_interval');
  late final _bmEngineMakeEnableOrientation = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Uint8,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_enable_orientation');
  late final _bmEngineMakeSetOrientationInterval = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Double,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          double,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_orientation_interval');
  late final _bmEngineMakeSetReliabilityForTouch = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Int32,
          ffi.Int32,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_reliability_for_touch');
  late final _bmEngineMakeSetCapabilities = _lib
      .lookupFunction<
        ffi.Uint8 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          ffi.Uint64,
          ffi.Pointer<ActionListC>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Char>,
          int,
          ffi.Pointer<ActionListC>,
        )
      >('bm_engine_make_set_capabilities');
  late final _bmControlsParseXml = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Uint8> Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        ffi.Pointer<ffi.Uint8> Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_controls_parse_xml');
  late final _bmControlsFreeSchemeBytes = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Uint8>, ffi.IntPtr),
        void Function(ffi.Pointer<ffi.Uint8>, int)
      >('bm_controls_free_scheme_bytes');

  late final _bmSafeImageMemory = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Uint8>, ffi.IntPtr),
        ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.Uint8>, int)
      >('bm_safe_image_memory');
  late final _bmFreeImageMemory = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Uint8>, ffi.IntPtr),
        void Function(ffi.Pointer<ffi.Uint8>, int)
      >('bm_free_image_memory');

  late final _deviceCoreNew = _lib
      .lookupFunction<
        ffi.Pointer<DeviceCoreC> Function(),
        ffi.Pointer<DeviceCoreC> Function()
      >('device_core_new');
  late final _deviceCoreSetId = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<DeviceCoreC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<DeviceCoreC>, ffi.Pointer<ffi.Char>)
      >('device_core_set_id');
  late final _deviceCoreSetName = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<DeviceCoreC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<DeviceCoreC>, ffi.Pointer<ffi.Char>)
      >('device_core_set_name');
  late final _deviceCoreSetAddr = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<DeviceCoreC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<DeviceCoreC>, ffi.Pointer<ffi.Char>)
      >('device_core_set_addr');
  late final _deviceCoreDestroy = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<DeviceCoreC>),
        void Function(ffi.Pointer<DeviceCoreC>)
      >('device_core_destroy');

  late final _bmRegistryInfoNew = _lib
      .lookupFunction<
        ffi.Pointer<BMRegistryInfoC> Function(),
        ffi.Pointer<BMRegistryInfoC> Function()
      >('bm_registry_info_new');
  late final _bmRegistryInfoSetAppId = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>)
      >('bm_registry_info_set_app_id');
  late final _bmRegistryInfoSetDeviceId = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>)
      >('bm_registry_info_set_device_id');
  late final _bmRegistryInfoSetDeviceName = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>)
      >('bm_registry_info_set_device_name');
  late final _bmRegistryInfoSetAddr = _lib
      .lookupFunction<
        ffi.Uint8 Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>),
        int Function(ffi.Pointer<BMRegistryInfoC>, ffi.Pointer<ffi.Char>)
      >('bm_registry_info_set_addr');
  late final _bmRegistryInfoDestroy = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<BMRegistryInfoC>),
        void Function(ffi.Pointer<BMRegistryInfoC>)
      >('bm_registry_info_destroy');

  void init() {
    if (_initialized) return;
    _bmLibraryInit();
    _initialized = true;
  }

  ffi.Pointer<ffi.Void> createEngine() => _bmEngineNew();

  void freeEngine(ffi.Pointer<ffi.Void> engine) => _bmEngineFree(engine);

  void initLocalDevice(
    ffi.Pointer<ffi.Void> engine,
    String deviceId,
    String deviceName,
    int deviceType,
    String address,
    int unreliablePort,
    int reliablePort,
  ) {
    final core = _makeDeviceCore(
      deviceId,
      deviceName,
      deviceType,
      address,
      unreliablePort,
      reliablePort,
    );
    _bmEngineInitLocalDevice(engine, core);
    _deviceCoreDestroy(core);
  }

  void registerDevice(
    ffi.Pointer<ffi.Void> engine,
    String deviceId,
    String deviceName,
    int deviceType,
    String address,
    int unreliablePort,
    int reliablePort,
  ) {
    final core = _makeDeviceCore(
      deviceId,
      deviceName,
      deviceType,
      address,
      unreliablePort,
      reliablePort,
    );
    _bmEngineRegisterDevice(engine, core);
    _deviceCoreDestroy(core);
  }

  Uint8List handshakeBytes({
    int currentMajor = 1,
    int currentMinor = 7,
    int currentBuild = 0,
    int minMajor = 0,
    int minMinor = 9,
    int minBuild = 0,
  }) {
    final out = calloc<ffi.Uint8>(12);
    final written = _bmHandshakeBytes(
      currentMajor,
      currentMinor,
      currentBuild,
      minMajor,
      minMinor,
      minBuild,
      out,
      12,
    );
    final bytes = Uint8List.fromList(
      out.cast<ffi.Uint8>().asTypedList(written),
    );
    calloc.free(out);
    return bytes;
  }

  List<BmAction> processIncoming(ffi.Pointer<ffi.Void> engine, Uint8List data) {
    final payload = calloc<ffi.Uint8>(data.length);
    payload.cast<ffi.Uint8>().asTypedList(data.length).setAll(0, data);
    final listPtr = calloc<ActionListC>();
    _bmEngineProcessIncoming(engine, payload, data.length, listPtr);
    calloc.free(payload);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> processIncomingUdp(
    ffi.Pointer<ffi.Void> engine,
    Uint8List data,
  ) {
    final payload = calloc<ffi.Uint8>(data.length);
    payload.cast<ffi.Uint8>().asTypedList(data.length).setAll(0, data);
    final listPtr = calloc<ActionListC>();
    _bmEngineProcessIncomingUdp(engine, payload, data.length, listPtr);
    calloc.free(payload);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeRegistryRegister(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    BmRegistryInfo info,
    String? domain,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final domainPtr = (domain ?? '').toNativeUtf8().cast<ffi.Char>();
    final infoPtr = _makeRegistryInfo(info);
    _bmEngineMakeRegistryRegister(
      engine,
      targetPtr,
      infoPtr,
      domainPtr,
      listPtr,
    );
    calloc.free(targetPtr);
    calloc.free(domainPtr);
    _bmRegistryInfoDestroy(infoPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeRegistryList(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeRegistryList(engine, targetPtr, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeDeviceConnectRequested(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    BmRegistryInfo game,
    BmRegistryInfo controller,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final gamePtr = _makeRegistryInfo(game);
    final ctrlPtr = _makeRegistryInfo(controller);
    _bmEngineMakeDeviceConnectRequested(
      engine,
      targetPtr,
      gamePtr,
      ctrlPtr,
      listPtr,
    );
    calloc.free(targetPtr);
    _bmRegistryInfoDestroy(gamePtr);
    _bmRegistryInfoDestroy(ctrlPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeRequestXml(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int width,
    int height,
    String deviceId,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final devicePtr = deviceId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeRequestXml(
      engine,
      targetPtr,
      width,
      height,
      devicePtr,
      listPtr,
    );
    calloc.free(targetPtr);
    calloc.free(devicePtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeOnControlSchemeParsed(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String deviceId,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final devicePtr = deviceId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeOnControlSchemeParsed(engine, targetPtr, devicePtr, listPtr);
    calloc.free(targetPtr);
    calloc.free(devicePtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSimpleInvoke(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String method,
    String? returnMethod,
    String? param,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final methodPtr = method.toNativeUtf8().cast<ffi.Char>();
    final returnPtr = returnMethod == null
        ? ffi.nullptr
        : returnMethod.toNativeUtf8().cast<ffi.Char>();
    final paramPtr = param == null
        ? ffi.nullptr
        : param.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSimpleInvoke(
      engine,
      targetPtr,
      methodPtr,
      returnPtr,
      paramPtr,
      listPtr,
    );
    calloc.free(targetPtr);
    calloc.free(methodPtr);
    if (returnPtr != ffi.nullptr) {
      calloc.free(returnPtr);
    }
    if (paramPtr != ffi.nullptr) {
      calloc.free(paramPtr);
    }
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeButtonInvoke(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String handler,
    bool pressed,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final handlerPtr = handler.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeButtonInvoke(
      engine,
      targetPtr,
      handlerPtr,
      pressed ? 1 : 0,
      listPtr,
    );
    calloc.free(targetPtr);
    calloc.free(handlerPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeDpadUpdate(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int x,
    int y,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeDpadUpdate(engine, targetPtr, x, y, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeTouchSet(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    List<TouchPointData> touches,
    int reliability,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final touchPtr = calloc<TouchPointC>(touches.length);
    for (var i = 0; i < touches.length; i++) {
      final t = touches[i];
      touchPtr[i]
        ..id = t.id
        ..x = t.x
        ..y = t.y
        ..screenWidth = t.screenWidth
        ..screenHeight = t.screenHeight
        ..state = t.state;
    }
    _bmEngineMakeTouchSet(
      engine,
      targetPtr,
      touchPtr,
      touches.length,
      reliability,
      listPtr,
    );
    calloc.free(targetPtr);
    calloc.free(touchPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeAccel(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    int reliability,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeAccel(engine, targetPtr, x, y, z, reliability, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeGyro(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    int reliability,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeGyro(engine, targetPtr, x, y, z, reliability, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeOrientation(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    double w,
    int reliability,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeOrientation(
      engine,
      targetPtr,
      x,
      y,
      z,
      w,
      reliability,
      listPtr,
    );
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeVibrate(ffi.Pointer<ffi.Void> engine, String targetId) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeVibrate(engine, targetPtr, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeUpdateWallet(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeUpdateWallet(engine, targetPtr, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeGetCookie(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String name,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final namePtr = name.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeGetCookie(engine, targetPtr, namePtr, listPtr);
    calloc.free(targetPtr);
    calloc.free(namePtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetCookie(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String name,
    String value,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final namePtr = name.toNativeUtf8().cast<ffi.Char>();
    final valuePtr = value.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetCookie(engine, targetPtr, namePtr, valuePtr, listPtr);
    calloc.free(targetPtr);
    calloc.free(namePtr);
    calloc.free(valuePtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makePromptTrialUpsell(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakePromptTrialUpsell(engine, targetPtr, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeWaitForNewHost(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String hostDeviceId,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final hostPtr = hostDeviceId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeWaitForNewHost(engine, targetPtr, hostPtr, listPtr);
    calloc.free(targetPtr);
    calloc.free(hostPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetControlMode(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int mode, {
    String? textContent,
  }) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    final textPtr = textContent == null
        ? ffi.nullptr
        : textContent.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetControlMode(engine, targetPtr, mode, textPtr, listPtr);
    calloc.free(targetPtr);
    if (textPtr != ffi.nullptr) calloc.free(textPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeEnableAccelerometer(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    bool enabled, {
    double intervalSeconds = -1.0,
  }) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeEnableAccelerometer(
      engine,
      targetPtr,
      enabled ? 1 : 0,
      intervalSeconds,
      listPtr,
    );
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeEnableTouch(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    bool enabled,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeEnableTouch(engine, targetPtr, enabled ? 1 : 0, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetTouchInterval(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double intervalSeconds,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetTouchInterval(engine, targetPtr, intervalSeconds, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeEnableGyro(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    bool enabled,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeEnableGyro(engine, targetPtr, enabled ? 1 : 0, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetGyroInterval(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double intervalSeconds,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetGyroInterval(engine, targetPtr, intervalSeconds, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeEnableOrientation(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    bool enabled,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeEnableOrientation(engine, targetPtr, enabled ? 1 : 0, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetOrientationInterval(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double intervalSeconds,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetOrientationInterval(
      engine,
      targetPtr,
      intervalSeconds,
      listPtr,
    );
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetReliabilityForTouch(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int touchReliability,
    int controlReliability,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetReliabilityForTouch(
      engine,
      targetPtr,
      touchReliability,
      controlReliability,
      listPtr,
    );
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  List<BmAction> makeSetCapabilities(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int capabilities,
  ) {
    final listPtr = calloc<ActionListC>();
    final targetPtr = targetId.toNativeUtf8().cast<ffi.Char>();
    _bmEngineMakeSetCapabilities(engine, targetPtr, capabilities, listPtr);
    calloc.free(targetPtr);
    final actions = _readActionList(listPtr);
    _bmEngineActionsFree(listPtr);
    calloc.free(listPtr);
    return actions;
  }

  Uint8List parseControlSchemeXml(String xmlContent) {
    if (xmlContent.isEmpty) return Uint8List(0);
    final xmlPtr = xmlContent.toNativeUtf8().cast<ffi.Char>();
    final lenPtr = calloc<ffi.IntPtr>();
    final bytesPtr = _bmControlsParseXml(xmlPtr, lenPtr);
    calloc.free(xmlPtr);

    if (bytesPtr == ffi.nullptr) {
      calloc.free(lenPtr);
      return Uint8List(0);
    }

    final len = lenPtr.value;
    final bytes = Uint8List.fromList(bytesPtr.asTypedList(len));
    _bmControlsFreeSchemeBytes(bytesPtr, len);
    calloc.free(lenPtr);
    return bytes;
  }

  Uint8List safeImageMemory(Uint8List data) {
    if (data.isEmpty) return Uint8List(0);
    final ptr = calloc<ffi.Uint8>(data.length);
    ptr.asTypedList(data.length).setAll(0, data);
    final safePtr = _bmSafeImageMemory(ptr, data.length);
    calloc.free(ptr);
    if (safePtr == ffi.nullptr) return Uint8List(0);
    final out = Uint8List.fromList(safePtr.asTypedList(data.length));
    _bmFreeImageMemory(safePtr, data.length);
    return out;
  }

  List<BmAction> _readActionList(ffi.Pointer<ActionListC> listPtr) {
    final list = listPtr.ref;
    final count = list.len;
    if (count == 0 || list.ptr == ffi.nullptr) {
      return const [];
    }
    final actions = <BmAction>[];
    for (var i = 0; i < count; i++) {
      final item = list.ptr[i];
      final action = _readAction(item);
      if (action != null) {
        actions.add(action);
      }
    }
    return actions;
  }

  BmAction? _readAction(ActionC item) {
    final tag = item.tag;
    if (tag == ActionKindCodes.send) {
      final payload = _readBytes(item.payloadPtr, item.payloadLen);
      final deviceId = _readString(item.deviceIdPtr, item.deviceIdLen);
      return BmSendAction(deviceId, item.channel, item.reliability, payload);
    }
    if (tag == ActionKindCodes.chunkProgress) {
      final deviceId = _readString(item.deviceIdPtr, item.deviceIdLen);
      final setId = _readString(item.chunkSetIdPtr, item.chunkSetIdLen);
      return BmChunkProgressAction(
        deviceId,
        setId,
        item.chunkCurrent,
        item.chunkTotal,
      );
    }
    if (tag == ActionKindCodes.chunkSetComplete) {
      final deviceId = _readString(item.deviceIdPtr, item.deviceIdLen);
      final setId = _readString(item.chunkSetIdPtr, item.chunkSetIdLen);
      final blob = _readBytes(item.payloadPtr, item.payloadLen);
      return BmChunkCompleteAction(deviceId, setId, blob);
    }
    if (tag == ActionKindCodes.registryEvent) {
      final infos = _readRegistryInfos(item.registryPtr, item.registryLen);
      final success = item.registrySuccess < 0
          ? null
          : item.registrySuccess != 0;
      return BmRegistryEventAction(item.registryKind, success, infos);
    }
    if (tag == ActionKindCodes.log) {
      final msg = _readString(
        item.payloadPtr.cast<ffi.Char>(),
        item.payloadLen,
      );
      return BmLogAction(item.logLevel, msg);
    }
    if (tag == ActionKindCodes.invoke) {
      final method = _readString(item.invokeMethodPtr, item.invokeMethodLen);
      final returnMethod = _readString(
        item.invokeReturnMethodPtr,
        item.invokeReturnMethodLen,
      );
      final raw = _readBytes(item.payloadPtr, item.payloadLen);
      return BmInvokeAction(
        method,
        returnMethod.isEmpty ? null : returnMethod,
        raw,
      );
    }
    if (tag == ActionKindCodes.handshake) {
      return BmHandshakeAction(item.handshakeCurrent, item.handshakeMinimum);
    }
    if (tag == ActionKindCodes.controlConfig) {
      bool? b(int v) => v < 0 ? null : v != 0;
      int? i(int v) => v < 0 ? null : v;
      return BmControlConfigAction(
        touchEnabled: b(item.controlTouchEnabled),
        accelEnabled: b(item.controlAccelEnabled),
        gyroEnabled: b(item.controlGyroEnabled),
        orientationEnabled: b(item.controlOrientationEnabled),
        touchIntervalMs: i(item.controlTouchIntervalMs),
        accelIntervalMs: i(item.controlAccelIntervalMs),
        gyroIntervalMs: i(item.controlGyroIntervalMs),
        orientationIntervalMs: i(item.controlOrientationIntervalMs),
        touchReliability: i(item.controlTouchReliability),
        controlReliability: i(item.controlReliability),
        controlMode: i(item.controlMode),
        portalId: _readString(item.controlPortalIdPtr, item.controlPortalIdLen),
        returnAppId: _readString(
          item.controlReturnAppIdPtr,
          item.controlReturnAppIdLen,
        ),
      );
    }
    return null;
  }

  List<BmRegistryInfo> _readRegistryInfos(
    ffi.Pointer<BMRegistryInfoC> ptr,
    int len,
  ) {
    if (ptr == ffi.nullptr || len == 0) return const [];
    final out = <BmRegistryInfo>[];
    for (var i = 0; i < len; i++) {
      out.add(_readRegistryInfo(ptr[i]));
    }
    return out;
  }

  BmRegistryInfo _readRegistryInfo(BMRegistryInfoC c) {
    return BmRegistryInfo(
      slotId: c.slotId,
      appId: _readString(c.appIdPtr, c.appIdLen),
      currentPlayers: c.currentPlayers,
      maxPlayers: c.maxPlayers,
      deviceType: c.deviceTypeCode,
      deviceId: _readString(c.deviceIdPtr, c.deviceIdLen),
      deviceName: _readString(c.deviceNamePtr, c.deviceNameLen),
      address: _readString(c.addrPtr, c.addrLen),
      unreliablePort: c.addrUnreliablePort,
      reliablePort: c.addrReliablePort,
    );
  }

  ffi.Pointer<DeviceCoreC> _makeDeviceCore(
    String deviceId,
    String deviceName,
    int deviceType,
    String address,
    int unreliablePort,
    int reliablePort,
  ) {
    final core = _deviceCoreNew();
    core.ref.deviceTypeCode = deviceType;
    core.ref.hasAddress = 1;
    core.ref.addrUnreliablePort = unreliablePort;
    core.ref.addrReliablePort = reliablePort;
    final idPtr = deviceId.toNativeUtf8().cast<ffi.Char>();
    final namePtr = deviceName.toNativeUtf8().cast<ffi.Char>();
    final addrPtr = address.toNativeUtf8().cast<ffi.Char>();
    _deviceCoreSetId(core, idPtr);
    _deviceCoreSetName(core, namePtr);
    _deviceCoreSetAddr(core, addrPtr);
    calloc.free(idPtr);
    calloc.free(namePtr);
    calloc.free(addrPtr);
    return core;
  }

  ffi.Pointer<BMRegistryInfoC> _makeRegistryInfo(BmRegistryInfo info) {
    final out = _bmRegistryInfoNew();
    out.ref.slotId = info.slotId;
    out.ref.currentPlayers = info.currentPlayers;
    out.ref.maxPlayers = info.maxPlayers;
    out.ref.deviceTypeCode = info.deviceType;
    out.ref.addrUnreliablePort = info.unreliablePort;
    out.ref.addrReliablePort = info.reliablePort;
    final appIdPtr = info.appId.toNativeUtf8().cast<ffi.Char>();
    final devIdPtr = info.deviceId.toNativeUtf8().cast<ffi.Char>();
    final devNamePtr = info.deviceName.toNativeUtf8().cast<ffi.Char>();
    final addrPtr = info.address.toNativeUtf8().cast<ffi.Char>();
    _bmRegistryInfoSetAppId(out, appIdPtr);
    _bmRegistryInfoSetDeviceId(out, devIdPtr);
    _bmRegistryInfoSetDeviceName(out, devNamePtr);
    _bmRegistryInfoSetAddr(out, addrPtr);
    calloc.free(appIdPtr);
    calloc.free(devIdPtr);
    calloc.free(devNamePtr);
    calloc.free(addrPtr);
    return out;
  }

  String _readString(ffi.Pointer<ffi.Char> ptr, int len) {
    if (ptr == ffi.nullptr || len == 0) return '';
    final bytes = ptr.cast<ffi.Uint8>().asTypedList(len);
    return utf8.decode(bytes, allowMalformed: true);
  }

  Uint8List _readBytes(ffi.Pointer<ffi.Uint8> ptr, int len) {
    if (ptr == ffi.nullptr || len == 0) return Uint8List(0);
    return Uint8List.fromList(ptr.cast<ffi.Uint8>().asTypedList(len));
  }

  ffi.DynamicLibrary _openLibrary() {
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('bronze_monkey.dll');
    }
    if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libbronze_monkey.dylib');
    }
    if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    }
    return ffi.DynamicLibrary.open('libbronze_monkey.so');
  }
}

base class ActionListC extends ffi.Struct {
  external ffi.Pointer<ActionC> ptr;
  @ffi.IntPtr()
  external int len;
}

base class ActionC extends ffi.Struct {
  @ffi.Int32()
  external int tag;
  @ffi.Int32()
  external int logLevel;
  @ffi.Int32()
  external int channel;
  @ffi.Int32()
  external int reliability;

  external ffi.Pointer<ffi.Uint8> payloadPtr;
  @ffi.IntPtr()
  external int payloadLen;
  @ffi.IntPtr()
  external int payloadCap;

  external ffi.Pointer<ffi.Char> deviceIdPtr;
  @ffi.IntPtr()
  external int deviceIdLen;

  external ffi.Pointer<ffi.Char> deviceNamePtr;
  @ffi.IntPtr()
  external int deviceNameLen;

  @ffi.Int32()
  external int deviceTypeCode;
  @ffi.Int32()
  external int classId;

  @ffi.Uint8()
  external int hasAddress;

  external ffi.Pointer<ffi.Char> addrPtr;
  @ffi.IntPtr()
  external int addrLen;
  @ffi.Int32()
  external int addrUnreliablePort;
  @ffi.Int32()
  external int addrReliablePort;

  @ffi.Int32()
  external int registryKind;
  @ffi.Int32()
  external int registrySuccess;
  external ffi.Pointer<BMRegistryInfoC> registryPtr;
  @ffi.IntPtr()
  external int registryLen;

  external ffi.Pointer<ffi.Char> invokeMethodPtr;
  @ffi.IntPtr()
  external int invokeMethodLen;
  external ffi.Pointer<ffi.Char> invokeReturnMethodPtr;
  @ffi.IntPtr()
  external int invokeReturnMethodLen;

  external ffi.Pointer<ffi.Char> chunkSetIdPtr;
  @ffi.IntPtr()
  external int chunkSetIdLen;
  @ffi.Uint32()
  external int chunkCurrent;
  @ffi.Uint32()
  external int chunkTotal;

  @ffi.Int32()
  external int controlTouchEnabled;
  @ffi.Int32()
  external int controlAccelEnabled;
  @ffi.Int32()
  external int controlGyroEnabled;
  @ffi.Int32()
  external int controlOrientationEnabled;
  @ffi.Int32()
  external int controlTouchIntervalMs;
  @ffi.Int32()
  external int controlAccelIntervalMs;
  @ffi.Int32()
  external int controlGyroIntervalMs;
  @ffi.Int32()
  external int controlOrientationIntervalMs;
  @ffi.Int32()
  external int controlTouchReliability;
  @ffi.Int32()
  external int controlReliability;
  @ffi.Int32()
  external int controlMode;
  external ffi.Pointer<ffi.Char> controlPortalIdPtr;
  @ffi.IntPtr()
  external int controlPortalIdLen;
  external ffi.Pointer<ffi.Char> controlReturnAppIdPtr;
  @ffi.IntPtr()
  external int controlReturnAppIdLen;
  @ffi.Uint32()
  external int handshakeCurrent;
  @ffi.Uint32()
  external int handshakeMinimum;
}

base class DeviceCoreC extends ffi.Struct {
  @ffi.Int32()
  external int deviceTypeCode;
  external ffi.Pointer<ffi.Char> idPtr;
  @ffi.IntPtr()
  external int idLen;
  external ffi.Pointer<ffi.Char> namePtr;
  @ffi.IntPtr()
  external int nameLen;
  @ffi.Uint8()
  external int hasAddress;
  external ffi.Pointer<ffi.Char> addrPtr;
  @ffi.IntPtr()
  external int addrLen;
  @ffi.Int32()
  external int addrUnreliablePort;
  @ffi.Int32()
  external int addrReliablePort;
}

base class BMRegistryInfoC extends ffi.Struct {
  @ffi.Int32()
  external int slotId;
  @ffi.Int32()
  external int currentPlayers;
  @ffi.Int32()
  external int maxPlayers;
  @ffi.Int32()
  external int deviceTypeCode;

  external ffi.Pointer<ffi.Char> appIdPtr;
  @ffi.IntPtr()
  external int appIdLen;

  external ffi.Pointer<ffi.Char> deviceIdPtr;
  @ffi.IntPtr()
  external int deviceIdLen;

  external ffi.Pointer<ffi.Char> deviceNamePtr;
  @ffi.IntPtr()
  external int deviceNameLen;

  external ffi.Pointer<ffi.Char> addrPtr;
  @ffi.IntPtr()
  external int addrLen;
  @ffi.Int32()
  external int addrUnreliablePort;
  @ffi.Int32()
  external int addrReliablePort;
}

base class TouchPointC extends ffi.Struct {
  @ffi.Int32()
  external int id;
  @ffi.Float()
  external double x;
  @ffi.Float()
  external double y;
  @ffi.Int16()
  external int screenWidth;
  @ffi.Int16()
  external int screenHeight;
  @ffi.Int32()
  external int state;
}

class TouchStateCodes {
  static const int began = 1;
  static const int moved = 2;
  static const int stationary = 3;
  static const int ended = 4;
  static const int cancelled = 5;
}

class TouchPointData {
  final int id;
  final double x;
  final double y;
  final int screenWidth;
  final int screenHeight;
  final int state;

  const TouchPointData({
    required this.id,
    required this.x,
    required this.y,
    required this.screenWidth,
    required this.screenHeight,
    required this.state,
  });
}
