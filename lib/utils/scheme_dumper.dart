// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('scheme_dumper');

/// Saves completed chunk sets to app storage so real control schemes can be
/// collected as test material. Off by default, since a scheme carries the
/// game's artwork (base64 PNGs) and can amount to megabytes.
class SchemeDumper {
  static const String prefKey = 'dumpSchemes';

  static final SchemeDumper instance = SchemeDumper._();

  SchemeDumper._();

  bool enabled = false;
  Future<Directory>? _root;
  final Map<String, Future<_GameFolder>> _games = {};

  Future<String> location() async => (await _resolveRoot()).path;

  /// One file per document, under a folder named after the game that sent it.
  /// A document already saved for that game is skipped, so reconnecting does
  /// not pile up copies of a scheme we have.
  Future<void> save(
    String setId,
    List<int> blob,
    String appId,
    String deviceName,
  ) async {
    if (!enabled || blob.isEmpty) return;
    final game = _folderFor(appId, deviceName);
    try {
      final folder = await (_games[game] ??= _openGame(game));
      final hash = _hash(blob);
      // Claim the name before any await, so two documents completing together
      // cannot take the same sequence number or race past the duplicate check.
      if (!folder.seen.add(hash)) {
        _log.fine('$game: already have ${_clean(setId)} $hash');
        return;
      }
      final ext = blob.first == 0x3c ? 'xml' : 'bin';
      final name = '${_clean(setId)}_${folder.seq++}_$hash.$ext';
      await File('${folder.dir.path}/$name').writeAsBytes(blob, flush: true);
      _log.info('$game/$name, ${blob.length} bytes');
    } catch (e) {
      _log.warning('scheme dump failed: $e');
      _games.remove(game);
    }
  }

  /// How much is saved, for the settings screen to show before offering to
  /// throw it away.
  Future<({int files, int bytes})> summary() async {
    var files = 0;
    var bytes = 0;
    for (final file in await _saved()) {
      files++;
      bytes += await file.length();
    }
    return (files: files, bytes: bytes);
  }

  /// Deletes only the files this class wrote, identified by the content tag in
  /// their name, then the folders they leave empty. Nothing is removed
  /// recursively and nothing unrecognised is touched, so a stray file in there
  /// survives and keeps its folder alive with it.
  Future<int> clear() async {
    var removed = 0;
    for (final file in await _saved()) {
      await file.delete();
      removed++;
    }
    final root = await _resolveRoot();
    if (await root.exists()) {
      await for (final entry in root.list()) {
        if (entry is Directory) await _deleteIfEmpty(entry);
      }
      await _deleteIfEmpty(root);
    }
    _games.clear();
    _root = null;
    _log.info('cleared $removed saved scheme files');
    return removed;
  }

  /// Every file under the root that carries our content tag, one game folder
  /// deep, which is the only shape this class ever writes.
  Future<List<File>> _saved() async {
    final root = await _resolveRoot();
    if (!await root.exists()) return const [];
    final found = <File>[];
    await for (final game in root.list()) {
      if (game is! Directory) continue;
      await for (final entry in game.list()) {
        if (entry is File && _tagged.hasMatch(entry.uri.pathSegments.last)) {
          found.add(entry);
        }
      }
    }
    return found;
  }

  Future<void> _deleteIfEmpty(Directory dir) async {
    if (await dir.list().isEmpty) await dir.delete();
  }

  /// Names the folder without creating it, so opening the settings screen
  /// does not leave an empty one behind.
  Future<Directory> _resolveRoot() async {
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    return Directory('${base.path}/schemes');
  }

  Future<Directory> _openRoot() async =>
      (await _resolveRoot()).create(recursive: true);

  /// Reads back what a previous run left, so the sequence keeps counting and
  /// the duplicate check spans restarts rather than just the session.
  Future<_GameFolder> _openGame(String game) async {
    final root = await (_root ??= _openRoot());
    final dir = await Directory('${root.path}/$game').create(recursive: true);
    final seen = <String>{};
    var seq = 0;
    await for (final entry in dir.list()) {
      final tag = _tagged.firstMatch(entry.uri.pathSegments.last);
      if (tag != null) seen.add(tag.group(1)!);
      seq++;
    }
    return _GameFolder(dir, seen, seq);
  }

  static final RegExp _tagged = RegExp(r'_([0-9a-f]{16})\.[a-z]+$');

  /// Two games on one host can share an app id (great...), so the name is what actually
  /// tells them apart on disk and the id is only there to break a tie.
  static String _folderFor(String appId, String deviceName) {
    final name = _clean(deviceName).replaceAll(RegExp(r'^_+|_+$'), '');
    final id = _clean(appId);
    final tie = id.length > 8 ? id.substring(0, 8) : id;
    if (name.isEmpty) return id.isEmpty ? 'unknown' : id;
    return tie.isEmpty ? name : '${name}_$tie';
  }

  static String _clean(String s) =>
      s.replaceAll(RegExp(r'[^A-Za-z0-9.-]'), '_');

  /// FNV-1a, should be enough to tell two schemes apart without
  /// pulling in a hash dependency.
  static String _hash(List<int> bytes) {
    var h = 0xcbf29ce484222325;
    for (final b in bytes) {
      h = (h ^ b) * 0x100000001b3;
    }
    final hi = (h >>> 32).toRadixString(16).padLeft(8, '0');
    final lo = (h & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return '$hi$lo';
  }
}

class _GameFolder {
  _GameFolder(this.dir, this.seen, this.seq);

  final Directory dir;
  final Set<String> seen;
  int seq;
}
