// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart' as mp;

class BmLogRecord {
  final int seq;

  final String level;
  final String target;
  final String message;

  const BmLogRecord(this.seq, this.level, this.target, this.message);
}

class BmLogDrain {
  final List<BmLogRecord> records;
  final int dropped;

  const BmLogDrain(this.records, this.dropped);

  factory BmLogDrain.fromBytes(Uint8List bytes) {
    if (bytes.isEmpty) return const BmLogDrain([], 0);
    final decoded = mp.deserialize(bytes);
    if (decoded is! Map) return const BmLogDrain([], 0);
    final records = ((decoded['records'] as List?) ?? const []).map((e) {
      final m = e as Map;
      return BmLogRecord(
        (m['seq'] as int?) ?? 0,
        (m['level'] as String?) ?? 'Info',
        (m['target'] as String?) ?? '',
        (m['message'] as String?) ?? '',
      );
    }).toList();
    return BmLogDrain(records, (decoded['dropped'] as int?) ?? 0);
  }
}
