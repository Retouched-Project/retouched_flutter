// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import '../utils/server_mgr.dart';

class AddServerDialog extends StatefulWidget {
  const AddServerDialog({super.key, this.initial});
  final ServerEntry? initial;
  @override
  State<AddServerDialog> createState() => _AddServerDialogState();
}

class _AddServerDialogState extends State<AddServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _localIpCtrl = TextEditingController();

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
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _localIpCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(
        ServerEntry(
          name: _nameCtrl.text.trim(),
          ip: _ipCtrl.text.trim(),
          localIp: _localIpCtrl.text.trim().isEmpty
              ? null
              : _localIpCtrl.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit server' : 'Add server'),
      content: Form(
        key: _formKey,
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
