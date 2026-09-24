// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game_client/game_client.dart';

class ServerEntry {
  static const int defaultRegistryPort = 8088;
  static const int defaultHttpPort = 8080;

  final String name;
  final String ip;
  final String? localIp;
  final int registryPort;
  final int httpPort;

  const ServerEntry({
    required this.name,
    required this.ip,
    this.localIp,
    this.registryPort = defaultRegistryPort,
    this.httpPort = defaultHttpPort,
  });

  String get address => '$ip:$registryPort';

  bool sameServerAs(ServerEntry other) =>
      ip == other.ip &&
      registryPort == other.registryPort &&
      httpPort == other.httpPort;

  Map<String, dynamic> toJson() => {
    'name': name,
    'ip': ip,
    'local_ip': localIp,
    'registry_port': registryPort,
    'http_port': httpPort,
  };

  factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
    name: json['name'] as String,
    ip: json['ip'] as String,
    localIp: (json['local_ip'] as String?)?.trim().isEmpty == true
        ? null
        : json['local_ip'] as String?,
    registryPort: (json['registry_port'] as int?) ?? defaultRegistryPort,
    httpPort: (json['http_port'] as int?) ?? defaultHttpPort,
  );
}

class ServerManager extends ChangeNotifier {
  static const String _prefsKey = 'servers';
  final List<ServerEntry> _servers = <ServerEntry>[];
  UnmodifiableListView<ServerEntry> get servers =>
      UnmodifiableListView<ServerEntry>(_servers);

  GameClient? _client;
  GameClient? get activeClient => _client;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? const <String>[];
    final items = raw
        .map((s) => ServerEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    _servers
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<void> add(ServerEntry entry) async {
    _servers.add(entry);
    await _save();
    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    _servers.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> replaceAt(int index, ServerEntry entry) async {
    _servers[index] = entry;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _servers.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefsKey, raw);
  }

  Future<List<String>> connectAndFetchGames(
    ServerEntry server, {
    Duration listTimeout = const Duration(seconds: 5),
  }) async {
    try {
      await _client?.close();
    } catch (_) {}
    _client = GameClient(server);
    await _client!.connect();
    final list = await _client!.waitForList(listTimeout);
    return list;
  }

  Future<void> disconnectActive() async {
    try {
      await _client?.close();
    } catch (_) {}
    _client = null;
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }
}
