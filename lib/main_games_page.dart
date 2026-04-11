// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'server_mgr.dart';
import 'game_client.dart';
import 'bmlib/bm_lib.dart';
import 'game_session_page.dart';

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ServerManager _serverMgr = ServerManager();
  GameClient? _client;
  Object? _error;
  late TabController _tabController;
  bool _floatingDpadEnabled = true;
  bool _preserveDpadDragEnabled = false;
  int? _capabilitiesOverride;
  bool _smartWidescreenEnabled = false;
  int _connectionTimeoutSeconds = 5;
  ServerEntry? _lastServer;
  bool _inSession = false;
  bool _pendingServerDisconnect = false;
  StreamSubscription<void>? _disconnSub;
  Future<void>? _closingStaleClient;
  String? _connectingIp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _tabController = TabController(length: 4, vsync: this);
    _serverMgr.load();
    _loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _client == null &&
        _lastServer != null) {
      _connectToServer(_lastServer!);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _floatingDpadEnabled = prefs.getBool('floatingDpad') ?? true;
      _preserveDpadDragEnabled = prefs.getBool('preserveDpadDrag') ?? false;
      if (prefs.containsKey('capabilitiesOverride')) {
        _capabilitiesOverride = prefs.getInt('capabilitiesOverride');
      }
      _smartWidescreenEnabled = prefs.getBool('smartWidescreen') ?? false;
      _connectionTimeoutSeconds = prefs.getInt('connectionTimeoutSeconds') ?? 5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('floatingDpad', _floatingDpadEnabled);
    await prefs.setBool('preserveDpadDrag', _preserveDpadDragEnabled);
    if (_capabilitiesOverride != null) {
      await prefs.setInt('capabilitiesOverride', _capabilitiesOverride!);
    } else {
      await prefs.remove('capabilitiesOverride');
    }
    await prefs.setBool('smartWidescreen', _smartWidescreenEnabled);
    await prefs.setInt('connectionTimeoutSeconds', _connectionTimeoutSeconds);
  }

  Future<void> _connectToServer(ServerEntry server) async {
    if (_connectingIp != null) return;

    final physicalSize = View.of(context).physicalSize;

    await _disconnSub?.cancel();
    _disconnSub = null;
    _pendingServerDisconnect = false;
    if (_closingStaleClient != null) {
      await _closingStaleClient;
      _closingStaleClient = null;
    }
    final previousClient = _client;
    if (previousClient != null) {
      if (mounted) {
        setState(() {
          _client = null;
        });
      }
      await previousClient.close();
    }
    if (!mounted) return;

    _lastServer = server;

    final newClient = GameClient(server);
    newClient.setScreenSize(
      physicalSize.width.toInt(),
      physicalSize.height.toInt(),
    );
    newClient.setCapabilitiesOverride(_capabilitiesOverride);

    setState(() {
      _connectingIp = server.ip;
      _error = null;
    });

    try {
      await newClient.connect(
        timeout: Duration(seconds: _connectionTimeoutSeconds),
      );
      if (!mounted) {
        await newClient.close();
        return;
      }
      setState(() {
        _client = newClient;
        _connectingIp = null;
      });
      _disconnSub = newClient.disconnectedStream.listen((_) {
        if (!mounted) return;
        if (_inSession) {
          _pendingServerDisconnect = true;
          return;
        }
        final staleClient = _client;
        final staleSub = _disconnSub;
        _disconnSub = null;
        setState(() {
          _client = null;
          _error = 'Connection to server lost';
        });
        _closingStaleClient = () async {
          try {
            await staleSub?.cancel();
            await staleClient?.close();
          } catch (_) {}
        }();
      });
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _client = null;
        _connectingIp = null;
      });
    }
  }

  Future<void> _disconnectFromServer() async {
    _disconnSub?.cancel();
    _disconnSub = null;
    await _client?.close();
    if (mounted) {
      setState(() {
        _client = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnSub?.cancel();
    _client?.close();
    _serverMgr.dispose();
    _tabController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _client?.close();
        if (context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          shadowColor: Colors.black45,
          centerTitle: true,
          title: SvgPicture.asset(
            'assets/retouched_logo_text.svg',
            height: 36,
            semanticsLabel: 'Logo',
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2196F3),
            indicatorWeight: 3.0,
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
            tabs: const [
              Tab(text: 'SERVERS'),
              Tab(text: 'GAMES'),
              Tab(text: 'OPTIONS'),
              Tab(text: 'ABOUT'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildServersTab(),
              _buildGamesTab(),
              _buildOptionsTab(),
              _buildAboutTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServersTab() {
    return AnimatedBuilder(
      animation: _serverMgr,
      builder: (context, _) {
        final servers = _serverMgr.servers;
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
                  final isConnected = _client?.server.ip == s.ip;
                  final isConnecting = _connectingIp == s.ip;
                  final busy = _connectingIp != null;
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
                    onTap: busy ? null : () => _connectToServer(s),
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
                            onPressed: busy
                                ? null
                                : () => _disconnectFromServer(),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: busy
                                ? null
                                : () => _editServer(index, s),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: busy
                              ? null
                              : () => _serverMgr.removeAt(index),
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
              _buildErrorBanner(),
              Expanded(child: listView),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddServerDialog,
            tooltip: 'Add server',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _badgedIcon(String mainAsset, {required bool positive}) {
    return SizedBox(
      width: 122,
      height: 122,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: 110,
            height: 110,
            child: SvgPicture.asset(mainAsset),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: 72,
            height: 72,
            child: SvgPicture.asset(
              positive ? 'assets/checkmark.svg' : 'assets/cross.svg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBackgroundIcons({
    required bool connected,
    required bool hasGames,
  }) {
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _badgedIcon('assets/server.svg', positive: connected),
              const SizedBox(height: 16),
              _badgedIcon('assets/host.svg', positive: hasGames),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    if (_error == null) return const SizedBox.shrink();
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
                  _formatConnectionError(_error!),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              if (_lastServer != null && _connectingIp == null)
                TextButton(
                  onPressed: () => _connectToServer(_lastServer!),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('RETRY'),
                ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                tooltip: 'Dismiss',
                onPressed: () => setState(() => _error = null),
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

  Future<void> _editServer(int index, ServerEntry server) async {
    final ServerEntry? edited = await showDialog<ServerEntry>(
      context: context,
      builder: (context) => AddServerDialog(initial: server),
    );
    if (edited != null) {
      await _serverMgr.replaceAt(index, edited);
    }
  }

  Future<void> _openAddServerDialog() async {
    final ServerEntry? added = await showDialog<ServerEntry>(
      context: context,
      builder: (context) => const AddServerDialog(),
    );
    if (added != null) {
      await _serverMgr.add(added);
    }
  }

  Widget _buildGamesTab() {
    if (_client == null) {
      return _buildStackedBackgroundIcons(connected: false, hasGames: false);
    }

    return StreamBuilder<List<String>>(
      stream: _client!.gamesStream,
      initialData: const <String>[],
      builder: (context, snap) {
        final games = _client!.gameInfos;
        final background = Positioned.fill(
          child: _buildStackedBackgroundIcons(
            connected: true,
            hasGames: games.isNotEmpty,
          ),
        );
        if (games.isEmpty) {
          return _buildStackedBackgroundIcons(connected: true, hasGames: false);
        }
        return Stack(
          children: [
            background,
            ListView.separated(
              itemCount: games.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final game = games[i];
                final iconUrl =
                    'http://${_client!.server.ip}:8080/apps/icons/${game.appId}.png';
                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: Image.network(
                      iconUrl,
                      errorBuilder: (context, error, stackTrace) {
                        return SvgPicture.asset(
                          'assets/retouched_logo.svg',
                          fit: BoxFit.contain,
                        );
                      },
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(
                    game.deviceName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _slotIndicator(game),
                  onTap: () async {
                    if (_inSession) return;
                    if (game.maxPlayers > 0 &&
                        game.currentPlayers >= game.maxPlayers) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Game is full')),
                      );
                      return;
                    }
                    _inSession = true;
                    await _client!.disconnectGame();
                    await _client!.connectToGame(game);
                    if (context.mounted) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GameSessionPage(
                            client: _client!,
                            floatingDpadEnabled: _floatingDpadEnabled,
                            smartWidescreenEnabled: _smartWidescreenEnabled,
                            preserveDpadDragEnabled: _preserveDpadDragEnabled,
                          ),
                        ),
                      );
                    }
                    _inSession = false;
                    if (_pendingServerDisconnect && mounted) {
                      _pendingServerDisconnect = false;
                      await _disconnSub?.cancel();
                      _disconnSub = null;
                      final staleClient = _client;
                      setState(() {
                        _client = null;
                        _error = 'Connection to server lost';
                      });
                      await staleClient?.close();
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/retouched_logo_text_flutter.svg',
              height: 60,
            ),
            const SizedBox(height: 20),
            const Text(
              'Retouched Flutter',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
            ),
            const SizedBox(height: 40),
            const Text(
              'Copyright (C) 2026\nddavef/KinteLiX',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsTab() {
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
          value: _floatingDpadEnabled,
          onChanged: (v) {
            setState(() => _floatingDpadEnabled = v);
            _saveSettings();
          },
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
          value: _preserveDpadDragEnabled,
          onChanged: (v) {
            setState(() => _preserveDpadDragEnabled = v);
            _saveSettings();
          },
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
          value: _smartWidescreenEnabled,
          onChanged: (v) {
            setState(() => _smartWidescreenEnabled = v);
            _saveSettings();
          },
          activeThumbColor: Theme.of(context).colorScheme.primary,
        ),
        ListTile(
          title: const Text(
            'Sensor Capabilities Override',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _capabilitiesOverride == null
                ? 'Auto-detect (Default)'
                : 'Manual Mask: $_capabilitiesOverride (0x${_capabilitiesOverride!.toRadixString(16)})',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: _capabilitiesOverride != null
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    setState(() => _capabilitiesOverride = null);
                    _saveSettings();
                    if (_client != null) _client!.setCapabilitiesOverride(null);
                  },
                )
              : null,
          onTap: _showCapabilitiesDialog,
        ),
        ListTile(
          title: const Text(
            'Connection Timeout',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '$_connectionTimeoutSeconds seconds',
            style: const TextStyle(color: Colors.grey),
          ),
          onTap: _showConnectionTimeoutDialog,
        ),
      ],
    );
  }

  Future<void> _showConnectionTimeoutDialog() async {
    final controller = TextEditingController(
      text: _connectionTimeoutSeconds.toString(),
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
    if (result != null && mounted) {
      setState(() => _connectionTimeoutSeconds = result);
      _saveSettings();
    }
  }

  Future<void> _showCapabilitiesDialog() async {
    int? mask = _capabilitiesOverride ?? 0;
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
        setState(() => _capabilitiesOverride = val);
        _saveSettings();
        if (_client != null) _client!.setCapabilitiesOverride(val);
      }
    });
  }

  Widget _slotIndicator(BmRegistryInfo game) {
    final color = _slotColor(game.slotId);
    final hexColor =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return FutureBuilder<String>(
      future: rootBundle.loadString('assets/slotwifi.svg'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(width: 48, height: 48);
        }
        final svgString = snapshot.data!.replaceFirstMapped(
          RegExp(r'<rect([^>]*?)id="box"([^>]*)>'),
          (Match m) {
            final fullRect = m.group(0)!;
            return fullRect.replaceFirstMapped(RegExp(r'style="([^"]*)"'), (
              Match sm,
            ) {
              String style = sm.group(1) ?? '';
              style = style.replaceAll(RegExp(r'fill:[^;]+;?'), '');
              style = style.replaceAll(RegExp(r'fill-opacity:[^;]+;?'), '');
              return 'style="fill:$hexColor;fill-opacity:1;$style"';
            });
          },
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: SvgPicture.string(svgString),
            ),
            const SizedBox(width: 8),
            Text(
              '${game.currentPlayers}/${game.maxPlayers}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  Color _slotColor(int slotId) {
    switch (slotId) {
      case 1:
        return const Color(0xFFFF6900);
      case 2:
        return const Color(0xFFFED000);
      case 3:
        return const Color(0xFFFF2C9B);
      case 4:
        return const Color(0xFFFF0066);
      case 5:
        return const Color(0xFFD500FF);
      case 6:
        return const Color(0xFF969C00);
      case 7:
        return const Color(0xFF9B96CE);
      case 8:
        return const Color(0xFF00CD97);
      case 9:
        return const Color(0xFF009B00);
      case 10:
        return const Color(0xFF00C9FF);
      case 11:
        return const Color(0xFF112F68);
      case 12:
        return const Color(0xFF8AFF00);
      case 13:
        return const Color(0xFFD01300);
      case 14:
        return const Color(0xFF76D061);
      case 15:
        return const Color(0xFF7400FF);
      default:
        return const Color(0xFF666666);
    }
  }
}

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
