/// Root application widget: theme and the single home route.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'pages/home_page.dart';

/// Brand palette shared across the app: a deep climate-teal primary plus a
/// warm terracotta accent, so screens read as more than one flat wash of
/// the same pale color. Widgets that can't reach a [ColorScheme] directly
/// (e.g. the hand-painted world map) read these constants instead of
/// hardcoding their own hex values.
class AppColors {
  const AppColors._();

  static const teal = Color(0xFF0B6E5C);
  static const tealDark = Color(0xFF06493D);
  static const terracotta = Color(0xFFD97A3F);

  static const mapSelected = Color(0xFF0B6E5C);
  static const mapAvailable = Color(0xFF7FC8B4);
  static const mapUnavailable = Color(0xFFE3E7E5);

  // Result-chart series colors: one hue per metric, validated as a
  // colorblind-safe categorical pair (adjacent CVD deltaE, OKLab, both
  // modes) rather than eyeballed, since case counts and temperature are
  // always shown as separate small-multiple charts a reader compares
  // side by side. Dark steps sit in the dark-surface lightness band
  // (OKLCH L 0.48-0.67); light steps in the light band (L 0.43-0.77).
  static const chartCases = Color(0xFF0EA383);
  static const chartCasesDark = Color(0xFF2E9E80);
  static const chartTemperature = Color(0xFFDB6B2C);
  static const chartTemperatureDark = Color(0xFFD3722E);
  static const chartPrecipitation = Color(0xFF1E88E5);
  static const chartPrecipitationDark = Color(0xFF64B5F6);
  static const chartIncidence = Color(0xFF8E24AA);
  static const chartIncidenceDark = Color(0xFFBA68C8);
}

class ClimateHealthApp extends StatelessWidget {
  const ClimateHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climate-Health Data Integration Platform',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF5FCBAE),
            onPrimary: Color(0xFF04372C),
            primaryContainer: AppColors.tealDark,
            onPrimaryContainer: Color(0xFFC9F1E4),
            secondary: Color(0xFFF0A876),
            onSecondary: Color(0xFF44230A),
            surface: Color(0xFF14181A),
            onSurface: Color(0xFFE3E7E5),
            surfaceContainerHighest: Color(0xFF1F2528),
            outline: Color(0xFF3A4144),
          )
        : const ColorScheme.light(
            primary: AppColors.teal,
            onPrimary: Colors.white,
            primaryContainer: AppColors.teal,
            onPrimaryContainer: Colors.white,
            secondary: AppColors.terracotta,
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1B1F1E),
            surfaceContainerHighest: Color(0xFFEFF3F1),
            outline: Color(0xFFCBD3D0),
          );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF0E1112) : const Color(0xFFF6F8F7),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
