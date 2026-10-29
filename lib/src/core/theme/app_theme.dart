import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Main application theme for the cyberpunk aesthetic
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricCyan,
        onPrimary: Color(0xFF00363A),
        primaryContainer: AppColors.electricCyan,
        onPrimaryContainer: Color(0xFF006970),
        secondary: AppColors.highVoltageYellow,
        onSecondary: Color(0xFF373100),
        secondaryContainer: AppColors.highVoltageYellow,
        onSecondaryContainer: Color(0xFF716500),
        tertiary: AppColors.electricViolet,
        onTertiary: Color(0xFF490080),
        tertiaryContainer: Color(0xFFEACFFF),
        onTertiaryContainer: Color(0xFF842BD2),
        error: AppColors.overloadCrimson,
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: AppColors.surfaceSubstrate,
        onSurface: AppColors.onSurface,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        shadow: Colors.black,
        inverseSurface: AppColors.onSurface,
        onInverseSurface: AppColors.surfaceSubstrate,
        inversePrimary: Color(0xFF006970),
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.background,
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLow.withOpacity(0.8),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 4,
        surfaceTintColor: AppColors.electricCyan.withOpacity(0.1),
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.onSurface,
        ),
        iconTheme: const IconThemeData(color: AppColors.electricCyan),
        actionsIconTheme: const IconThemeData(color: AppColors.electricCyan),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shadowColor: Colors.black,
        surfaceTintColor: AppColors.electricCyan.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: AppColors.brushedMetallicTrim,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricCyan,
          foregroundColor: AppColors.coreVoid,
          elevation: 0,
          shadowColor: AppColors.electricCyan,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: AppTextStyles.labelLargeUpper.copyWith(
            color: AppColors.coreVoid,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.coreVoid.withOpacity(0.1);
              }
              return null;
            },
          ),
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricCyan,
          side: const BorderSide(color: AppColors.electricCyan, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: AppTextStyles.labelLargeUpper.copyWith(
            color: AppColors.electricCyan,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mutedAlloyText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.labelMediumUpper,
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.coreVoid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.mutedAlloyText,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.mutedAlloyText.withOpacity(0.6),
        ),
        floatingLabelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.electricCyan,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.brushedMetallicTrim,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.brushedMetallicTrim,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.electricCyan,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.overloadCrimson,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: AppColors.overloadCrimson,
            width: 2,
          ),
        ),
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.electricCyan,
        inactiveTrackColor: AppColors.brushedMetallicTrim,
        thumbColor: AppColors.electricCyan,
        overlayColor: AppColors.electricCyan.withOpacity(0.2),
        valueIndicatorColor: AppColors.electricCyan,
        valueIndicatorTextStyle: AppTextStyles.hudMetricSmall.copyWith(
          color: AppColors.coreVoid,
        ),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricCyan;
          }
          return AppColors.mutedAlloyText;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricCyan.withOpacity(0.3);
          }
          return AppColors.brushedMetallicTrim;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricCyan;
          }
          return AppColors.brushedMetallicTrim;
        }),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.highVoltageYellow;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.coreVoid),
        side: const BorderSide(
          color: AppColors.brushedMetallicTrim,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.electricCyan;
          }
          return AppColors.mutedAlloyText;
        }),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.electricCyan,
        linearTrackColor: AppColors.brushedMetallicTrim,
        circularTrackColor: AppColors.brushedMetallicTrim,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLow.withOpacity(0.85),
        selectedItemColor: AppColors.electricCyan,
        unselectedItemColor: AppColors.mutedAlloyText,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: AppTextStyles.labelSmallUpper.copyWith(
          color: AppColors.electricCyan,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmallUpper.copyWith(
          color: AppColors.mutedAlloyText,
        ),
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLow.withOpacity(0.85),
        indicatorColor: AppColors.electricCyan.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmallUpper.copyWith(
              color: AppColors.electricCyan,
            );
          }
          return AppTextStyles.labelSmallUpper.copyWith(
            color: AppColors.mutedAlloyText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.electricCyan, size: 24);
          }
          return const IconThemeData(color: AppColors.mutedAlloyText, size: 22);
        }),
        height: 72,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.brushedMetallicTrim,
        thickness: 1,
        space: 1,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        disabledColor: AppColors.surfaceContainerLow.withOpacity(0.5),
        selectedColor: AppColors.electricCyan.withOpacity(0.2),
        secondarySelectedColor: AppColors.highVoltageYellow.withOpacity(0.2),
        labelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        secondaryLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.coreVoid,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        side: const BorderSide(
          color: AppColors.brushedMetallicTrim,
          width: 1,
        ),
        brightness: Brightness.dark,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainer,
        elevation: 24,
        surfaceTintColor: AppColors.electricCyan.withOpacity(0.1),
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
      
      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionTextColor: AppColors.highVoltageYellow,
        behavior: SnackBarBehavior.floating,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 8,
      ),
      
      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          border: Border.all(
            color: AppColors.brushedMetallicTrim,
            width: 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        textStyle: AppTextStyles.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      
      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.electricCyan,
        unselectedLabelColor: AppColors.mutedAlloyText,
        indicatorColor: AppColors.electricCyan,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: AppTextStyles.labelMediumUpper,
        unselectedLabelStyle: AppTextStyles.labelMediumUpper,
        dividerColor: AppColors.brushedMetallicTrim,
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surfaceContainer,
        selectedTileColor: AppColors.electricCyan.withOpacity(0.1),
        iconColor: AppColors.electricCyan,
        textColor: AppColors.onSurface,
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall,
        leadingAndTrailingTextStyle: AppTextStyles.labelSmall,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.electricCyan,
        foregroundColor: AppColors.coreVoid,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        highlightElevation: 16,
        shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        extendedTextStyle: AppTextStyles.labelLargeUpper.copyWith(
          color: AppColors.coreVoid,
        ),
      ),
      
      // Text Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.electricCyan,
        selectionColor: AppColors.electricCyan.withOpacity(0.3),
        selectionHandleColor: AppColors.electricCyan,
      ),
      
      // Platform overrides for Android
      platform: TargetPlatform.android,
    );
  }
  
  // High contrast variant for accessibility
  static ThemeData get highContrastTheme {
    final theme = darkTheme;
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: AppColors.peakPhosphorWhite,
        onPrimary: AppColors.coreVoid,
        secondary: AppColors.highVoltageYellow,
        onSecondary: AppColors.coreVoid,
      ),
      cardTheme: theme.cardTheme.copyWith(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(
            color: AppColors.peakPhosphorWhite,
            width: 2,
          ),
        ),
      ),
    );
  }
}