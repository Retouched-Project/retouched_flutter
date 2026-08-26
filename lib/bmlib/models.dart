// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:typed_data';

const List<String> _touchStateNames = [
  '',
  'Began',
  'Moved',
  'Stationary',
  'Ended',
  'Cancelled',
];

Uint8List _bytes(dynamic v) {
  if (v == null) return Uint8List(0);
  if (v is Uint8List) return v;
  if (v is List) return Uint8List.fromList(List<int>.from(v));
  return Uint8List(0);
}

class BmRegistryInfo {
  final int slotId;
  final String appId;
  final int? currentPlayers;
  final int? maxPlayers;
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

  factory BmRegistryInfo.fromWire(Map m) {
    final device = (m['device'] as Map?) ?? const {};
    final addr = (m['device_address'] as Map?) ?? const {};
    return BmRegistryInfo(
      slotId: (m['slot_id'] as int?) ?? 0,
      appId: (m['app_id'] as String?) ?? '',
      currentPlayers: m['current_players'] as int?,
      maxPlayers: m['max_players'] as int?,
      deviceType: (device['device_type'] as int?) ?? 0,
      deviceId: (device['device_id'] as String?) ?? '',
      deviceName: (device['device_name'] as String?) ?? '',
      address: (addr['address'] as String?) ?? '',
      unreliablePort: (addr['unreliable_port'] as int?) ?? 0,
      reliablePort: (addr['reliable_port'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toWire() {
    final addr = {
      'address': address,
      'unreliable_port': unreliablePort,
      'reliable_port': reliablePort,
    };
    return {
      'slot_id': slotId,
      'app_id': appId,
      'current_players': currentPlayers,
      'max_players': maxPlayers,
      'device': {
        'device_id': deviceId,
        'device_name': deviceName,
        'device_type': deviceType,
        'address': addr,
      },
      'device_address': addr,
    };
  }
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

  Map<String, dynamic> toWire() => {
    'id': id,
    'x': x,
    'y': y,
    'screen_width': screenWidth,
    'screen_height': screenHeight,
    'state': _touchStateNames[state],
  };
}

/// Stationary is absent on purpose: the engine reaches it once a set has gone,
/// and a caller never observes it.
enum BmTouchPhase {
  began('Began'),
  moved('Moved'),
  ended('Ended'),
  cancelled('Cancelled');

  const BmTouchPhase(this.wireName);
  final String wireName;
}

sealed class BmTouchEvent {
  const BmTouchEvent();
  Map<String, dynamic> toWire();
}

class BmPointerEvent extends BmTouchEvent {
  final int id;
  final double x;
  final double y;
  final BmTouchPhase phase;
  final int screenWidth;
  final int screenHeight;

  const BmPointerEvent({
    required this.id,
    required this.x,
    required this.y,
    required this.phase,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Map<String, dynamic> toWire() => {
    'type': 'Pointer',
    'id': id,
    'x': x,
    'y': y,
    'phase': phase.wireName,
    'screen_width': screenWidth,
    'screen_height': screenHeight,
  };
}

class BmCancelAllTouches extends BmTouchEvent {
  const BmCancelAllTouches();

  @override
  Map<String, dynamic> toWire() => {'type': 'CancelAll'};
}

/// Which path an outgoing message is built for, and where that path leads.
class BmVia {
  final bool datagram;

  /// Where to send it, when the path is a datagram. A transport that reaches
  /// the peer another way can ignore both.
  final String address;
  final int port;

  const BmVia._(this.datagram, this.address, this.port);

  static const stream = BmVia._(false, '', 0);

  factory BmVia.fromWire(Object? value) {
    if (value is! Map || value['type'] != 'Datagram') return stream;
    return BmVia._(
      true,
      (value['address'] as String?) ?? '',
      (value['port'] as int?) ?? 0,
    );
  }
}

class BmOutgoing {
  final String targetDeviceId;
  final int channel;
  final int reliability;

  /// Which path these bytes are built for.
  final BmVia via;

  /// Ready to write on [via], with nothing left to add or strip.
  final Uint8List payload;

  const BmOutgoing(
    this.targetDeviceId,
    this.channel,
    this.reliability,
    this.via,
    this.payload,
  );

  factory BmOutgoing.fromWire(Map m) => BmOutgoing(
    (m['target_device_id'] as String?) ?? '',
    (m['channel'] as int?) ?? 0,
    (m['reliability'] as int?) ?? 0,
    BmVia.fromWire(m['via']),
    _bytes(m['payload']),
  );
}

class BmEvent {
  final String type;
  final Map raw;

  const BmEvent(this.type, this.raw);

  String get sender => (raw['sender'] as String?) ?? '';
  String get deviceId => (raw['device_id'] as String?) ?? '';

  Map? get _peerCore => (raw['record'] as Map?)?['core'] as Map?;
  String get peerDeviceId => (_peerCore?['device_id'] as String?) ?? '';
  int get peerUnreliablePort => (raw['udp_port'] as int?) ?? 0;
  bool get success => (raw['success'] as bool?) ?? false;
  String? get domain => raw['domain'] as String?;

  BmRegistryInfo? get info =>
      raw['info'] == null ? null : BmRegistryInfo.fromWire(raw['info'] as Map);
  List<BmRegistryInfo> get infos => ((raw['infos'] as List?) ?? const [])
      .map((e) => BmRegistryInfo.fromWire(e as Map))
      .toList();

  String get setId => (raw['set_id'] as String?) ?? '';
  int get current => (raw['current'] as int?) ?? 0;
  int get total => (raw['total'] as int?) ?? 0;
  int get minimum => (raw['minimum'] as int?) ?? 0;
  String get method => (raw['method'] as String?) ?? '';
  Uint8List get blob => _bytes(raw['blob']);
  Uint8List get scheme => _bytes(raw['scheme']);

  double get x => (raw['x'] as num?)?.toDouble() ?? 0.0;
  double get y => (raw['y'] as num?)?.toDouble() ?? 0.0;
  double get z => (raw['z'] as num?)?.toDouble() ?? 0.0;
  double get w => (raw['w'] as num?)?.toDouble() ?? 0.0;
  int get dpadX => (raw['x'] as int?) ?? 0;
  int get dpadY => (raw['y'] as int?) ?? 0;
  String get handler => (raw['handler'] as String?) ?? '';
  bool get pressed => (raw['pressed'] as bool?) ?? false;
  String get eventName => (raw['event'] as String?) ?? '';
  String get key => (raw['key'] as String?) ?? '';
  String get nav => (raw['nav'] as String?) ?? '';

  // ControlConfig fields are flattened in for the ControlConfig variant.
  bool? get touchEnabled => raw['touch_enabled'] as bool?;
  bool? get accelEnabled => raw['accel_enabled'] as bool?;
  bool? get gyroEnabled => raw['gyro_enabled'] as bool?;
  bool? get orientationEnabled => raw['orientation_enabled'] as bool?;
  int? get touchIntervalMs => raw['touch_interval_ms'] as int?;
  int? get accelIntervalMs => raw['accel_interval_ms'] as int?;
  int? get gyroIntervalMs => raw['gyro_interval_ms'] as int?;
  int? get orientationIntervalMs => raw['orientation_interval_ms'] as int?;
  String? get controlMode => raw['control_mode'] as String?;
  String? get portalId => raw['portal_id'] as String?;
  String? get returnAppId => raw['return_app_id'] as String?;
  String? get startString => raw['start_string'] as String?;
}

class BmProcessOutput {
  final List<BmEvent> events;
  final List<BmOutgoing> outgoings;

  /// When the engine next wants [BmLib.handleTime], on the caller's own
  /// clock. Null when nothing is scheduled. This is for a timer.
  final int? nextTimeMs;

  /// The earliest moment a send of the kind just emitted would be accepted,
  /// when that send was weighed against a cadence. This is for skipping calls
  /// that have no chance.
  final int? nextSendMs;

  const BmProcessOutput(
    this.events,
    this.outgoings, [
    this.nextTimeMs,
    this.nextSendMs,
  ]);
}
