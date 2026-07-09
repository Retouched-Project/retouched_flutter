// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class LogEntry {
  final DateTime time;

  final String level;
  final String source;
  final String message;

  const LogEntry(this.time, this.level, this.source, this.message);
}

class LogStore extends ChangeNotifier {
  LogStore._();
  static final LogStore instance = LogStore._();

  static const int maxEntries = 2000;
  final List<LogEntry> _entries = [];
  bool _notifyScheduled = false;

  List<LogEntry> get entries => _entries;

  void add(LogEntry e) {
    _entries.add(e);
    _trim();
    _scheduleNotify();
  }

  void addAll(List<LogEntry> es) {
    if (es.isEmpty) return;
    _entries.addAll(es);
    _trim();
    _scheduleNotify();
  }

  void clear() {
    _entries.clear();
    _scheduleNotify();
  }

  void _trim() {
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
  }

  void _scheduleNotify() {
    if (_notifyScheduled || !hasListeners) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
    SchedulerBinding.instance.scheduleFrame();
  }
}
