// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

import 'package:flutter/material.dart';

class KeyboardOverlay extends StatefulWidget {
  const KeyboardOverlay({
    super.key,
    required this.initialText,
    required this.onKey,
  });

  final String initialText;
  final void Function(String key) onKey;

  @override
  State<KeyboardOverlay> createState() => _KeyboardOverlayState();
}

class _KeyboardOverlayState extends State<KeyboardOverlay> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late String _prev;

  @override
  void initState() {
    super.initState();
    _prev = widget.initialText;
    _controller = TextEditingController(text: widget.initialText)
      ..selection = TextSelection.collapsed(offset: widget.initialText.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String next) {
    final p = _prev;
    // Diff against the previous value: longest common prefix and suffix, then
    // the middle is what changed.
    final max = p.length < next.length ? p.length : next.length;
    var pre = 0;
    while (pre < max && p.codeUnitAt(pre) == next.codeUnitAt(pre)) {
      pre++;
    }
    var suf = 0;
    while (suf < p.length - pre &&
        suf < next.length - pre &&
        p.codeUnitAt(p.length - 1 - suf) ==
            next.codeUnitAt(next.length - 1 - suf)) {
      suf++;
    }
    final removed = p.length - pre - suf;
    final inserted = next.substring(pre, next.length - suf);
    for (var i = 0; i < removed; i++) {
      widget.onKey('');
    }
    if (inserted.isNotEmpty) {
      widget.onKey(inserted);
    }
    _prev = next;
  }

  void _onSubmitted(String _) {
    widget.onKey('\n');
    _focusNode.requestFocus(); // Keep the keyboard up for continued typing.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xFF1E1E2E),
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.12,
          left: 24,
          right: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
            textInputAction: TextInputAction.send,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.none,
            style: const TextStyle(color: Color(0xFFCDD6F4), fontSize: 24),
            cursorColor: const Color(0xFFCDD6F4),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF11111B),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF45475A),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF45475A),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
