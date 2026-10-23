import 'package:flutter/material.dart';

abstract final class BowlColors {
  static const ink = Color(0xFF183437);
  static const canvas = Color(0xFFF6F5F0);
  static const orange = Color(0xFFC64628);
  static const mint = Color(0xFFDCEAE0);
  static const muted = Color(0xFF607274);
  static const line = Color(0xFFE2E5DF);
}

final tallyBowlTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: BowlColors.canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: BowlColors.ink,
    primary: BowlColors.ink,
    primaryContainer: BowlColors.mint,
    onPrimaryContainer: BowlColors.ink,
    secondary: BowlColors.orange,
    surface: Colors.white,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: BowlColors.ink,
    displayColor: BowlColors.ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: BowlColors.canvas,
    foregroundColor: BowlColors.ink,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: BowlColors.line),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: BowlColors.canvas,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: BowlColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: BowlColors.line),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  ),
  dividerTheme: const DividerThemeData(color: BowlColors.line),
);
