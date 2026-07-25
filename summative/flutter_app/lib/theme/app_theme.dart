import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for a "network operations console" visual identity --
/// deliberately not the generic Material lavender-on-white default, since
/// this app's subject (network intrusion detection) calls for something
/// closer to a technical monitoring dashboard: dark surface, a single
/// cyan signal color, and a monospace face for data readouts.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0B1220);
  static const surface = Color(0xFF141B2D);
  static const surfaceAlt = Color(0xFF1B2438);
  static const border = Color(0xFF2A3450);

  static const accent = Color(0xFF22D3EE);
  static const accentDim = Color(0xFF0E7490);

  static const textPrimary = Color(0xFFE7ECF5);
  static const textSecondary = Color(0xFF8B97B0);
  static const textMuted = Color(0xFF5B6684);

  static const success = Color(0xFF34D399);
  static const successBg = Color(0xFF102A23);
  static const danger = Color(0xFFF87171);
  static const dangerBg = Color(0xFF2A1414);
  static const warning = Color(0xFFFBBF24);
  static const warningBg = Color(0xFF2A2210);
}

class AppTheme {
  AppTheme._();

  /// Data / numeric readout face -- used for the predicted value and for
  /// text typed into fields, reinforcing the "console" identity.
  static TextStyle mono({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w500,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.jetBrainsMono(fontSize: fontSize, fontWeight: fontWeight, color: color);

  /// Display face -- section headers, app bar title.
  static TextStyle display({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.spaceGrotesk(fontSize: fontSize, fontWeight: fontWeight, color: color);

  /// Body face -- labels, hints, prose.
  static TextStyle body({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textSecondary,
  }) =>
      GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color);

  static ThemeData get theme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.bg,
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: display(fontSize: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
        labelStyle: body(fontSize: 13, color: AppColors.textSecondary),
        helperStyle: body(fontSize: 11, color: AppColors.textMuted),
        errorStyle: body(fontSize: 11, color: AppColors.danger),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF08222A),
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          textStyle: display(fontSize: 16, color: const Color(0xFF08222A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: body(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
        ),
      ),
    );
  }
}
