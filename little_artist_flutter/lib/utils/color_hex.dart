import 'package:flutter/material.dart';

extension ColorHex on String {
  /// Converts hex string (e.g. "F2784B" or "#F2784B") to a Color.
  Color toColor() {
    final hex = replaceFirst('#', '');
    final fullHex = hex.length == 6 ? 'FF$hex' : hex;
    return Color(int.parse(fullHex, radix: 16));
  }
}
