import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified Global Theme System - Production Quality
/// Single source of truth for all colors, typography, and spacing
class GlobalTheme {
  // === PRIMARY COLORS ===
  static const Color primaryNeon = Color(0xFFD7FF42); // Neon yellow
  static const Color primaryAccent = Color(0xFF42FF9E); // Neon green
  static const Color primaryAction = Color(0xFF4287FF); // Electric blue

  // === BACKGROUND COLORS ===
  static const Color backgroundPrimary = Color(
    0xFF000000,
  ); // True black for OLED
  static const Color backgroundSecondary = Color(0xFF0A0A0A); // Slight lift
  static const Color backgroundTertiary = Color(0xFF121212); // Material surface

  // === SURFACE COLORS ===
  static const Color surfaceCard = Color(0xFF1E1E1E); // Cards and containers
  static const Color surfaceElevated = Color(0xFF2A2A2A); // Elevated elements
  static const Color surfaceBorder = Color(0xFF333333); // Borders and dividers

  // === TEXT COLORS ===
  static const Color textPrimary = Color(0xFFFFFFFF); // High contrast white
  static const Color textSecondary = Color(0xFFE0E0E0); // Readable secondary
  static const Color textTertiary = Color(0xFFB0B0B0); // Subtle text
  static const Color textDisabled = Color(0xFF666666); // Disabled state

  // === STATUS COLORS ===
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFF9800);
  static const Color statusError = Color(0xFFF44336);
  static const Color statusInfo = Color(0xFF2196F3);

  // === GRADIENTS ===
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.3, 1.0],
    colors: [backgroundPrimary, backgroundSecondary, backgroundTertiary],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryNeon, Color(0xFFB8E830)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceCard, Color(0xFF1A1A1A)],
  );

  // === SPACING SYSTEM (8dp grid) ===
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;

  // === BORDER RADIUS ===
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 1000.0;

  // === SHADOWS ===
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static List<BoxShadow> neonGlow(Color color, {double opacity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 16,
      offset: const Offset(0, 0),
    ),
    BoxShadow(
      color: color.withOpacity(opacity * 0.5),
      blurRadius: 32,
      offset: const Offset(0, 4),
    ),
  ];

  // === TYPOGRAPHY SYSTEM ===
  static TextTheme get textTheme => TextTheme(
    // Display styles for large headers
    displayLarge: GoogleFonts.inter(
      fontSize: 57,
      fontWeight: FontWeight.w900,
      height: 1.12,
      letterSpacing: -0.25,
      color: textPrimary,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45,
      fontWeight: FontWeight.w800,
      height: 1.16,
      color: textPrimary,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.22,
      color: textPrimary,
    ),

    // Headline styles
    headlineLarge: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: textPrimary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.29,
      color: textPrimary,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.33,
      color: textPrimary,
    ),

    // Title styles
    titleLarge: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.27,
      color: textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.50,
      letterSpacing: 0.15,
      color: textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: textPrimary,
    ),

    // Body styles
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.50,
      letterSpacing: 0.5,
      color: textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25,
      color: textSecondary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4,
      color: textTertiary,
    ),

    // Label styles
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1,
      color: textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.5,
      color: textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.45,
      letterSpacing: 0.5,
      color: textTertiary,
    ),
  );

  // === MAIN THEME DATA ===
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color scheme using Material 3 standards
    colorScheme: const ColorScheme.dark(
      primary: primaryNeon,
      primaryContainer: Color(0xFF2A2A00),
      secondary: primaryAccent,
      secondaryContainer: Color(0xFF002A17),
      tertiary: primaryAction,
      tertiaryContainer: Color(0xFF002A4A),
      surface: backgroundTertiary,
      surfaceContainer: surfaceCard,
      surfaceContainerHighest: surfaceElevated,
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onTertiary: Color(0xFF000000),
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: surfaceBorder,
      outlineVariant: Color(0xFF2A2A2A),
      error: statusError,
      onError: Color(0xFF000000),
      errorContainer: Color(0xFF4A1C1C),
      onErrorContainer: Color(0xFFFFDADA),
    ),

    scaffoldBackgroundColor: backgroundPrimary,
    textTheme: textTheme,

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNeon,
        foregroundColor: Colors.black,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryNeon,
        side: const BorderSide(color: primaryNeon, width: 1.5),
        padding: const EdgeInsets.symmetric(
          horizontal: spacing24,
          vertical: spacing12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryAccent,
        padding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: surfaceCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),

    // AppBar theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary, size: 24),
    ),

    // Icon theme
    iconTheme: const IconThemeData(color: textSecondary, size: 24),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: surfaceBorder,
      thickness: 1,
      space: 1,
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceCard,
      hintStyle: textTheme.bodyMedium?.copyWith(color: textDisabled),
      labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryNeon, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: statusError),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundTertiary,
      selectedItemColor: primaryNeon,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Tab bar theme
    tabBarTheme: TabBarThemeData(
      labelColor: primaryNeon,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryNeon,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  // === UTILITY METHODS ===

  /// Get contrast color for better accessibility
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Adjust color opacity safely
  static Color adjustOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Darken a color by a percentage
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Lighten a color by a percentage
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
}

/// Extension for easier theme access in widgets
extension GlobalThemeExtension on ThemeData {
  Color get primaryNeon => GlobalTheme.primaryNeon;
  Color get primaryAccent => GlobalTheme.primaryAccent;
  Color get primaryAction => GlobalTheme.primaryAction;

  Color get backgroundPrimary => GlobalTheme.backgroundPrimary;
  Color get backgroundSecondary => GlobalTheme.backgroundSecondary;
  Color get backgroundTertiary => GlobalTheme.backgroundTertiary;

  Color get surfaceCard => GlobalTheme.surfaceCard;
  Color get surfaceElevated => GlobalTheme.surfaceElevated;
  Color get surfaceBorder => GlobalTheme.surfaceBorder;

  Color get textPrimary => GlobalTheme.textPrimary;
  Color get textSecondary => GlobalTheme.textSecondary;
  Color get textTertiary => GlobalTheme.textTertiary;
  Color get textDisabled => GlobalTheme.textDisabled;

  LinearGradient get backgroundGradient => GlobalTheme.backgroundGradient;
  LinearGradient get primaryGradient => GlobalTheme.primaryGradient;
  LinearGradient get cardGradient => GlobalTheme.cardGradient;
}
