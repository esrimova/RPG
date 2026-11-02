import 'package:flutter/material.dart';

class Pal {
  static const bg = Color(0xFF0B0E14);
  static const surface = Color(0xFF141925);
  static const surface2 = Color(0xFF1C2333);
  static const line = Color(0xFF2A3350);
  static const text = Color(0xFFE8ECF5);
  static const muted = Color(0xFF8D98AF);
  static const cyan = Color(0xFF00E5F5);
  static const yellow = Color(0xFFFFD60A);
  static const violet = Color(0xFFA855F7);
  static const red = Color(0xFFFF4D6D);
  static const green = Color(0xFF4ADE80);

  /// Colors a user can pick for branches and activities.
  static const picks = <int>[0xFF00E5F5, 0xFFA855F7, 0xFFFFD60A, 0xFF4ADE80, 0xFFFF4D6D, 0xFFFF9F43, 0xFF4D9DFF, 0xFFF472B6];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Pal.cyan, brightness: Brightness.dark).copyWith(
    primary: Pal.cyan,
    onPrimary: const Color(0xFF00363B),
    secondary: Pal.violet,
    surface: Pal.surface,
    error: Pal.red,
  );
  final border = OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Pal.line));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Pal.bg,
    fontFamily: 'SpaceGrotesk',
    appBarTheme: const AppBarTheme(backgroundColor: Pal.bg, elevation: 0, scrolledUnderElevation: 0),
    cardTheme: CardThemeData(
      color: Pal.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Pal.line)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Pal.surface2,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: Pal.cyan)),
      isDense: true,
    ),
    dialogTheme: DialogThemeData(backgroundColor: Pal.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
