import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Brand
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Secondary
  static const Color secondary = Color(0xFF6366F1);
  static const Color accent = Color(0xFF10B981);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Light Theme
  static const Color lightBg = Color(0xFFF9FAFB);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Dark Theme
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // ==================== MODULE GRADIENTS ====================
  // No orange, no brown, no bright red

  static const List<Color> routeGradient = [
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
  ];

  static const List<Color> emergencyGradient = [
    Color(0xFFEC4899),
    Color(0xFFDB2777),
  ];

  static const List<Color> applyGradient = [
    Color(0xFF06B6D4),
    Color(0xFF0891B2),
  ];

  static const List<Color> cardGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> loginGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF7C3AED),
  ];

  static const List<Color> profileGradient = [
    Color(0xFF6366F1),
    Color(0xFF4F46E5),
  ];

  static const List<Color> feedbackGradient = [
    Color(0xFFA855F7),
    Color(0xFF9333EA),
  ];

  static const List<Color> developerGradient = [
    Color(0xFF64748B),
    Color(0xFF475569),
  ];

  static const List<Color> trackingGradient = [
    Color(0xFF14B8A6),
    Color(0xFF0D9488),
  ];

  // Lost & Found — Yellow/Amber (no brown)
  static const List<Color> lostfoundGradient = [
    Color(0xFFEAB308),
    Color(0xFFCA8A04),
  ];

  static const List<Color> attendanceGradient = [
    Color(0xFF6366F1),
    Color(0xFF4F46E5),
  ];

  static const List<Color> faqGradient = [
    Color(0xFF06B6D4),
    Color(0xFF0284C7),
  ];

  // Driver — Lime (no orange)
  static const List<Color> driverGradient = [
    Color(0xFF84CC16),
    Color(0xFF65A30D),
  ];

  // SOS — Deep Rose (no bright red)
  static const List<Color> sosGradient = [
    Color(0xFFF43F5E),
    Color(0xFFE11D48),
  ];

  // Global
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF6366F1)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  // Lost/Found badge colors
  static const Color lostBadge = Color(0xFFE11D48);
  static const Color foundBadge = Color(0xFF10B981);

  // Glass
  static Color glassLight = Colors.white.withValues(alpha: 0.15);
  static Color glassDark = Colors.black.withValues(alpha: 0.3);
}

class AppSizes {
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;

  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double r32 = 32.0;

  static const double fontXs = 11.0;
  static const double fontSm = 13.0;
  static const double fontBase = 15.0;
  static const double fontLg = 17.0;
  static const double fontXl = 20.0;
  static const double font2xl = 24.0;
  static const double font3xl = 32.0;
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: AppSizes.font3xl,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppSizes.font2xl,
        fontWeight: FontWeight.w700,
        color: AppColors.lightText,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontXl,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontBase,
        fontWeight: FontWeight.w600,
        color: AppColors.lightText,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontBase,
        color: AppColors.lightText,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontSm,
        color: AppColors.lightTextSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r20),
      ),
      color: AppColors.lightSurface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p24,
          vertical: AppSizes.p16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: AppSizes.fontBase,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      error: AppColors.error,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: AppSizes.font3xl,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppSizes.font2xl,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontXl,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontBase,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: AppSizes.fontBase,
        color: AppColors.darkText,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: AppSizes.fontSm,
        color: AppColors.darkTextSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkText,
      iconTheme: const IconThemeData(color: AppColors.darkText),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: AppSizes.fontLg,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r20),
      ),
      color: AppColors.darkSurface,
    ),
  );
}