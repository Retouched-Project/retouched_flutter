// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

enum ControlOrientation {
  portrait,
  landscape;

  static ControlOrientation fromString(String? s) {
    return "landscape" == s ? landscape : portrait;
  }
}
