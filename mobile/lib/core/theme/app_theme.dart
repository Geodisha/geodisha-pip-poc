import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette
  static const Color primaryColor    = Color(0xFF0A1628);
  static const Color primaryLight    = Color(0xFF1E3A8A);
  static const Color primaryDark     = Color(0xFF050D1A);
  static const Color accentColor     = Color(0xFF6366F1);
  static const Color accentLight     = Color(0xFF818CF8);
  static const Color accentGlow      = Color(0xFF4F46E5);
  static const Color secondaryColor  = Color(0xFF059669);
  static const Color secondaryLight  = Color(0xFF10B981);
  static const Color successColor    = Color(0xFF10B981);
  static const Color warningColor    = Color(0xFFF59E0B);
  static const Color errorColor      = Color(0xFFEF4444);
  static const Color infoColor       = Color(0xFF3B82F6);
  static const Color textPrimary     = Color(0xFF0F172A);
  static const Color textSecondary   = Color(0xFF64748B);
  static const Color backgroundLight = Color(0xFFF0F4FF);
  static const Color backgroundColor = Color(0xFFE8EEFF);
  static const Color surfaceColor    = Colors.white;
  static const Color dividerColor    = Color(0xFFE2E8F0);
  static const Color darkGrey        = Color(0xFF334155);
  static const Color mediumGrey      = Color(0xFF94A3B8);
  static const Color lightGrey       = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0F2554), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF050D1A), Color(0xFF0F2554), Color(0xFF162B66)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF1E3A8A), Color(0xFF4F46E5)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // Decorations
  static BoxDecoration primaryGradientDecoration({double radius = 0}) =>
      BoxDecoration(gradient: appBarGradient, borderRadius: BorderRadius.circular(radius));

  static BoxDecoration cardDecoration({Color? color, double radius = 16}) =>
      BoxDecoration(
        color: color ?? surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F2554).withValues(alpha: 0.07), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      );

  static BoxDecoration glassDecoration({double radius = 16, double opacity = 0.12}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
      );

  static BoxDecoration glowDecoration(Color glowColor, {double radius = 16}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: glowColor.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
          BoxShadow(color: glowColor.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 4)),
        ],
      );

  // Inter typography
  static TextTheme get _textTheme => GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.0, height: 1.15),
      displayMedium:  TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.7),
      headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.3),
      headlineSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.1),
      titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge:      TextStyle(fontSize: 15, color: textPrimary, height: 1.6),
      bodyMedium:     TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
      bodySmall:      TextStyle(fontSize: 11, color: textSecondary, height: 1.4),
      labelLarge:     TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.2),
      labelMedium:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
      labelSmall:     TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.5),
    ),
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        error: errorColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ),
      textTheme: _textTheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white, fontSize: 17,
          fontWeight: FontWeight.w700, letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: mediumGrey, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      tabBarTheme: TabBarThemeData(
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.2),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.white, width: 3),
          borderRadius: BorderRadius.all(Radius.circular(3)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: mediumGrey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.2),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: const Color(0xFF3B82F6),
      secondary: secondaryLight,
      tertiary: accentLight,
      error: errorColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A1628), foregroundColor: Colors.white, elevation: 0),
    cardTheme: CardThemeData(elevation: 0, color: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );

  static Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return successColor;
      case 'in_progress': return infoColor;
      case 'delayed': return errorColor;
      case 'critical': return errorColor;
      case 'high': return warningColor;
      case 'medium': return accentColor;
      case 'low': return successColor;
      default: return mediumGrey;
    }
  }

  static Color riskColor(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'critical': return errorColor;
      case 'vulnerable': case 'high': return warningColor;
      case 'secure': case 'low': return successColor;
      default: return infoColor;
    }
  }

  static IconData statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return Icons.check_circle;
      case 'in_progress': return Icons.timelapse;
      case 'delayed': return Icons.warning;
      case 'critical': return Icons.error;
      default: return Icons.radio_button_unchecked;
    }
  }
}
