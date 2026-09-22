// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../game_client/game_client.dart';
import '../../bmlib/bm_lib.dart';
import '../../widgets/stacked_background_icons.dart';

class GamesTab extends StatelessWidget {
  const GamesTab({super.key, required this.client, required this.onLaunchGame});

  final GameClient? client;
  final void Function(BmRegistryInfo game) onLaunchGame;

  @override
  Widget build(BuildContext context) {
    final client = this.client;
    if (client == null) {
      return const StackedBackgroundIcons(connected: false, hasGames: false);
    }

    return StreamBuilder<List<String>>(
      stream: client.gamesStream,
      initialData: const <String>[],
      builder: (context, snap) {
        final games = client.gameInfos;
        final background = Positioned.fill(
          child: StackedBackgroundIcons(
            connected: true,
            hasGames: games.isNotEmpty,
          ),
        );
        if (games.isEmpty) {
          return const StackedBackgroundIcons(connected: true, hasGames: false);
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
                    'http://${client.server.ip}:8080/apps/icons/${game.appId}.png';
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
                  onTap: () => onLaunchGame(game),
                );
              },
            ),
          ],
        );
      },
    );
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
              '${game.currentPlayers ?? 0}/${game.maxPlayers ?? 0}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  static const List<Color> _slotColors = [
    Color(0xFFFF6600),
    Color(0xFFFFCC00),
    Color(0xFFFF3399),
    Color(0xFFFF0066),
    Color(0xFFCC00FF),
    Color(0xFF999900),
    Color(0xFF9999CC),
    Color(0xFF00CC99),
    Color(0xFF009900),
    Color(0xFF00CCFF),
    Color(0xFF003366),
    Color(0xFF99FF00),
    Color(0xFFCC0000),
    Color(0xFF80CD68),
    Color(0xFF6600FF),
  ];

  Color _slotColor(int slotId) {
    final index = (math.max(1, slotId) - 1) % _slotColors.length;
    return _slotColors[index];
  }
}
