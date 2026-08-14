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
    final sniffer = _gamePolicySniffer;
    if (!sniffer.isWatching) return data;

    final sniff = sniffer.feed(data);
    switch (sniff.kind) {
      case PolicySniffKind.wait:
        return null;
      case PolicySniffKind.passthrough:
        return sniff.data;
      case PolicySniffKind.answer:
        _answerPolicyRequest();
        return null;
    }
  }

  void _answerPolicyRequest() {
    _gameFramer.reset();
    _gameHandshakerInst?.reset();
    final socket = _gameSocket;
    if (socket == null) return;
    socket.add(_lib.policyResponse);
    socket
        .flush()
        .catchError((_) {})
        .then((_) => socket.close().catchError((_) {}));
  }
}
