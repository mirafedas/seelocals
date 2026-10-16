import 'package:flutter/material.dart';

// Placeholder; the real design system arrives in Step 2.
abstract final class AppTheme {
  static const _seed = Color(0xFF1B7F6B);

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  );

  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );
}
