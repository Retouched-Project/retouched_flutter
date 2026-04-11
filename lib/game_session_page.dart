// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'game_client.dart';
import 'bmrender/controls/scheme.pb.dart';
import 'bmrender/controls/scheme_extensions.dart';
import 'bmrender/controls/control_orientation.dart';
import 'bmrender/bm_render_view.dart';
import 'loading_logo.dart';
import 'bmrender/unlock_slider.dart';

const _menuIcons = <int, String>{
  0: 'assets/retouched_logo.svg',
  1: 'assets/menu_reset.svg',
  2: 'assets/menu_help.svg',
  3: 'assets/menu_sound_on.svg',
  4: 'assets/menu_sound_off.svg',
  5: 'assets/menu_music.svg',
  6: 'assets/menu_music_off.svg',
};

class GameSessionPage extends StatefulWidget {
  final GameClient client;
  final ControlScheme? initialScheme;
  final bool floatingDpadEnabled;
  final bool smartWidescreenEnabled;
  final bool preserveDpadDragEnabled;

  const GameSessionPage({
    super.key,
    required this.client,
    this.initialScheme,
    this.floatingDpadEnabled = true,
    this.smartWidescreenEnabled = false,
    this.preserveDpadDragEnabled = false,
  });

  @override
  State<GameSessionPage> createState() => _GameSessionPageState();
}

class _GameSessionPageState extends State<GameSessionPage>
    with WidgetsBindingObserver {
  ControlScheme? _currentScheme;
  bool _loading = true;
  StreamSubscription? _schemeSub;
  bool _popping = false;
  final GlobalKey<UnlockSliderState> _sliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _currentScheme = widget.initialScheme;
    if (_currentScheme != null) {
      _loading = false;
      _applyOrientation(_currentScheme!.getRotation());
    }
    _schemeSub = widget.client.schemeStream.listen(_onScheme);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _disconnectAndPop();
    }
  }

  void _onScheme(ControlScheme? scheme) {
    if (!mounted || _popping) return;
    if (scheme != null) {
      setState(() {
        _currentScheme = scheme;
        _loading = false;
        _applyOrientation(scheme.getRotation());
      });
    } else {
      _disconnectAndPop();
    }
  }

  Future<void> _disconnectAndPop() async {
    if (_popping) return;
    _popping = true;
    widget.client.sendResume();
    await widget.client.disconnectGame();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _applyOrientation(ControlOrientation? orientation) {
    if (orientation == ControlOrientation.landscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else if (orientation == ControlOrientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _schemeSub?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _showPauseMenu() async {
    if (_currentScheme == null) return;
    widget.client.sendPause();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) {
          return StreamBuilder<ControlScheme?>(
            stream: widget.client.schemeStream,
            initialData: _currentScheme,
            builder: (context, snapshot) {
              final scheme = snapshot.data ?? _currentScheme;
              if (scheme == null) {
                return const SizedBox.shrink();
              }
              final options = scheme.getOptions();
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80000000),
                          blurRadius: 32,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: options.length + 1,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0x14FFFFFF),
                        ),
                        itemBuilder: (context, index) {
                          if (index < options.length) {
                            final opt = options[index];
                            final iconAsset =
                                _menuIcons[opt.getIconResId()] ??
                                _menuIcons[0]!;
                            return InkWell(
                              onTap: () {
                                if (opt.getEvent().isNotEmpty) {
                                  widget.client.sendMenuEvent(opt.getEvent());
                                }
                                if (opt.isCloseOnSelect()) {
                                  Navigator.of(dialogCtx).pop();
                                }
                              },
                              highlightColor: const Color(0x1AFFFFFF),
                              splashColor: const Color(0x14FFFFFF),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      iconAsset,
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      opt.getTitle(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return InkWell(
                            onTap: () {
                              Navigator.of(dialogCtx).pop();
                              _disconnectAndPop();
                            },
                            highlightColor: const Color(0x26FF6B6B),
                            splashColor: const Color(0x1AFF6B6B),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/menu_disconnect.svg',
                                    width: 24,
                                    height: 24,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFFF6B6B),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Disconnect',
                                    style: TextStyle(
                                      color: Color(0xFFFF6B6B),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      widget.client.sendResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _sliderKey.currentState?.nudge();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading || _currentScheme == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: StreamBuilder<double>(
            stream: widget.client.progressStream,
            initialData: 0.0,
            builder: (context, snap) {
              final p = snap.data ?? 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingLogo(progress: p),
                  const SizedBox(height: 24),
                  const Text(
                    'Loading and parsing controls...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(p * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: BMRenderView(
                scheme: _currentScheme!,
                onButton: widget.client.handleButton,
                onDpad: widget.client.handleDpad,
                onTouchSet: widget.client.handleTouchSet,
                floatingDpadEnabled: widget.floatingDpadEnabled,
                smartWidescreenEnabled: widget.smartWidescreenEnabled,
                preserveDpadDragEnabled: widget.preserveDpadDragEnabled,
              ),
            ),
            Positioned(
              top: _currentScheme?.getRotation() == ControlOrientation.landscape
                  ? 12
                  : 56,
              right:
                  24 +
                  (_currentScheme?.getRotation() == ControlOrientation.landscape
                      ? 48.0
                      : 0.0),
              child: UnlockSlider(key: _sliderKey, onUnlocked: _showPauseMenu),
            ),
          ],
        ),
      ),
    );
  }
}
