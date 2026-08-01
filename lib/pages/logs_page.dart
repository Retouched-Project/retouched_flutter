// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../utils/app_logger.dart';
import '../utils/log_store.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scroll = ScrollController();
  Level _level = logLevel;
  bool _stickToBottom = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // Follow the tail only while the reader is already there, so scrolling back
    // to look at something is not undone by the next batch.
    final position = _scroll.position;
    _stickToBottom = position.maxScrollExtent - position.pixels < 40;
  }

  static const Map<String, Color> _colors = {
    'Error': Color(0xFFFF5555),
    'Warn': Color(0xFFFFCC00),
    'Info': Color(0xFF5FD75F),
    'Debug': Color(0xFF5F9FFF),
    'Trace': Color(0xFF5FD7D7),
  };

  void _copyAll() {
    final text = LogStore.instance.entries
        .map((e) => '[${e.level}] ${e.source}: ${e.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        actions: [
          PopupMenuButton<Level>(
            tooltip: 'Log level',
            initialValue: _level,
            onSelected: (v) {
              setState(() => _level = v);
              setLogLevel(v);
            },
            itemBuilder: (context) => [
              for (final l in selectorLevels)
                PopupMenuItem(value: l, child: Text(levelLabel(l))),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(levelLabel(_level)),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all',
            onPressed: _copyAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: LogStore.instance.clear,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: LogStore.instance,
        builder: (context, _) {
          final entries = LogStore.instance.entries;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_stickToBottom && _scroll.hasClients) {
              _scroll.jumpTo(_scroll.position.maxScrollExtent);
            }
          });
          if (entries.isEmpty) {
            return const Center(child: Text('No logs yet'));
          }
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];
              return SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '[${e.level}] ',
                      style: TextStyle(
                        color: _colors[e.level] ?? Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '${e.source}: ',
                      style: const TextStyle(color: Colors.white38),
                    ),
                    TextSpan(text: e.message),
                  ],
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              );
            },
          );
        },
      ),
    );
  }
}
