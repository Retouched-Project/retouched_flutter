// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../server_mgr.dart';
import '../game_client/game_client.dart';
import '../bmlib/bm_lib.dart';
import 'game_session_page.dart';
import 'home/servers_tab.dart';
import 'home/games_tab.dart';
import 'home/options_tab.dart';
import 'home/about_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
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

  Future<void> _launchGame(BmRegistryInfo game) async {
    if (_inSession) return;
    if ((game.maxPlayers ?? 0) > 0 &&
        (game.currentPlayers ?? 0) >= (game.maxPlayers ?? 0)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Game is full')));
      return;
    }
    _inSession = true;
    await _client!.disconnectGame();
    await _client!.connectToGame(game);
    if (mounted) {
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
              ServersTab(
                serverMgr: _serverMgr,
                client: _client,
                connectingIp: _connectingIp,
                error: _error,
                lastServer: _lastServer,
                onConnect: _connectToServer,
                onDisconnect: _disconnectFromServer,
                onDismissError: () => setState(() => _error = null),
              ),
              GamesTab(client: _client, onLaunchGame: _launchGame),
              OptionsTab(
                floatingDpadEnabled: _floatingDpadEnabled,
                preserveDpadDragEnabled: _preserveDpadDragEnabled,
                smartWidescreenEnabled: _smartWidescreenEnabled,
                capabilitiesOverride: _capabilitiesOverride,
                connectionTimeoutSeconds: _connectionTimeoutSeconds,
                onFloatingDpadChanged: (v) {
                  setState(() => _floatingDpadEnabled = v);
                  _saveSettings();
                },
                onPreserveDpadDragChanged: (v) {
                  setState(() => _preserveDpadDragEnabled = v);
                  _saveSettings();
                },
                onSmartWidescreenChanged: (v) {
                  setState(() => _smartWidescreenEnabled = v);
                  _saveSettings();
                },
                onCapabilitiesOverrideChanged: (v) {
                  setState(() => _capabilitiesOverride = v);
                  _saveSettings();
                  if (_client != null) _client!.setCapabilitiesOverride(v);
                },
                onConnectionTimeoutChanged: (v) {
                  setState(() => _connectionTimeoutSeconds = v);
                  _saveSettings();
                },
              ),
              const AboutTab(),
            ],
          ),
        ),
      ),
    );
  }
}
