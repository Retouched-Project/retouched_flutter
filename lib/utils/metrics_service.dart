// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:io';

class MetricsService {
  static const int sessionStart = 1685287796;
  static const int sessionEnd = 1685284196;

  static void send({
    required int type,
    required String appId,
    required String serverIp,
    required int httpPort,
    required String deviceId,
  }) {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final events = Uri.encodeComponent(
      '[{"type":$type,"time":$epoch,"appId":"$appId","deviceId":"$deviceId","data":""}]',
    );
    final body =
        'action=logEvents&events=$events&token=${Uri.encodeComponent(deviceId)}';
    final url = Uri.parse('http://$serverIp:$httpPort/bmregistry/metrics');
    HttpClient()
        .postUrl(url)
        .then((req) {
          req.headers.contentType = ContentType(
            'application',
            'x-www-form-urlencoded',
          );
          req.write(body);
          return req.close();
        })
        .then((resp) => resp.drain<void>())
        .catchError((_) {});
  }
}
