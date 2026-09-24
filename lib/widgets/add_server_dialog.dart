// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/server_mgr.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key, this.initial, this.others = const []});
  final ServerEntry? initial;

  final List<ServerEntry> others;
  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _duplicate = false;
  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _localIpCtrl = TextEditingController();
  final _registryPortCtrl = TextEditingController(
    text: '${ServerEntry.defaultRegistryPort}',
  );
  final _httpPortCtrl = TextEditingController(
    text: '${ServerEntry.defaultHttpPort}',
  );

  static final RegExp _ipv4 = RegExp(
    r'^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$',
  );

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _nameCtrl.text = widget.initial!.name;
      _ipCtrl.text = widget.initial!.ip;
      _localIpCtrl.text = widget.initial!.localIp ?? '';
      _registryPortCtrl.text = '${widget.initial!.registryPort}';
      _httpPortCtrl.text = '${widget.initial!.httpPort}';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _localIpCtrl.dispose();
    _registryPortCtrl.dispose();
    _httpPortCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final entry = ServerEntry(
        name: _nameCtrl.text.trim(),
        ip: _ipCtrl.text.trim(),
        localIp: _localIpCtrl.text.trim().isEmpty
            ? null
            : _localIpCtrl.text.trim(),
        registryPort: int.parse(_registryPortCtrl.text),
        httpPort: int.parse(_httpPortCtrl.text),
      );
      if (widget.others.any(entry.sameServerAs)) {
        setState(() => _duplicate = true);
        return;
      }
      Navigator.of(context).pop(entry);
    }
  }

  Widget _portField(TextEditingController ctrl, String label) => TextFormField(
    controller: ctrl,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (v) {
      final port = int.tryParse(v ?? '');
      if (port == null || port < 1 || port > 65535) return '1 to 65535';
      return null;
    },
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit server' : 'Add server'),
      content: Form(
        key: _formKey,
        onChanged: () {
          if (_duplicate) setState(() => _duplicate = false);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: _ipCtrl,
              decoration: const InputDecoration(labelText: 'Server IPv4'),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Enter an IP';
                if (!_ipv4.hasMatch(t)) return 'Invalid IPv4';
                return null;
              },
            ),
            TextFormField(
              controller: _localIpCtrl,
              decoration: const InputDecoration(
                labelText: 'Local IPv4 (optional)',
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                if (!_ipv4.hasMatch(t)) return 'Invalid IPv4';
                return null;
              },
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _portField(_registryPortCtrl, 'Registry port')),
                const SizedBox(width: 16),
                Expanded(child: _portField(_httpPortCtrl, 'HTTP port')),
              ],
            ),
            if (_duplicate)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'A server with this IP and these ports already exists',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(isEdit ? 'Save' : 'Add')),
      ],
    );
  }
}
