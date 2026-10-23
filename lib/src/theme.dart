import 'package:flutter/material.dart';

/// Brand artwork/print colors. Interactive surfaces use the active ColorScheme.
abstract final class BowlColors {
  static const ink = Color(0xFF183437);
  static const canvas = Color(0xFFF6F5F0);
  static const orange = Color(0xFFC64628);
  static const mint = Color(0xFFDCEAE0);
  static const muted = Color(0xFF607274);
  static const line = Color(0xFFE2E5DF);
}

final tallyBowlTheme = _theme(Brightness.light);
final tallyBowlDarkTheme = _theme(Brightness.dark);

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BowlColors.ink,
    brightness: brightness,
    primary: dark ? const Color(0xFFB5DBCF) : BowlColors.ink,
    onPrimary: dark ? BowlColors.ink : Colors.white,
    primaryContainer: dark ? const Color(0xFF274846) : BowlColors.mint,
    onPrimaryContainer: dark ? BowlColors.mint : BowlColors.ink,
    secondary: dark ? const Color(0xFFFFB392) : BowlColors.orange,
    surface: dark ? const Color(0xFF1B2728) : Colors.white,
    onSurface: dark ? const Color(0xFFE5EEEA) : BowlColors.ink,
    onSurfaceVariant: dark ? const Color(0xFFB8CAC4) : BowlColors.muted,
    outlineVariant: dark ? const Color(0xFF48615F) : BowlColors.line,
  );
  final canvas = dark ? const Color(0xFF101C1D) : BowlColors.canvas;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: canvas,
    colorScheme: scheme,
    textTheme: ThemeData(brightness: brightness).textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: canvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
