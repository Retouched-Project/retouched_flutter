// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ddavef/KinteLiX retouched_flutter

enum SamplingMode {
  nearestNeighbor,
  bilinear;

  static SamplingMode fromString(String? s) {
    return "nearest" == s ? nearestNeighbor : bilinear;
  }
}
