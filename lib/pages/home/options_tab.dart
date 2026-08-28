// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import '../../utils/scheme_dumper.dart';
import '../logs_page.dart';

class OptionsTab extends StatelessWidget {
  const OptionsTab({
    super.key,
    required this.floatingDpadEnabled,
    required this.preserveDpadDragEnabled,
    required this.smartWidescreenEnabled,
    required this.dumpSchemesEnabled,
    required this.capabilitiesOverride,
    required this.connectionTimeoutSeconds,
    required this.onFloatingDpadChanged,
    required this.onPreserveDpadDragChanged,
    required this.onSmartWidescreenChanged,
    required this.onDumpSchemesChanged,
    required this.onCapabilitiesOverrideChanged,
    required this.onConnectionTimeoutChanged,
  });

  final bool floatingDpadEnabled;
  final bool preserveDpadDragEnabled;
  final bool smartWidescreenEnabled;
  final bool dumpSchemesEnabled;
  final int? capabilitiesOverride;
  final int connectionTimeoutSeconds;
  final ValueChanged<bool> onFloatingDpadChanged;
  final ValueChanged<bool> onPreserveDpadDragChanged;
  final ValueChanged<bool> onSmartWidescreenChanged;
  final ValueChanged<bool> onDumpSchemesChanged;
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
        SwitchListTile(
          title: const Text(
            'Save Control Schemes',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: dumpSchemesEnabled
              ? _DumpLocation()
              : const Text(
                  'Write each game\'s control scheme to storage',
                  style: TextStyle(color: Colors.grey),
                ),
          value: dumpSchemesEnabled,
          onChanged: (v) async {
            if (v && !await _confirmDumpSchemes(context)) return;
            onDumpSchemesChanged(v);
          },
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
        const ClearSchemesTile(),
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

  Future<bool> _confirmDumpSchemes(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save control schemes?'),
        content: const Text(
          'Every control scheme a game sends will be written to app storage, '
          'including its artwork. A single scheme can be several megabytes, '
          'and the files stay until you delete them.\n\n'
          'This is a developer tool! Recommended to leave off for normal play.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save them'),
          ),
        ],
      ),
    );
    return ok ?? false;
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

class _DumpLocation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SchemeDumper.instance.location(),
      builder: (context, snap) => Text(
        snap.data ?? 'Writing schemes to storage',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}

/// Offers to throw away saved schemes, and stays out of the way when there is
/// nothing to throw away.
class ClearSchemesTile extends StatefulWidget {
  const ClearSchemesTile({super.key});

  @override
  State<ClearSchemesTile> createState() => _ClearSchemesTileState();
}

class _ClearSchemesTileState extends State<ClearSchemesTile> {
  ({int files, int bytes})? _saved;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final saved = await SchemeDumper.instance.summary();
    if (mounted) setState(() => _saved = saved);
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    if (saved == null || saved.files == 0) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: Colors.white),
      title: const Text(
        'Clear Saved Schemes',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        '${saved.files} ${saved.files == 1 ? 'file' : 'files'}, '
        '${_size(saved.bytes)}',
        style: const TextStyle(color: Colors.grey),
      ),
      onTap: () => _confirm(saved),
    );
  }

  Future<void> _confirm(({int files, int bytes}) saved) async {
    final where = await SchemeDumper.instance.location();
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved schemes?'),
        content: Text(
          'This deletes ${saved.files} scheme '
          '${saved.files == 1 ? 'file' : 'files'} (${_size(saved.bytes)}) from:'
          '\n\n$where\n\n'
          'Only files this app saved are removed, and anything else in that '
          'folder is left alone. Copy them off the device first if you still '
          'need them, because this cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep them'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete ${saved.files}'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final removed = await SchemeDumper.instance.clear();
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $removed scheme ${removed == 1 ? 'file' : 'files'}',
        ),
      ),
    );
  }

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} kB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
