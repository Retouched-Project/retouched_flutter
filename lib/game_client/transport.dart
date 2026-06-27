// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientTransport on GameClient {
  void _sendOutgoings(List<BmOutgoing> outgoings) {
    for (final outgoing in outgoings) {
      if (debugWire) _logHex('TX frame', outgoing.payload);
      final game = _activeGame;
      if (outgoing.reliability == 0 &&
          game != null &&
          game.unreliablePort != 0 &&
          outgoing.targetDeviceId == game.deviceId &&
          _udpSocket != null) {
        _sendUdp(outgoing.payload.sublist(4));
      } else {
        final socket = _resolveSocket(outgoing.targetDeviceId);
        socket?.add(outgoing.payload);
      }
    }
  }

  void _sendUdp(Uint8List payload) {
    final game = _activeGame;
    if (game == null || _udpSocket == null) return;
    final target = InternetAddress.tryParse(game.address);
    if (target == null) return;
    _udpSocket!.send(payload, target, game.unreliablePort);
  }

  Socket? _resolveSocket(String targetDeviceId) {
    if (targetDeviceId == serverDeviceId) return _socket;
    if (_activeGame != null && targetDeviceId == _activeGame!.deviceId) {
      return _gameSocket ?? _socket;
    }
    return _socket;
  }

  bool _handlePolicyRequest(List<int> data) {
    if (data.isEmpty) return false;
    if (data[0] == 0x3C || _policyBuffer.isNotEmpty) {
      _policyBuffer.addAll(data);
      if (_policyBuffer.length >= _policyRequestBytes.length) {
        final socket = _gameSocket;
        if (socket != null) {
          socket.add(_policyResponseBytes);
          socket
              .flush()
              .catchError((_) {})
              .then((_) => socket.close().catchError((_) {}));
        }
        _isHandlingPolicy = true;
        _policyBuffer.clear();
        _gameFramer.clear();
      }
      return true;
    }
    return false;
  }

  void _logHex(String tag, Uint8List data) {
    final sb = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      if (i > 0) sb.write(' ');
      sb.write(data[i].toRadixString(16).padLeft(2, '0'));
    }
    _wireLog.fine('$tag (${data.length} bytes): $sb');
  }
}
