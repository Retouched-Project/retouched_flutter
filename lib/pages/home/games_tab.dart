// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

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
