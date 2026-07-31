// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientTransport on GameClient {
  void _sendOutgoings(List<BmOutgoing> outgoings) {
    for (final outgoing in outgoings) {
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

  List<int>? _filterPolicyRequest(List<int> data) {
    if (!_policySniffArmed) return data;
    if (data.isEmpty) return null;

    _policyBuffer.addAll(data);
    final probe = _policyBuffer.length < _policyRequestBytes.length
        ? _policyBuffer.length
        : _policyRequestBytes.length;
    for (var i = 0; i < probe; i++) {
      if (_policyBuffer[i] != _policyRequestBytes[i]) {
        _policySniffArmed = false;
        final buffered = List<int>.of(_policyBuffer);
        _policyBuffer.clear();
        return buffered;
      }
    }
    if (_policyBuffer.length < _policyRequestBytes.length) return null;

    _policySniffArmed = false;
    _policyBuffer.clear();
    _gameFramer.clear();
    _isHandlingPolicy = true;
    final socket = _gameSocket;
    if (socket != null) {
      socket.add(_policyResponseBytes);
      socket
          .flush()
          .catchError((_) {})
          .then((_) => socket.close().catchError((_) {}));
    }
    return null;
  }
}
