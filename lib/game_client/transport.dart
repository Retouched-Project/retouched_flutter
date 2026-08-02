// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientTransport on GameClient {
  void _sendOutgoings(List<BmOutgoing> outgoings) {
    for (final outgoing in outgoings) {
      final game = _activeGame;
      if (outgoing.prefersDatagram &&
          game != null &&
          outgoing.targetDeviceId == game.deviceId) {
        // A datagram carries the message as it is.
        _sendUdp(outgoing.payload);
      } else {
        // A stream needs the length in front.
        final socket = _resolveSocket(outgoing.targetDeviceId);
        socket?.add(_lib.frame(outgoing.payload));
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
    _gameFramer.reset();
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
