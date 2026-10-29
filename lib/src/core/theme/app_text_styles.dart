import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Cyberpunk text styles based on the design specification
class AppTextStyles {
  // Font Families
  static const String headlineFont = 'Space Grotesk';
  static const String bodyFont = 'Chivo';
  static const String monoFont = 'JetBrains Mono';
  
  // Display Styles
  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 44 / 40,
    letterSpacing: -0.03,
    color: AppColors.peakPhosphorWhite,
  );
  
  static TextStyle displayLargeMobile = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 36 / 32,
    letterSpacing: -0.02,
    color: AppColors.peakPhosphorWhite,
  );
  
  // Headline Styles
  static TextStyle headlineLarge = GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 32 / 28,
    letterSpacing: -0.02,
    color: AppColors.peakPhosphorWhite,
  );
  
  static TextStyle headlineMedium = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.01,
    color: AppColors.peakPhosphorWhite,
  );
  
  static TextStyle headlineSmall = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: 0,
    color: AppColors.peakPhosphorWhite,
  );
  
  // Body Styles
  static TextStyle bodyLarge = GoogleFonts.chivo(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: AppColors.onSurface,
  );
  
  static TextStyle bodyMedium = GoogleFonts.chivo(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0.01,
    color: AppColors.onSurface,
  );
  
  static TextStyle bodySmall = GoogleFonts.chivo(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.01,
    color: AppColors.onSurfaceVariant,
  );
  
  // Label Styles (Monospace for telemetry)
  static TextStyle labelLarge = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.05,
    color: AppColors.onSurfaceVariant,
  );
  
  static TextStyle labelMedium = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.06,
    color: AppColors.onSurfaceVariant,
  );
  
  static TextStyle labelSmall = GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 14 / 10,
    letterSpacing: 0.08,
    color: AppColors.onSurfaceVariant,
  );
  
  // HUD Metric Style (for XP, stats, etc.)
  static TextStyle hudMetric = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 22 / 20,
    letterSpacing: 0.02,
    color: AppColors.electricCyan,
  );
  
  static TextStyle hudMetricSmall = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 16 / 14,
    letterSpacing: 0.02,
    color: AppColors.electricCyan,
  );
  
  static TextStyle hudMetricLarge = GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 32 / 28,
    letterSpacing: 0.02,
    color: AppColors.electricCyan,
  );
  
  // Accent Variants
  static TextStyle hudMetricYellow = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 22 / 20,
    letterSpacing: 0.02,
    color: AppColors.highVoltageYellow,
  );
  
  static TextStyle hudMetricViolet = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 22 / 20,
    letterSpacing: 0.02,
    color: AppColors.electricViolet,
  );
  
  static TextStyle hudMetricCrimson = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 22 / 20,
    letterSpacing: 0.02,
    color: AppColors.overloadCrimson,
  );
  
  // Uppercase variants for labels
  static TextStyle labelLargeUpper = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.1,
    color: AppColors.onSurfaceVariant,
  );
  
  static TextStyle labelMediumUpper = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.12,
    color: AppColors.onSurfaceVariant,
  );
  
  static TextStyle labelSmallUpper = GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 14 / 10,
    letterSpacing: 0.15,
    color: AppColors.onSurfaceVariant,
  );
}