// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

import '../bmlib/bm_lib.dart';
import 'log_store.dart';

Timer? _drainTimer;

const List<Level> selectorLevels = [
  Level.SEVERE,
  Level.WARNING,
  Level.INFO,
  Level.FINE,
  Level.FINEST,
];

Level logLevel = Level.INFO;

String levelLabel(Level l) {
  if (l >= Level.SEVERE) return 'Error';
  if (l >= Level.WARNING) return 'Warn';
  if (l >= Level.INFO) return 'Info';
  if (l >= Level.FINE) return 'Debug';
  return 'Trace';
}

int libCode(Level l) {
  if (l >= Level.SEVERE) return 1;
  if (l >= Level.WARNING) return 2;
  if (l >= Level.INFO) return 3;
  if (l >= Level.FINE) return 4;
  return 5;
}

void setupLogging({int capacity = LogStore.maxEntries}) {
  Logger.root.level = logLevel;
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    LogStore.instance.add(
      LogEntry(
        record.time,
        levelLabel(record.level),
        record.loggerName,
        record.message,
      ),
    );
  });

  final lib = BmLib.instance;
  lib.init();
  lib.configureLogging(libCode(logLevel), capacity);
  startLogDrain();
}

void setLogLevel(Level level) {
  logLevel = level;
  Logger.root.level = level;
  BmLib.instance.setLogLevel(libCode(level));
}

void startLogDrain() {
  _drainTimer?.cancel();
  _drainTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
    final drain = BmLib.instance.takeLogs();
    if (drain.records.isEmpty && drain.dropped == 0) return;

    final batch = <LogEntry>[];
    for (final r in drain.records) {
      developer.log(
        r.message,
        name: r.target,
        level: _engineLevelValue(r.level),
      );
      batch.add(LogEntry(DateTime.now(), r.level, r.target, r.message));
    }
    if (drain.dropped > 0) {
      final msg = '${drain.dropped} lib log records dropped (ring overflow)';
      developer.log(msg, name: 'bronze_monkey');
      batch.add(LogEntry(DateTime.now(), 'Warn', 'bronze_monkey', msg));
    }
    LogStore.instance.addAll(batch);
  });
}

int _engineLevelValue(String name) {
  switch (name) {
    case 'Error':
      return Level.SEVERE.value;
    case 'Warn':
      return Level.WARNING.value;
    case 'Info':
      return Level.INFO.value;
    case 'Debug':
      return Level.FINE.value;
    case 'Trace':
      return Level.FINEST.value;
    default:
      return Level.INFO.value;
  }
}
