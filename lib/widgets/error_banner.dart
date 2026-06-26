// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
    this.onRetry,
  });

  final Object? error;
  final VoidCallback onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF5C1F1F),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatConnectionError(error!),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('RETRY'),
                ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                tooltip: 'Dismiss',
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatConnectionError(Object error) {
    if (error is TimeoutException) {
      return 'Server did not respond. Check that it is running and reachable.';
    }
    if (error is SocketException) {
      final msg = error.osError?.message ?? error.message;
      return msg.isEmpty
          ? 'Could not reach server.'
          : 'Could not reach server: $msg';
    }
    return error.toString();
  }
}
