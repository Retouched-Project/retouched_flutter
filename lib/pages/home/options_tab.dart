// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import '../logs_page.dart';

class OptionsTab extends StatelessWidget {
  const OptionsTab({
    super.key,
    required this.floatingDpadEnabled,
    required this.preserveDpadDragEnabled,
    required this.smartWidescreenEnabled,
    required this.capabilitiesOverride,
    required this.connectionTimeoutSeconds,
    required this.onFloatingDpadChanged,
    required this.onPreserveDpadDragChanged,
    required this.onSmartWidescreenChanged,
    required this.onCapabilitiesOverrideChanged,
    required this.onConnectionTimeoutChanged,
  });

  final bool floatingDpadEnabled;
  final bool preserveDpadDragEnabled;
  final bool smartWidescreenEnabled;
  final int? capabilitiesOverride;
  final int connectionTimeoutSeconds;
  final ValueChanged<bool> onFloatingDpadChanged;
  final ValueChanged<bool> onPreserveDpadDragChanged;
  final ValueChanged<bool> onSmartWidescreenChanged;
  final ValueChanged<int?> onCapabilitiesOverrideChanged;
  final ValueChanged<int> onConnectionTimeoutChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text(
            'Floating D-Pad',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Allow D-Pad to move when dragging outside center',
            style: TextStyle(color: Colors.grey),
          ),
          value: floatingDpadEnabled,
          onChanged: onFloatingDpadChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
        SwitchListTile(
          title: const Text(
            'Persistent D-Pad Drag',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Remember D-Pad drag position across layout changes',
            style: TextStyle(color: Colors.grey),
          ),
          value: preserveDpadDragEnabled,
          onChanged: onPreserveDpadDragChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
        SwitchListTile(
          title: const Text(
            'Force Widescreen (D-Pad Layouts Only)',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Stretches D-Pad layouts to fill widescreen',
            style: TextStyle(color: Colors.grey),
          ),
          value: smartWidescreenEnabled,
          onChanged: onSmartWidescreenChanged,
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
        ListTile(
          title: const Text(
            'Sensor Capabilities Override',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            capabilitiesOverride == null
                ? 'Auto-detect (Default)'
                : 'Manual Mask: $capabilitiesOverride (0x${capabilitiesOverride!.toRadixString(16)})',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: capabilitiesOverride != null
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () => onCapabilitiesOverrideChanged(null),
                )
              : null,
          onTap: () => _showCapabilitiesDialog(context),
        ),
        ListTile(
          title: const Text(
            'Connection Timeout',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '$connectionTimeoutSeconds seconds',
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: () => _showConnectionTimeoutDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined, color: Colors.white),
          title: const Text('Logs', style: TextStyle(color: Colors.white)),
          subtitle: const Text(
            'View app and engine logs',
            style: TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LogsPage())),
        ),
      ],
    );
  }

  Future<void> _showConnectionTimeoutDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: connectionTimeoutSeconds.toString(),
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connection timeout'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Seconds',
                helperText: 'How long to wait for the server (1-120)',
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 1 || n > 120) {
                  return 'Enter a number between 1 and 120';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(int.parse(controller.text.trim()));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null && context.mounted) {
      onConnectionTimeoutChanged(result);
    }
  }

  Future<void> _showCapabilitiesDialog(BuildContext context) async {
    int? mask = capabilitiesOverride ?? 0;
    bool gyro = (mask & 1) != 0;
    bool rotVec = (mask & 2) != 0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Override Sensor Capabilities'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Gyroscope'),
                    value: gyro,
                    onChanged: (v) => setState(() => gyro = v!),
                  ),
                  CheckboxListTile(
                    title: const Text('Rotation'),
                    value: rotVec,
                    onChanged: (v) => setState(() => rotVec = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    int newMask = 0;
                    if (gyro) newMask |= 1;
                    if (rotVec) newMask |= 2;
                    Navigator.of(context).pop(newMask);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((val) {
      if (val != null && val is int) {
        onCapabilitiesOverrideChanged(val);
      }
    });
  }
}
