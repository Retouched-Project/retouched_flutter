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

  late final _getLastError = _lib
      .lookupFunction<
        ffi.Int32 Function(ffi.Pointer<ffi.Char>, ffi.IntPtr),
        int Function(ffi.Pointer<ffi.Char>, int)
      >('bm_get_last_error');

  late final _initLocalDevice = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
        ),
        bool Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_init_local_device');

  late final _declarePeer = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
        ),
        bool Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_declare_peer');

  late final _configure = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
        ),
        bool Function(ffi.Pointer<ffi.Void>, ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_configure');

  late final _processIncoming = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Uint8>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_engine_process_incoming');

  late final _emit = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          ffi.IntPtr,
          ffi.Uint64,
          ffi.Bool,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint8>,
          int,
          int,
          bool,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_engine_emit');

  late final _handleTime = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Void>,
          ffi.Uint64,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Void>,
          int,
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_engine_handle_time');

  late final _handshake = _lib
      .lookupFunction<
        ffi.Bool Function(ffi.Pointer<ffi.Uint8>, ffi.IntPtr),
        bool Function(ffi.Pointer<ffi.Uint8>, int)
      >('bm_engine_handshake');

  late final _framerNew = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Void> Function(ffi.IntPtr),
        ffi.Pointer<ffi.Void> Function(int)
      >('bm_framer_new');

  late final _framerFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_framer_free');

  late final _framerFeed = _lib
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
      >('bm_framer_feed');

  late final _handshakerNew = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Void> Function(ffi.Int32),
        ffi.Pointer<ffi.Void> Function(int)
      >('bm_handshaker_new');

  late final _handshakerFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_handshaker_free');

  late final _handshakerOnConnect = _lib
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
      >('bm_handshaker_on_connect');

  late final _handshakerOnMessage = _lib
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
      >('bm_handshaker_on_message');

  late final _handshakerReset = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_handshaker_reset');

  late final _framerReset = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_framer_reset');

  late final _policyResponse = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_policy_response');

  late final _policySnifferNew = _lib
      .lookupFunction<
        ffi.Pointer<ffi.Void> Function(),
        ffi.Pointer<ffi.Void> Function()
      >('bm_policy_sniffer_new');

  late final _policySnifferFree = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_policy_sniffer_free');

  late final _policySnifferFeed = _lib
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
      >('bm_policy_sniffer_feed');

  late final _policySnifferIsWatching = _lib
      .lookupFunction<
        ffi.Bool Function(ffi.Pointer<ffi.Void>),
        bool Function(ffi.Pointer<ffi.Void>)
      >('bm_policy_sniffer_is_watching');

  late final _policySnifferHungUp = _lib
      .lookupFunction<
        ffi.Bool Function(ffi.Pointer<ffi.Void>),
        bool Function(ffi.Pointer<ffi.Void>)
      >('bm_policy_sniffer_hung_up');

  late final _policySnifferReset = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<ffi.Void>),
        void Function(ffi.Pointer<ffi.Void>)
      >('bm_policy_sniffer_reset');

  late final _frame = _lib
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
      >('bm_frame');

  late final _maxMessageLen = _lib
      .lookupFunction<ffi.IntPtr Function(), int Function()>(
        'bm_max_message_len',
      );

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

  late final _generateDeviceId = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_generate_device_id');

  late final _generateAppId = _lib
      .lookupFunction<
        ffi.Bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        ),
        bool Function(
          ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
          ffi.Pointer<ffi.IntPtr>,
        )
      >('bm_generate_app_id');

  void init() {
    if (_initialized) return;
    _bmLibraryInit();
    _initialized = true;
  }

  ffi.Pointer<ffi.Void> createEngine() => _engineNew();

  void freeEngine(ffi.Pointer<ffi.Void> engine) => _engineFree(engine);

  BmSchemeAssembler createSchemeAssembler() =>
      BmSchemeAssembler._(this, _assemblerNew());

  /// Tracks the version exchange for one connection. A controller waits for
  /// the other side and answers, so [LinkRole.responder] is the usual choice.
  BmHandshaker createHandshaker(LinkRole role) =>
      BmHandshaker._(this, _handshakerNew(role.code));

  /// Rejects messages longer than [maxLen], or the library ceiling by default.
  BmFramer createFramer({int? maxLen}) =>
      BmFramer._(this, _framerNew(maxLen ?? _maxMessageLen()));

  BmPolicySniffer createPolicySniffer() =>
      BmPolicySniffer._(this, _policySnifferNew());

  late final Uint8List policyResponse = _readOutOnly(_policyResponse);

  int get maxMessageLen => _maxMessageLen();

  /// Adds the length prefix a stream transport needs. Datagrams send the
  /// message as it is.
  Uint8List frame(Uint8List message) => _checked(
    _callOut(message, (ptr, len, op, ol) => _frame(ptr, len, op, ol)),
  );

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

  String generateDeviceId() => _readIdString(_generateDeviceId);

  String generateAppId() => _readIdString(_generateAppId);

  String _readIdString(
    bool Function(ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.IntPtr>)
    call,
  ) => String.fromCharCodes(_readOutOnly(call));

  Uint8List _readOutOnly(
    bool Function(ffi.Pointer<ffi.Pointer<ffi.Uint8>>, ffi.Pointer<ffi.IntPtr>)
    call,
  ) {
    final outPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final ok = call(outPtr, outLen);
    final bytes = _readOut(ok, outPtr, outLen);
    calloc.free(outPtr);
    calloc.free(outLen);
    return bytes;
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

  /// Null means the call itself was refused; the library said why and
  /// [_takeLastError] has it. Empty bytes are a successful call with nothing
  /// to say, which some calls legitimately have.
  Uint8List? _callOut(
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
    return ok ? out : null;
  }

  Uint8List _checked(Uint8List? out) {
    if (out == null) throw BmError(_takeLastError());
    return out;
  }

  String _takeLastError() {
    final buf = calloc<ffi.Char>(512);
    final n = _getLastError(buf, 512);
    final message = n > 0 ? buf.cast<Utf8>().toDartString() : '';
    calloc.free(buf);
    return message.isEmpty ? 'no further detail' : message;
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

  /// Tells the engine about a peer it could not have learned about on its own,
  /// at an address known out of band.
  void declarePeer(
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
    _callIn(core, (ptr, len) => _declarePeer(engine, ptr, len));
  }

  /// Everything the engine is told about itself. Pass the whole of it whenever
  /// any of it changes; the engine holds nothing over from a previous call.
  ///
  /// A controller that opens its own sessions needs a screen, since it asks a
  /// game for a scheme to fit it.
  bool configure(
    ffi.Pointer<ffi.Void> engine, {
    bool server = false,
    EndpointMode? endpoint,
    bool opensSessions = true,
    bool gyroscope = false,
    bool orientation = false,
    int screenWidth = 0,
    int screenHeight = 0,
    bool approvesRegistrations = true,
    bool datagrams = false,
  }) => _callIn(
    mp.serialize({
      'server': server,
      'endpoint': endpoint?.code,
      'opens_sessions': opensSessions,
      'gyroscope': gyroscope,
      'orientation': orientation,
      'screen_width': screenWidth,
      'screen_height': screenHeight,
      'approves_registrations': approvesRegistrations,
      'datagrams': datagrams,
    }),
    (ptr, len) => _configure(engine, ptr, len),
  );

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

  /// [source] is where the transport says the bytes came from. A transport
  /// that carries no addressing leaves it null and the engine invents none.
  BmProcessOutput processIncoming(
    ffi.Pointer<ffi.Void> engine,
    Uint8List data, {
    String? source,
    bool datagram = false,
    int? nowMs,
  }) {
    final arrival = source == null && nowMs == null
        ? Uint8List(0)
        : mp.serialize({
            'source': source,
            'datagram': datagram,
            'now_ms': nowMs,
          });
    final arrivalPtr = calloc<ffi.Uint8>(arrival.isEmpty ? 1 : arrival.length);
    if (arrival.isNotEmpty) {
      arrivalPtr.asTypedList(arrival.length).setAll(0, arrival);
    }
    final out = _callOut(
      data,
      (ptr, len, op, ol) => _processIncoming(
        engine,
        ptr,
        len,
        arrivalPtr,
        arrival.length,
        op,
        ol,
      ),
    );
    calloc.free(arrivalPtr);
    return _decodeProcessOutput(_checked(out));
  }

  /// Tells the engine what time it is, in milliseconds on any monotonic
  /// clock. Anything due fires, and the output names the next wanted moment.
  BmProcessOutput handleTime(ffi.Pointer<ffi.Void> engine, int nowMs) {
    final outPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final ok = _handleTime(engine, nowMs, outPtr, outLen);
    final out = _readOut(ok, outPtr, outLen);
    calloc.free(outPtr);
    calloc.free(outLen);
    if (!ok) throw BmError(_takeLastError());
    return _decodeProcessOutput(out);
  }

  /// Throws [BmError] when the command itself was wrong. A send to a peer
  /// that has since left is not an error and comes back empty.
  ///
  /// [nowMs] is a reading of any monotonic clock. Passing one lets the engine
  /// hold a paced command back until its turn; passing none never holds
  /// anything back.
  BmProcessOutput emit(
    ffi.Pointer<ffi.Void> engine,
    Map<String, dynamic> command, {
    int? nowMs,
  }) {
    final out = _callOut(
      mp.serialize(command),
      (ptr, len, op, ol) =>
          _emit(engine, ptr, len, nowMs ?? 0, nowMs != null, op, ol),
    );
    return _decodeProcessOutput(_checked(out));
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
    return BmProcessOutput(
      events,
      outgoings,
      decoded['next_time_ms'] as int?,
      decoded['next_send_ms'] as int?,
    );
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
  }).outgoings;

  List<BmOutgoing> makeRegistryList(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) => emit(engine, {
    'type': 'RequestHostList',
    'target': targetId,
    'return_method': null,
  }).outgoings;

  List<BmOutgoing> makeDeviceConnectRequested(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String gameDeviceId,
  ) => emit(engine, {
    'type': 'ConnectToHost',
    'target': targetId,
    'host_id': gameDeviceId,
  }).outgoings;

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
  }).outgoings;

  List<BmOutgoing> makeOnControlSchemeParsed(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
  ) => emit(engine, {
    'type': 'ControlSchemeParsed',
    'target': targetId,
  }).outgoings;

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
  }).outgoings;

  List<BmOutgoing> makeDpadUpdate(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int x,
    int y,
  ) => emit(engine, {
    'type': 'SendDPad',
    'target': targetId,
    'x': x,
    'y': y,
  }).outgoings;

  List<BmOutgoing> makeSendKeyString(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String key,
  ) => emit(engine, {
    'type': 'SendKeyString',
    'target': targetId,
    'key': key,
  }).outgoings;

  List<BmOutgoing> makeSendNavigation(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String nav,
  ) => emit(engine, {
    'type': 'SendNavigation',
    'target': targetId,
    'nav': nav,
  }).outgoings;

  void declareTouch(ffi.Pointer<ffi.Void> engine, bool enabled, int nowMs) {
    emit(engine, {'type': 'DeclareTouch', 'enabled': enabled}, nowMs: nowMs);
  }

  /// Reports what fingers did. The engine keeps the set they add up to and
  /// sends it at the game's cadence, so a batch offered before its turn comes
  /// back with nothing to send and [BmProcessOutput.nextSendMs] naming the
  /// moment to try again.
  BmProcessOutput makeTouchEvents(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    List<BmTouchEvent> events,
    int nowMs,
  ) => emit(engine, {
    'type': 'TouchEvent',
    'target': targetId,
    'events': events.map((e) => e.toWire()).toList(),
  }, nowMs: nowMs);

  /// Sends a set the caller assembled itself, unbatched. For input that does
  /// not arrive as a pointer stream.
  List<BmOutgoing> makeTouchSet(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    List<TouchPointData> touches,
  ) => emit(engine, {
    'type': 'SendTouch',
    'target': targetId,
    'touches': touches.map((t) => t.toWire()).toList(),
  }).outgoings;

  /// Sensor sends are paced by the engine at the interval the game asked for,
  /// so a reading offered before its turn comes back with nothing to send.
  /// These return the whole output because [BmProcessOutput.nextSendMs] is the
  /// point: hold on to it and skip the call until then.
  BmProcessOutput makeAccel(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    int nowMs,
  ) => emit(engine, {
    'type': 'SendAccel',
    'target': targetId,
    'x': x,
    'y': y,
    'z': z,
  }, nowMs: nowMs);

  BmProcessOutput makeGyro(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    int nowMs,
  ) => emit(engine, {
    'type': 'SendGyro',
    'target': targetId,
    'x': x,
    'y': y,
    'z': z,
  }, nowMs: nowMs);

  BmProcessOutput makeOrientation(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    double x,
    double y,
    double z,
    double w,
    int nowMs,
  ) => emit(engine, {
    'type': 'SendOrientation',
    'target': targetId,
    'x': x,
    'y': y,
    'z': z,
    'w': w,
  }, nowMs: nowMs);

  List<BmOutgoing> makeSetCapabilities(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    int capabilities,
  ) => emit(engine, {
    'type': 'SetCapabilities',
    'target': targetId,
    'gyroscope': (capabilities & 1) != 0,
    'orientation': (capabilities & 2) != 0,
  }).outgoings;

  List<BmOutgoing> makePause(ffi.Pointer<ffi.Void> engine, String targetId) =>
      emit(engine, {'type': 'Pause', 'target': targetId}).outgoings;

  List<BmOutgoing> makeMenuEvent(
    ffi.Pointer<ffi.Void> engine,
    String targetId,
    String event,
  ) => emit(engine, {
    'type': 'SendMenuEvent',
    'target': targetId,
    'event': event,
  }).outgoings;

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

/// Which side of a session this engine plays. A server on its own takes neither.
enum EndpointMode {
  game(1),
  controller(2);

  const EndpointMode(this.code);
  final int code;
}

/// Which side of a connection speaks first.
enum LinkRole {
  /// Announces itself as soon as the connection is up.
  initiator(0),

  /// Waits for the other side, then answers.
  responder(1);

  const LinkRole(this.code);
  final int code;
}

/// How the two versions compare.
enum VersionCheck { compatible, localTooOld, remoteTooOld, unknown }

/// The result of offering one message to a [BmHandshaker].
class HandshakeOutcome {
  /// True when this was not a version exchange, so it belongs to the engine.
  final bool passthrough;

  /// Bytes to send back, when an answer is owed.
  final Uint8List? reply;
  final VersionCheck check;

  const HandshakeOutcome._(this.passthrough, this.reply, this.check);

  static const passthroughResult = HandshakeOutcome._(
    true,
    null,
    VersionCheck.compatible,
  );

  bool get compatible => check == VersionCheck.compatible;
}

/// The library refused a call, and this is what it said.
class BmError implements Exception {
  final String message;
  const BmError(this.message);
  @override
  String toString() => 'BmError: $message';
}

/// Raised when a stream can no longer be split into messages.
class BmFramingException implements Exception {
  final String message;
  const BmFramingException(this.message);
  @override
  String toString() => 'BmFramingException: $message';
}

/// Tracks the version exchange for one connection.
class BmHandshaker {
  final BmLib _lib;
  ffi.Pointer<ffi.Void> _ptr;

  BmHandshaker._(this._lib, this._ptr);

  /// What to send now the connection is up. A responder sends nothing.
  Uint8List? onConnect() {
    if (_ptr == ffi.nullptr) return null;
    final outPtr = calloc<ffi.Pointer<ffi.Uint8>>();
    final outLen = calloc<ffi.IntPtr>();
    final ok = _lib._handshakerOnConnect(_ptr, outPtr, outLen);
    final bytes = _lib._readOut(ok, outPtr, outLen);
    calloc.free(outPtr);
    calloc.free(outLen);
    return bytes.isEmpty ? null : bytes;
  }

  /// Offers one message. A passthrough result belongs to the engine.
  HandshakeOutcome onMessage(Uint8List message) {
    if (_ptr == ffi.nullptr) return HandshakeOutcome.passthroughResult;
    final out = _lib._checked(
      _lib._callOut(
        message,
        (ptr, len, op, ol) => _lib._handshakerOnMessage(_ptr, ptr, len, op, ol),
      ),
    );
    if (out.isEmpty) return HandshakeOutcome.passthroughResult;
    final decoded = mp.deserialize(out) as Map;
    if (decoded['type'] != 'Received') {
      return HandshakeOutcome.passthroughResult;
    }
    final reply = decoded['reply'];
    return HandshakeOutcome._(
      false,
      reply == null ? null : Uint8List.fromList(List<int>.from(reply)),
      switch (decoded['check']) {
        'Compatible' => VersionCheck.compatible,
        'LocalTooOld' => VersionCheck.localTooOld,
        'RemoteTooOld' => VersionCheck.remoteTooOld,
        _ => VersionCheck.unknown,
      },
    );
  }

  /// Forgets the exchange so a reconnect starts over. A handshaker that still
  /// thinks it has spoken will never answer the next connection.
  void reset() {
    if (_ptr != ffi.nullptr) _lib._handshakerReset(_ptr);
  }

  void dispose() {
    if (_ptr != ffi.nullptr) {
      _lib._handshakerFree(_ptr);
      _ptr = ffi.nullptr;
    }
  }
}

enum PolicySniffKind { wait, answer, passthrough }

class PolicySniff {
  final PolicySniffKind kind;
  final Uint8List? data;
  const PolicySniff._(this.kind, this.data);
  static const waitResult = PolicySniff._(PolicySniffKind.wait, null);
}

class BmPolicySniffer {
  final BmLib _lib;
  ffi.Pointer<ffi.Void> _ptr;

  BmPolicySniffer._(this._lib, this._ptr);

  bool get isWatching =>
      _ptr != ffi.nullptr && _lib._policySnifferIsWatching(_ptr);

  bool hungUp() => _ptr != ffi.nullptr && _lib._policySnifferHungUp(_ptr);

  PolicySniff feed(List<int> data) {
    if (_ptr == ffi.nullptr) {
      return PolicySniff._(
        PolicySniffKind.passthrough,
        data is Uint8List ? data : Uint8List.fromList(data),
      );
    }
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    final out = _lib._checked(
      _lib._callOut(
        bytes,
        (ptr, len, op, ol) => _lib._policySnifferFeed(_ptr, ptr, len, op, ol),
      ),
    );
    if (out.isEmpty) return PolicySniff.waitResult;
    final decoded = mp.deserialize(out) as Map;
    switch (decoded['type']) {
      case 'Answer':
        return const PolicySniff._(PolicySniffKind.answer, null);
      case 'Passthrough':
        return PolicySniff._(
          PolicySniffKind.passthrough,
          Uint8List.fromList(List<int>.from(decoded['data'] as List)),
        );
      default:
        return PolicySniff.waitResult;
    }
  }

  /// Starts over, so the next connection is watched from its first byte.
  void reset() {
    if (_ptr != ffi.nullptr) _lib._policySnifferReset(_ptr);
  }

  void dispose() {
    if (_ptr != ffi.nullptr) {
      _lib._policySnifferFree(_ptr);
      _ptr = ffi.nullptr;
    }
  }
}

/// Reassembles messages from a stream that arrives in arbitrary pieces.
class BmFramer {
  final BmLib _lib;
  ffi.Pointer<ffi.Void> _ptr;

  BmFramer._(this._lib, this._ptr);

  /// Adds bytes and returns every message they completed, which is often none
  /// while one is still arriving. Throws [BmFramingException] when the stream
  /// is out of step, since there is no way to find the next boundary again.
  List<Uint8List> feed(List<int> data) {
    if (_ptr == ffi.nullptr) return const [];
    final bytes = data is Uint8List ? data : Uint8List.fromList(data);
    final out = _lib._callOut(
      bytes,
      (ptr, len, op, ol) => _lib._framerFeed(_ptr, ptr, len, op, ol),
    );
    if (out == null) {
      throw BmFramingException(_lib._takeLastError());
    }
    final decoded = mp.deserialize(out) as List;
    return decoded.map((m) => Uint8List.fromList(List<int>.from(m))).toList();
  }

  /// Drops anything half read, for when a connection restarts.
  void reset() {
    if (_ptr != ffi.nullptr) _lib._framerReset(_ptr);
  }

  void dispose() {
    if (_ptr != ffi.nullptr) {
      _lib._framerFree(_ptr);
      _ptr = ffi.nullptr;
    }
  }
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
