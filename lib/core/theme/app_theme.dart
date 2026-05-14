import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App color palette — dark-first design
class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF00D4AA);
  static const Color primaryDark = Color(0xFF00A884);
  static const Color primaryLight = Color(0xFF33DDBB);
  static const Color secondary = Color(0xFFFF6B35);
  static const Color accent = Color(0xFFFFD700);

  // Background layers
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1C2333);
  static const Color card = Color(0xFF1A2235);
  static const Color cardElevated = Color(0xFF202A3E);

  // Glass effect
  static const Color glass = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textTertiary = Color(0xFF607D8B);
  static const Color textDisabled = Color(0xFF455A64);

  // Status colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF1744);
  static const Color info = Color(0xFF2979FF);

  // Match states
  static const Color live = Color(0xFFFF1744);
  static const Color upcoming = Color(0xFF2979FF);
  static const Color finished = Color(0xFF607D8B);

  // Card status
  static const Color yellowCard = Color(0xFFFFD600);
  static const Color redCard = Color(0xFFDD2C00);
  static const Color goal = Color(0xFF00C853);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF00D4AA),
    Color(0xFFFF6B35),
    Color(0xFFFFD700),
    Color(0xFF2979FF),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF0052CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A2235), Color(0xFF202A3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00BFA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// App text styles
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.25,
      );

  static TextStyle displayMedium(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle headlineLarge(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle headlineMedium(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle headlineSmall(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle titleLarge(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle titleMedium(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.15,
      );

  static TextStyle titleSmall(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.25,
      );

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        letterSpacing: 0.4,
      );

  static TextStyle labelLarge(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
      );

  static TextStyle labelMedium(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle labelSmall(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      );

  static TextStyle scoreboard(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle statNumber(BuildContext context) =>
      GoogleFonts.rajdhani(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );
}

/// App dimensions
class AppDimensions {
  AppDimensions._();

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusRound = 100.0;

  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;

  static const double cardElevation = 0;
  static const double appBarHeight = 60.0;
  static const double navBarHeight = 64.0;
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;
}

/// Main app theme
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final rajdhani = GoogleFonts.rajdhani();
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      secondaryContainer: Color(0xFF4A2000),
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      error: AppColors.error,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
      outline: AppColors.glassBorder,
      outlineVariant: AppColors.glass,
    ),
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusL)),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.rajdhani(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      selectedIconTheme: IconThemeData(color: AppColors.primary),
      unselectedIconTheme: IconThemeData(color: AppColors.textTertiary),
      selectedLabelTextStyle: TextStyle(color: AppColors.primary),
      unselectedLabelTextStyle: TextStyle(color: AppColors.textTertiary),
      indicatorColor: Color(0x2200D4AA),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      prefixIconColor: AppColors.textTertiary,
      suffixIconColor: AppColors.textTertiary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      side: const BorderSide(color: AppColors.glassBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.glassBorder,
      thickness: 1,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusXL)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceVariant,
      contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.textTertiary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withOpacity(0.3);
        }
        return AppColors.surfaceVariant;
      }),
    ),
    tabBarTheme: const TabBarThemeData(
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textTertiary,
      dividerColor: Colors.transparent,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 57,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 45,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.rajdhani(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    ),
    extensions: const [],
  );
  } // end get dark
}
