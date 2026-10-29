import 'package:flutter/material.dart';

/// Cyberpunk color palette based on the design specification
class AppColors {
  // Core Void & Structural Chassis (Neutrals)
  static const Color coreVoid = Color(0xFF0A0C10);           // Primary void backing
  static const Color surfaceSubstrate = Color(0xFF12151E);   // Base card and container fill
  static const Color elevatedPlate = Color(0xFF1B202E);      // Component interactive fills
  static const Color brushedMetallicTrim = Color(0xFF2E374D); // Frame edges, inactive dividers
  static const Color mutedAlloyText = Color(0xFF8D98AF);     // De-prioritized telemetry
  static const Color peakPhosphorWhite = Color(0xFFF0F4FC);  // Primary readout text
  
  // Power Rails (Accents)
  static const Color electricCyan = Color(0xFF00F0FF);       // System telemetry, agility, intellect
  static const Color highVoltageYellow = Color(0xFFFFE600);  // Kinetic stamina, daily streaks
  static const Color electricViolet = Color(0xFFA855F7);     // Willpower, psychic attributes
  static const Color overloadCrimson = Color(0xFFFF0055);    // Failure states, energy depletion
  
  // Additional UI Colors
  static const Color surfaceContainerLow = Color(0xFF1A1C20);
  static const Color surfaceContainer = Color(0xFF1E2024);
  static const Color surfaceContainerHigh = Color(0xFF282A2E);
  static const Color surfaceContainerHighest = Color(0xFF333539);
  static const Color surfaceContainerLowest = Color(0xFF0C0E12);
  static const Color surfaceVariant = Color(0xFF333539);
  static const Color outline = Color(0xFF849495);
  static const Color outlineVariant = Color(0xFF3B494B);
  static const Color onSurface = Color(0xFFE2E2E8);
  static const Color onSurfaceVariant = Color(0xFFB9CACB);
  static const Color onBackground = Color(0xFFE2E2E8);
  static const Color background = Color(0xFF111318);
  
  // Status Colors
  static const Color success = electricCyan;
  static const Color warning = highVoltageYellow;
  static const Color error = overloadCrimson;
  static const Color info = electricViolet;

  // Material ColorScheme compat colors
  static const Color onPrimaryContainer = Color(0xFF006970);
  static const Color onSecondary = Color(0xFF373100);
  static const Color onSecondaryContainer = Color(0xFF716500);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color onTertiary = Color(0xFF490080);
  static const Color onTertiaryContainer = Color(0xFF842BD2);
  
  // Gradient Definitions
  static const LinearGradient gunmetalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B202E),
      Color(0xFF12151E),
      Color(0xFF262D40),
    ],
  );
  
  static const LinearGradient cyanGlowGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00F0FF),
      Color(0xFF7DF4FF),
      Color(0xFF00DBE9),
    ],
  );
  
  static const LinearGradient voltageGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFE600),
      Color(0xFFFDE400),
      Color(0xFFDEC800),
    ],
  );
  
  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFA855F7),
      Color(0xFFDDB7FF),
      Color(0xFFDD88FF),
    ],
  );
  
  static const LinearGradient primaryActionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFE600),
      Color(0xFF00F0FF),
      Color(0xFFFFE600),
    ],
  );
  
  // Glow Effects (as BoxShadow)
  static List<BoxShadow> cyanSurgeGlow = [
    BoxShadow(
      color: electricCyan.withOpacity(0.45),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: electricCyan.withOpacity(0.15),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> voltageFlareGlow = [
    BoxShadow(
      color: highVoltageYellow.withOpacity(0.5),
      blurRadius: 8,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: highVoltageYellow.withOpacity(0.2),
      blurRadius: 22,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> voidPulseGlow = [
    BoxShadow(
      color: electricViolet.withOpacity(0.45),
      blurRadius: 10,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: electricViolet.withOpacity(0.15),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> cardElevation = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}