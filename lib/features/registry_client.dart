// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:ffi' as ffi;
import '../bmlib/bm_lib.dart';

class RegistryClient {
  final BmLib _lib;

  List<String> games = const [];
  List<BmRegistryInfo> gameInfos = const [];
  Completer<void>? registerCompleter;
  Completer<void>? listCompleter;

  ffi.Pointer<ffi.Void> Function()? getEngine;
  void Function(List<BmAction>)? sendActions;
  void Function(List<String>)? onGamesChanged;

  RegistryClient(this._lib);

  void handleRegistryEvent(BmRegistryEventAction action) {
    if (action.kind == RegistryEventKindCodes.onRegister) {
      _safeComplete(registerCompleter);
      return;
    }
    if (action.kind == RegistryEventKindCodes.onList) {
      _replaceGameInfos(action.infos);
      _safeComplete(listCompleter);
      return;
    }
    if (action.kind == RegistryEventKindCodes.onHostConnected ||
        action.kind == RegistryEventKindCodes.onHostUpdate) {
      _updateGameInfos(action.infos);
    }
    if (action.kind == RegistryEventKindCodes.onHostDisconnected) {
      _removeGameInfos(action.infos);
    }
  }

  void _replaceGameInfos(List<BmRegistryInfo> infos) {
    final filtered = infos
        .where(
          (i) =>
              i.deviceType == DeviceTypeCodes.flash ||
              i.deviceType == DeviceTypeCodes.unity,
        )
        .toList();
    for (final g in filtered) {
      final engine = getEngine?.call();
      if (engine != null) {
        _lib.registerDevice(
          engine,
          g.deviceId,
          g.deviceName,
          g.deviceType,
          g.address,
          g.unreliablePort,
          g.reliablePort,
        );
      }
    }
    gameInfos = filtered;
    games = gameInfos.map((g) => g.deviceName).toList(growable: false);
    onGamesChanged?.call(List.unmodifiable(games));
  }

  void _updateGameInfos(List<BmRegistryInfo> infos) {
    final filtered = infos
        .where(
          (i) =>
              i.deviceType == DeviceTypeCodes.flash ||
              i.deviceType == DeviceTypeCodes.unity,
        )
        .toList();
    if (filtered.isEmpty) return;
    final map = {for (final g in gameInfos) g.deviceId: g};
    for (final g in filtered) {
      map[g.deviceId] = g;
      final engine = getEngine?.call();
      if (engine != null) {
        _lib.registerDevice(
          engine,
          g.deviceId,
          g.deviceName,
          g.deviceType,
          g.address,
          g.unreliablePort,
          g.reliablePort,
        );
      }
    }
    gameInfos = map.values.toList(growable: false);
    games = gameInfos.map((g) => g.deviceName).toList(growable: false);
    onGamesChanged?.call(List.unmodifiable(games));
  }

  void _removeGameInfos(List<BmRegistryInfo> infos) {
    if (infos.isEmpty) return;
    final removeIds = infos.map((i) => i.deviceId).toSet();
    gameInfos = gameInfos
        .where((g) => !removeIds.contains(g.deviceId))
        .toList(growable: false);
    games = gameInfos.map((g) => g.deviceName).toList(growable: false);
    onGamesChanged?.call(List.unmodifiable(games));
  }

  void reset() {
    games = const [];
    gameInfos = const [];
  }

  static void _safeComplete(Completer<void>? completer) {
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
