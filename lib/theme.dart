// SOVEREIGN — Fondasi visual Fase 0 (lihat docs/ui.md §2).
// Deep Navy bg, Blue Slate kartu, aksen Green/Amber/Red/Cyan.
// Satuan: dp untuk dimensi, sp untuk teks. Margin 16dp, sentuh min 48dp.
import 'package:flutter/material.dart';

/// Token warna SOVEREIGN.
abstract final class SovereignColors {
  static const Color deepNavy = Color(0xFF071827);
  static const Color deepNavySoft = Color(0xFF0B2237);
  static const Color blueSlate = Color(0xFF102C43);
  static const Color blueSlateElevated = Color(0xFF16334D);
  static const Color border = Color(0xFF1E3A52);
  static const Color green = Color(0xFF22C55E);
  static const Color amber = Color(0xFFFBBF24);
  static const Color red = Color(0xFFF87171);
  static const Color cyan = Color(0xFF36C5F0);
  static const Color ink = Color(0xFFF2F7FB);
  static const Color muted = Color(0xFF9FB3C8);
  static const Color mutedDim = Color(0xFF6E869D);
}

/// Jarak & ukuran baku (dp).
abstract final class SovereignSpacing {
  static const double margin = 16.0;
  static const double gap = 12.0;
  static const double radius = 16.0;
  static const double radiusSmall = 12.0;
  static const double touchMin = 48.0;
  static const double headerHeight = 60.0;
  static const double bottomNavHeight = 68.0;
  static const double kpiHeight = 88.0;
  static const double miniCardHeight = 84.0;
  static const double mapHeight = 188.0;
  static const double processButtonHeight = 52.0;
}

/// Tipografi (sp) — angka utama tebal, keterangan kecil.
abstract final class SovereignType {
  static const TextStyle heroNumber = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.15,
  );
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const TextStyle body = TextStyle(fontSize: 14, height: 1.4);
  static const TextStyle support = TextStyle(fontSize: 13, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.4);
}

/// ThemeData gelap SOVEREIGN.
ThemeData sovereignTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final colorScheme = const ColorScheme.dark(
    primary: SovereignColors.cyan,
    onPrimary: SovereignColors.deepNavy,
    secondary: SovereignColors.green,
    onSecondary: SovereignColors.deepNavy,
    tertiary: SovereignColors.amber,
    error: SovereignColors.red,
    onError: SovereignColors.deepNavy,
    surface: SovereignColors.blueSlate,
    onSurface: SovereignColors.ink,
    surfaceContainerHighest: SovereignColors.blueSlateElevated,
    outline: SovereignColors.border,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SovereignColors.deepNavy,
    canvasColor: SovereignColors.deepNavy,
    dividerColor: SovereignColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: SovereignColors.deepNavy,
      foregroundColor: SovereignColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: SovereignColors.blueSlate,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SovereignSpacing.radius),
        side: const BorderSide(color: SovereignColors.border, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(SovereignSpacing.processButtonHeight),
        backgroundColor: SovereignColors.green,
        foregroundColor: SovereignColors.deepNavy,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, SovereignSpacing.touchMin),
        foregroundColor: SovereignColors.ink,
        side: const BorderSide(color: SovereignColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, SovereignSpacing.touchMin),
        foregroundColor: SovereignColors.cyan,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: SovereignColors.cyan,
      inactiveTrackColor: SovereignColors.border,
      thumbColor: SovereignColors.cyan,
      overlayColor: Color(0x2936C5F0),
      valueIndicatorColor: SovereignColors.cyan,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SovereignColors.deepNavy,
      indicatorColor: const Color(0x1A36C5F0),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: SovereignColors.cyan, size: 24);
        }
        return const IconThemeData(color: SovereignColors.muted, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        const baseStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
        if (states.contains(WidgetState.selected)) {
          return baseStyle.copyWith(color: SovereignColors.cyan);
        }
        return baseStyle.copyWith(color: SovereignColors.muted);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SovereignColors.blueSlateElevated,
      contentTextStyle: const TextStyle(color: SovereignColors.ink, fontSize: 13),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SovereignColors.border),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: SovereignColors.blueSlate,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SovereignColors.border),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SovereignColors.blueSlate,
      modalBackgroundColor: SovereignColors.blueSlate,
      showDragHandle: true,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: SovereignColors.ink,
      displayColor: SovereignColors.ink,
    ),
  );
}

/// Status dengan warna + label + ikon (jangan warna saja, ui.md §2.1).
enum SovereignStatus { good, warn, bad, neutral }

extension SovereignStatusX on SovereignStatus {
  Color get color => switch (this) {
        SovereignStatus.good => SovereignColors.green,
        SovereignStatus.warn => SovereignColors.amber,
        SovereignStatus.bad => SovereignColors.red,
        SovereignStatus.neutral => SovereignColors.muted,
      };

  String get label => switch (this) {
        SovereignStatus.good => 'Baik',
        SovereignStatus.warn => 'Waspada',
        SovereignStatus.bad => 'Kritis',
        SovereignStatus.neutral => 'Netral',
      };

  IconData get icon => switch (this) {
        SovereignStatus.good => Icons.check_circle_rounded,
        SovereignStatus.warn => Icons.warning_amber_rounded,
        SovereignStatus.bad => Icons.error_outline_rounded,
        SovereignStatus.neutral => Icons.info_outline_rounded,
      };
}
