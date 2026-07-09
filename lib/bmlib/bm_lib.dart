// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:msgpack_dart/msgpack_dart.dart' as mp;

import 'bm_log.dart';
import 'models.dart';

export 'codes.dart';
export 'models.dart';

class BmLib {
  BmLib._();

  static final BmLib instance = BmLib._();

  late final ffi.DynamicLibrary _lib = _openLibrary();
  bool _initialized = false;

  late final _bmLibraryInit = _lib
      .lookupFunction<ffi.Uint8 Function(), int Function()>('bm_library_init');

  late final _engineNew = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Void> Function(),
        ffi.Pointer<ffi.Void> Function()
      >('bm_engine_new');

  late final _engineFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_engine_free');

  late final _bufferFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Uint8>, ffi.IntPtr),
        void Function(ffi.Pointer<ffi.Uint8>, int)
      >('bm_buffer_free');

  late final _initLocalDevice = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
        ),
        bool Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_init_local_device');

  late final _registerDevice = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
        ),
        bool Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_register_device');

  late final _processIncoming = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_engine_process_incoming');

  late final _processIncomingUdp = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_engine_process_incoming_udp');

  late final _emit = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_engine_emit');

  late final _handshake = _lib
      .lookupFunction<
        ffi.Bool Function(ffi.Pointer<ffi.Uint8>, ffi.IntPtr),
        bool Function(ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_handshake');

  late final _safeImage = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_safe_image_memory');

  late final _assemblerNew = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Void> Function(),
        ffi.Pointer<ffi.Void> Function()
      >('bm_scheme_assembler_new');

  late final _assemblerFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_scheme_assembler_free');

  late final _assemblerOffer = _lib
      .lookupFunction<
        ffi.Int32 Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
          ffi.Pointer<ffi.Bool>,
        ),
        int Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
          ffi.Pointer<ffi.Bool>,
        )
      >('bm_scheme_assembler_offer');

  late final _assemblerCurrent = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_scheme_assembler_current');

  late final _assemblerReset = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_scheme_assembler_reset');

  late final _logConfigure = _lib
      .lookupFunction<
        ffi.Bool Function(ffi.Uint8, ffi.IntPtr),
        bool Function(int, int)
      >('bm_log_configure');

  late final _logSetLevel = _lib
      .lookupFunction<ffi.Bool Function(ffi.Uint8), bool Function(int)>(
        'bm_log_set_level',
      );

  late final _logTake = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_log_take');

  void init() {
    if (_initialized) return;
    _bmLibraryInit();
    _initialized = true;
  }

  ffi.Pointer<ffi.Void> createEngine() => _engineNew();

  void freeEngine(ffi.Pointer<ffi.Void> engine) => _engineFree(engine);

  BmSchemeAssembler createSchemeAssembler() =>
      BmSchemeAssembler._(this, _assemblerNew());

  bool configureLogging(int level, int capacity) =>
      _logConfigure(level, capacity);

  bool setLogLevel(int level) => _logSetLevel(level);

  BmLogDrain takeLogs() {
    final outPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final ok = _logTake(outPtr, outLen);
    final bytes = _readOut(ok, outPtr, outLen);
    calloc.free(outPtr);
    calloc.free(outLen);
    return BmLogDrain.fromBytes(bytes);
  }

  Uint8List _readOut(
    bool ok,
    ffi.Pointer<ffi.Pointer<ffi.Uint8>> outPtr,
    ffi.Pointer<ffi.IntPtr> outLen,
  ) {
    var result = Uint8List(0);
    if (ok && outPtr.value != ffi.nullptr && outLen.value > 0) {
      result = Uint8List.fromList(outPtr.value.asTypedList(outLen.value));
      _bufferFree(outPtr.value, outLen.value);
    }
    return result;
  }

  Uint8List _callOut(
    Uint8List input,
    bool Function(
      ffi.Pointer<ffi.Uint8>,
      int,
      ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
      ffi.Pointer<ffi.IntPtr>,
    )
    call,
  ) {
    final inPtr = calloc<ffi.Uint8>(input.isEmpty ? 1 : input.length);
    if (input.isNotEmpty) {
      inPtr.asTypedList(input.length).setAll(0, input);
    }
    final outPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final ok = call(inPtr, input.length, outPtr, outLen);
    final out = _readOut(ok, outPtr, outLen);
    calloc.free(inPtr);
    calloc.free(outPtr);
    calloc.free(outLen);
    return out;
  }

  bool _callIn(
    Uint8List input,
    bool Function(ffi.Pointer<ffi.Uint8>, int) call,
  ) {
    final inPtr = calloc<ffi.Uint8>(input.isEmpty ? 1 : input.length);
    if (input.isNotEmpty) {
      inPtr.asTypedList(input.length).setAll(0, input);
    }
    final ok = call(inPtr, input.length);
    calloc.free(inPtr);
    return ok;
  }

  void initLocalDevice(
    ffi.Pointer<ffi.Void> engine,
    String deviceId,
    String deviceName,
    int deviceType,
    String address,
    int unreliablePort,
    int reliablePort,
  ) {
    final core = mp.serialize(
      _deviceCoreWire(
        deviceId,
        deviceName,
        deviceType,
        address,
        unreliablePort,
        reliablePort,
      ),
    );
    _callIn(core, (ptr, len) => _initLocalDevice(engine, ptr, len));
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
    final core = mp.serialize(
      _deviceCoreWire(
        deviceId,
        deviceName,
        deviceType,
        address,
        unreliablePort,
        reliablePort,
      ),
    );
    _callIn(core, (ptr, len) => _registerDevice(engine, ptr, len));
  }

  Map<String, dynamic> _deviceCoreWire(
    String id,
    String name,
    int type,
    String addr,
    int uport,
    int rport,
  ) => {
    'device_id': id,
    'device_name': name,
    'device_type': type,
    'address': {
      'address': addr,
      'unreliable_port': uport,
      'reliable_port': rport,
    },
  };

  Uint8List handshakeBytes() {
    final out = calloc<ffi.Uint8>(12);
    _handshake(out, 12);
    final bytes = Uint8List.fromList(out.asTypedList(12));
    calloc.free(out);
    return bytes;
  }

  BmProcessOutput processIncoming(
    ffi.Pointer<ffi.Void> engine,
    Uint8List data,
  ) {
    final out = _callOut(
      data,
      (ptr, len, op, ol) => _processIncoming(engine, ptr, len, op, ol),
    );
    return _decodeProcessOutput(out);
  }

  BmProcessOutput processIncomingUdp(
    ffi.Pointer<ffi.Void> engine,
    Uint8List data,
  ) {
    final out = _callOut(
      data,
      (ptr, len, op, ol) => _processIncomingUdp(engine, ptr, len, op, ol),
    );
    return _decodeProcessOutput(out);
  }

  List<BmOutgoing> emit(
    ffi.Pointer<ffi.Void> engine,
    Map<String, dynamic> command,
  ) {
    final out = _callOut(
      mp.serialize(command),
      (ptr, len, op, ol) => _emit(engine, ptr, len, op, ol),
    );
    return _decodeOutgoings(out);
  }

  BmProcessOutput _decodeProcessOutput(Uint8List bytes) {
    if (bytes.isEmpty) return const BmProcessOutput([], []);
    final decoded = mp.deserialize(bytes);
    if (decoded is! Map) return const BmProcessOutput([], []);
    final events = ((decoded['events'] as List?) ?? const []).map((e) {
      final m = e as Map;
      return BmEvent((m['type'] as String?) ?? '', m);
    }).toList();
    final outgoings = ((decoded['outgoings'] as List?) ?? const [])
        .map((e) => BmOutgoing.fromWire(e as Map))
        .toList();
    return BmProcessOutput(events, outgoings);
  }

  List<BmOutgoing> _decodeOutgoings(Uint8List bytes) {
    if (bytes.isEmpty) return const [];
    final decoded = mp.deserialize(bytes);
    if (decoded is! List) return const [];
    return decoded.map((e) => BmOutgoing.fromWire(e as Map)).toList();
  }

  List<BmOutgoing> makeRegistryRegister(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    BmRegistryInfo info,
    String? domain,
  ) => emit(engine, {
    'type': 'Register',
    'target': targetId,
    'info': info.toWire(),
    'domain': domain,
    'return_method': null,
  });

  List<BmOutgoing> makeRegistryList(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) => emit(engine, {
    'type': 'RequestHostList',
    'target': targetId,
    'return_method': null,
  });

  List<BmOutgoing> makeDeviceConnectRequested(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    BmRegistryInfo game,
    BmRegistryInfo controller,
  ) => emit(engine, {
    'type': 'ConnectToHost',
    'target': targetId,
    'host': game.toWire(),
    'self_info': controller.toWire(),
  });

  List<BmOutgoing> makeRequestXml(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int width,
    int height,
  ) => emit(engine, {
    'type': 'RequestControlScheme',
    'target': targetId,
    'width': width,
    'height': height,
  });

  List<BmOutgoing> makeOnControlSchemeParsed(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) => emit(engine, {'type': 'ControlSchemeParsed', 'target': targetId});

  List<BmOutgoing> makeButtonInvoke(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String handler,
    bool pressed,
  ) => emit(engine, {
    'type': 'SendButton',
    'target': targetId,
    'handler': handler,
    'pressed': pressed,
  });

  List<BmOutgoing> makeDpadUpdate(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int x,
    int y,
  ) => emit(engine, {'type': 'SendDPad', 'target': targetId, 'x': x, 'y': y});

  List<BmOutgoing> makeSendKeyString(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String key,
  ) => emit(engine, {'type': 'SendKeyString', 'target': targetId, 'key': key});

  List<BmOutgoing> makeSendNavigation(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String nav,
  ) => emit(engine, {'type': 'SendNavigation', 'target': targetId, 'nav': nav});

  List<BmOutgoing> makeTouchSet(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    List<TouchPointData> touches,
  ) => emit(engine, {
    'type': 'SendTouch',
    'target': targetId,
    'touches': touches.map((t) => t.toWire()).toList(),
  });

  List<BmOutgoing> makeAccel(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
  ) => emit(engine, {
    'type': 'SendAccel',
    'target': targetId,
    'x': x,
    'y': y,
    'z': z,
  });

  List<BmOutgoing> makeGyro(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
  ) => emit(engine, {
    'type': 'SendGyro',
    'target': targetId,
    'x': x,
    'y': y,
    'z': z,
  });

  List<BmOutgoing> makeOrientation(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    double w,
  ) => emit(engine, {
    'type': 'SendOrientation',
    'target': targetId,
    'x': x,
    'y': y,
    'z': z,
    'w': w,
  });

  List<BmOutgoing> makeSetCapabilities(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int capabilities,
  ) => emit(engine, {
    'type': 'SetCapabilities',
    'target': targetId,
    'gyroscope': (capabilities & 1) != 0,
    'orientation': (capabilities & 2) != 0,
  });

  List<BmOutgoing> makePause(ffi.Pointer<ffi.Void> engine, String targetId) =>
      emit(engine, {'type': 'Pause', 'target': targetId});

  List<BmOutgoing> makeMenuEvent(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String event,
  ) => emit(engine, {
    'type': 'SendMenuEvent',
    'target': targetId,
    'event': event,
  });

  Uint8List safeImageMemory(Uint8List data) {
    if (data.isEmpty) return Uint8List(0);
    return _callOut(data, (ptr, len, op, ol) => _safeImage(ptr, len, op, ol));
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

class BmSchemeOffer {
  /// 2 = updated, 1 = consumed, 0 = not a scheme set, -1 = error.
  final int kind;
  final Uint8List? scheme;
  final bool initial;

  const BmSchemeOffer(this.kind, this.scheme, this.initial);

  bool get isUpdated => kind == 2;
  bool get isNotScheme => kind == 0;
}

class BmSchemeAssembler {
  final BmLib _lib;
  ffi.Pointer<ffi.Void> _ptr;

  BmSchemeAssembler._(this._lib, this._ptr);

  BmSchemeOffer offer(String setId, Uint8List blob) {
    final setIdBytes = utf8.encode(setId);
    final setIdPtr = calloc<ffi.Uint8>(
      setIdBytes.isEmpty ? 1 : setIdBytes.length,
    );
    if (setIdBytes.isNotEmpty) {
      setIdPtr.asTypedList(setIdBytes.length).setAll(0, setIdBytes);
    }
    final blobPtr = calloc<ffi.Uint8>(blob.isEmpty ? 1 : blob.length);
    if (blob.isNotEmpty) {
      blobPtr.asTypedList(blob.length).setAll(0, blob);
    }
    final outScheme = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final outInitial = calloc<ffi.Bool>();

    final kind = _lib._assemblerOffer(
      _ptr,
      setIdPtr,
      setIdBytes.length,
      blobPtr,
      blob.length,
      outScheme,
      outLen,
      outInitial,
    );

    Uint8List? scheme;
    var initial = false;
    if (kind == 2) {
      initial = outInitial.value;
      if (outScheme.value != ffi.nullptr && outLen.value > 0) {
        scheme = Uint8List.fromList(outScheme.value.asTypedList(outLen.value));
        _lib._bufferFree(outScheme.value, outLen.value);
      }
    }

    calloc.free(setIdPtr);
    calloc.free(blobPtr);
    calloc.free(outScheme);
    calloc.free(outLen);
    calloc.free(outInitial);
    return BmSchemeOffer(kind, scheme, initial);
  }

  Uint8List? current() {
    final outPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final ok = _lib._assemblerCurrent(_ptr, outPtr, outLen);
    Uint8List? result;
    if (ok && outPtr.value != ffi.nullptr && outLen.value > 0) {
      result = Uint8List.fromList(outPtr.value.asTypedList(outLen.value));
      _lib._bufferFree(outPtr.value, outLen.value);
    }
    calloc.free(outPtr);
    calloc.free(outLen);
    return result;
  }

  void reset() => _lib._assemblerReset(_ptr);

  void dispose() {
    if (_ptr != ffi.nullptr) {
      _lib._assemblerFree(_ptr);
      _ptr = ffi.nullptr;
    }
  }
}
