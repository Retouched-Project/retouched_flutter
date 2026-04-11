// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:typed_data';

class MessageFramer {
  final BytesBuilder _buffer = BytesBuilder();

  List<Uint8List> feed(List<int> data) {
    _buffer.add(Uint8List.fromList(data));
    return drain();
  }

  List<Uint8List> drain() {
    final raw = _buffer.toBytes();
    int offset = 0;
    final frames = <Uint8List>[];

    while (true) {
      if (raw.length - offset < 4) break;
      final len = ByteData.sublistView(
        raw,
        offset,
        offset + 4,
      ).getUint32(0, Endian.little);
      if (raw.length - offset - 4 < len) break;
      final frameEnd = offset + 4 + len;
      frames.add(Uint8List.sublistView(raw, offset, frameEnd));
      offset = frameEnd;
    }

    if (offset > 0) {
      final remain = (offset < raw.length)
          ? Uint8List.sublistView(raw, offset)
          : Uint8List(0);
      _buffer.clear();
      if (remain.isNotEmpty) _buffer.add(remain);
    }

    return frames;
  }

  void clear() {
    _buffer.clear();
  }
}
