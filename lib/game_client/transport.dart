// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

part of 'game_client.dart';

extension GameClientTransport on GameClient {
  /// The payload is ready to write, so this only has to pick a path.
  void _sendOutgoings(List<BmOutgoing> outgoings) {
    for (final outgoing in outgoings) {
      if (outgoing.via.datagram) {
        _sendUdp(outgoing.payload, outgoing.via);
      } else {
        _resolveSocket(outgoing.targetDeviceId)?.add(outgoing.payload);
      }
    }
  }

  /// The engine has already decided these bytes go by datagram, so anything
  /// stopping that is worth saying. Input is frequent, so it is said once.
  void _sendUdp(Uint8List payload, BmVia via) {
    if (_udpSocket == null) {
      _warnUdpOnce('there is no socket to send from');
      return;
    }
    if (via.address.isEmpty) {
      _warnUdpOnce('nothing has observed where this game is');
      return;
    }
    final target = InternetAddress.tryParse(via.address);
    if (target == null) {
      _warnUdpOnce('"${via.address}" is not an address we can send to');
      return;
    }
    final sent = _udpSocket!.send(payload, target, via.port);
    if (sent == 0) {
      _warnUdpOnce('the socket accepted no bytes for ${via.address}');
      return;
    }
    if (!_udpConfirmed) {
      _udpConfirmed = true;
      _log.info('Datagrams are reaching ${via.address}:${via.port}');
    }
  }

  /// Wakes the engine when it said it had something owed. Rearming for a
  /// moment already pending is skipped, so a stream of input does not rebuild
  /// the timer on every event.
  void _armEngineTimer(int? dueAt) {
    if (dueAt == null) {
      _engineTimer?.cancel();
      _engineTimer = null;
      _engineTimerDueAt = null;
      return;
    }
    if (_engineTimer != null && _engineTimerDueAt == dueAt) return;

    final delay = dueAt - DateTime.now().millisecondsSinceEpoch;
    _engineTimer?.cancel();
    _engineTimerDueAt = dueAt;
    _engineTimer = Timer(Duration(milliseconds: delay < 0 ? 0 : delay), () {
      _engineTimer = null;
      _engineTimerDueAt = null;
      final engine = _engine;
      if (engine == null) return;
      final out = _lib.handleTime(
        engine,
        DateTime.now().millisecondsSinceEpoch,
      );
      _sendOutgoings(out.outgoings);
      _armEngineTimer(out.nextTimeMs);
    });
  }

  void _stopEngineTimer() {
    _engineTimer?.cancel();
    _engineTimer = null;
    _engineTimerDueAt = null;
  }

  /// Releases what the engine held for a peer. Its outgoings are the notices
  /// a registry owes anyone still watching, so they still have to be written.
  void _tellEnginePeerGone(String deviceId) {
    final engine = _engine;
    if (engine == null || deviceId.isEmpty) return;
    _sendOutgoings(
      _lib.emit(engine, {'type': 'PeerGone', 'device_id': deviceId}).outgoings,
    );
  }

  void _warnUdpOnce(String why) {
    if (_udpWarned) return;
    _udpWarned = true;
    _log.warning('Cannot send a datagram: $why');
  }

  Socket? _resolveSocket(String targetDeviceId) {
    if (targetDeviceId == serverDeviceId) return _socket;
    if (_activeGame != null && targetDeviceId == _activeGame!.deviceId) {
      return _gameSocket ?? _socket;
    }
    return null;
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
