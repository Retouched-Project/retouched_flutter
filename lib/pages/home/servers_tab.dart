// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import '../../server_mgr.dart';
import '../../game_client/game_client.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/add_server_dialog.dart';

class ServersTab extends StatelessWidget {
  const ServersTab({
    super.key,
    required this.serverMgr,
    required this.client,
    required this.connectingIp,
    required this.error,
    required this.lastServer,
    required this.onConnect,
    required this.onDisconnect,
    required this.onDismissError,
  });

  final ServerManager serverMgr;
  final GameClient? client;
  final String? connectingIp;
  final Object? error;
  final ServerEntry? lastServer;
  final void Function(ServerEntry server) onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: serverMgr,
      builder: (context, _) {
        final servers = serverMgr.servers;
        final listView = servers.isEmpty
            ? const Center(
                child: Text(
                  'No servers yet. Tap the + button to add one.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.separated(
                itemCount: servers.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Colors.white24),
                itemBuilder: (context, index) {
                  final s = servers[index];
                  final isConnected = client?.server.ip == s.ip;
                  final isConnecting = connectingIp == s.ip;
                  final busy = connectingIp != null;
                  return ListTile(
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    leading: isConnecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : isConnected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.dns),
                    title: Text(s.name),
                    subtitle: Text(
                      s.ip,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: busy ? null : () => onConnect(s),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isConnected)
                          IconButton(
                            icon: const Icon(
                              Icons.power_settings_new,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Disconnect',
                            onPressed: busy ? null : () => onDisconnect(),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: busy
                                ? null
                                : () => _editServer(context, index, s),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: busy
                              ? null
                              : () => serverMgr.removeAt(index),
                        ),
                      ],
                    ),
                  );
                },
              );
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              ErrorBanner(
                error: error,
                onDismiss: onDismissError,
                onRetry: (lastServer != null && connectingIp == null)
                    ? () => onConnect(lastServer!)
                    : null,
              ),
              Expanded(child: listView),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddServerDialog(context),
            tooltip: 'Add server',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _editServer(
    BuildContext context,
    int index,
    ServerEntry server,
  ) async {
    final ServerEntry? edited = await showDialog<ServerEntry>(
      context: context,
      builder: (context) => AddServerDialog(initial: server),
    );
    if (edited != null) {
      await serverMgr.replaceAt(index, edited);
    }
  }

  Future<void> _openAddServerDialog(BuildContext context) async {
    final ServerEntry? added = await showDialog<ServerEntry>(
      context: context,
      builder: (context) => const AddServerDialog(),
    );
    if (added != null) {
      await serverMgr.add(added);
    }
  }
}
