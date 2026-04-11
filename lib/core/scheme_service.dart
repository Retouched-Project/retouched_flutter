// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'package:logging/logging.dart';
import '../bmlib/bm_lib.dart';
import '../bmrender/controls/scheme.pb.dart';
import '../bmrender/controls/scheme_extensions.dart';

class SchemeService {
  static final _log = Logger('retouched.SchemeService');

  final BmLib _lib;
  final bool Function() debugWire;

  ControlScheme? scheme;
  String? _lastUpdateXml;

  SchemeService(this._lib, {required this.debugWire});

  ControlScheme? handleChunkComplete(
    BmChunkCompleteAction action, {
    required ffi.Pointer<ffi.Void> engine,
    required String? activeGameDeviceId,
    required String? deviceId,
    required void Function(List<BmAction>) sendActions,
  }) {
    final bytes = action.blob;
    if (bytes.isEmpty) return null;

    ControlScheme? parsed;
    String? xml;
    try {
      if (debugWire()) {
        final head = bytes.length > 20 ? bytes.sublist(0, 20) : bytes;
        _log.fine('Chunk complete (${bytes.length} bytes). Head: $head');
      }

      try {
        xml = utf8.decode(bytes, allowMalformed: true);
      } catch (e) {
        _log.warning('UTF-8 decode failed: $e');
      }

      if (xml != null && xml.contains('<BMApplicationScheme')) {
        _logXml(xml);
        final protoBytes = _lib.parseControlSchemeXml(xml);
        if (protoBytes.isNotEmpty) {
          parsed = ControlScheme.fromBuffer(protoBytes);
        } else {
          _log.warning('XML parsed to empty Protobuf');
        }
      } else {
        if (debugWire()) {
          _log.fine(
            'Received binary chunk (${bytes.length} bytes), attempting Protobuf decode.',
          );
        }
        parsed = ControlScheme.fromBuffer(bytes);
      }
    } catch (e) {
      _log.severe('Chunk parse error: $e');
      return null;
    }

    if (parsed == null) return null;

    if (action.setId == 'testXML') {
      _lastUpdateXml = null;
      scheme = parsed;
      if (activeGameDeviceId != null && deviceId != null) {
        final actions = _lib.makeOnControlSchemeParsed(
          engine,
          activeGameDeviceId,
          deviceId,
        );
        sendActions(actions);
      }
      return scheme;
    } else if (action.setId == 'updateXML') {
      if (xml != null && xml == _lastUpdateXml) return null;
      _lastUpdateXml = xml;

      if (scheme != null) {
        scheme = scheme!.merge(parsed);
      } else {
        scheme = parsed;
      }
      return scheme;
    }
    return null;
  }

  void reset() {
    scheme = null;
    _lastUpdateXml = null;
  }

  void _logXml(String xml) {
    if (!debugWire()) return;

    final pattern = RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true);
    final truncated = xml.replaceAllMapped(pattern, (match) {
      final content = match.group(1) ?? '';
      if (content.length > 100) {
        return '<![CDATA[${content.substring(0, 50)}...${content.substring(content.length - 50)} (${content.length} bytes total)]]>';
      }
      return match.group(0)!;
    });

    _log.fine('XML Dump:\n$truncated');
  }
}
