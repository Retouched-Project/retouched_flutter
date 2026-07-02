// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NavOverlay extends StatelessWidget {
  const NavOverlay({super.key, required this.onNav});

  final void Function(String command) onNav;

  static const double _gap = 15;
  static const Size _szActivate = Size(94, 94);
  static const Size _szUp = Size(93, 182);
  static const Size _szDown = Size(93, 189);
  static const Size _szLeft = Size(110, 93);
  static const Size _szRight = Size(100, 93);
  static const Size _szBack = Size(63, 57);

  @override
  Widget build(BuildContext context) {
    final upDy = -(_szActivate.height / 2 + _gap + _szUp.height / 2);
    final downDy = _szActivate.height / 2 + _gap + _szDown.height / 2;
    final leftDx = -(_szActivate.width / 2 + _gap + _szLeft.width / 2);
    final rightDx = _szActivate.width / 2 + _gap + _szRight.width / 2;

    Widget centered(Offset offset, Widget child) => Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: Transform.translate(offset: offset, child: child),
      ),
    );

    Widget button(String name, Size size) => _NavButton(
      asset: 'assets/nav/nav_btn_$name.svg',
      size: size,
      command: name,
      onNav: onNav,
    );

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          centered(Offset(0, upDy), button('up', _szUp)),
          centered(Offset(0, downDy), button('down', _szDown)),
          centered(Offset(leftDx, 0), button('left', _szLeft)),
          centered(Offset(rightDx, 0), button('right', _szRight)),
          centered(Offset.zero, button('activate', _szActivate)),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: button('back', _szBack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.asset,
    required this.size,
    required this.command,
    required this.onNav,
  });

  final String asset;
  final Size size;
  final String command;
  final void Function(String command) onNav;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      widget.asset,
      width: widget.size.width,
      height: widget.size.height,
    );
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        setState(() => _pressed = true);
        widget.onNav(widget.command);
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: _pressed
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF888888),
                BlendMode.modulate,
              ),
              child: svg,
            )
          : svg,
    );
  }
}
