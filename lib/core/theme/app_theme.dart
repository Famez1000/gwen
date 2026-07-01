import 'package:flutter/material.dart';

class AppTheme {
  // Theme Index 0: Forest (Sage Green Light Mode)
  static const Color forestPrimary = Color(0xFF5F8474);
  static const Color forestBg = Color(0xFFFAF8F5);
  static const Color forestText = Color(0xFF2C3330);

  // Theme Index 1: Lavendel (Calm Blue / Soft Teal Light Mode)
  static const Color lavendelPrimary = Color(0xFF6FA8DC);      // Calm Blue
  static const Color lavendelSecondary = Color(0xFF7FC8B2);    // Soft Teal
  static const Color lavendelBg = Color(0xFFF5F7F4);           // Warm Cloud
  static const Color lavendelText = Color(0xFF3E4A59);         // Deep Slate
  static const Color lavendelAccent = Color(0xFFC9C3E6);       // Mist Lavender

  // Theme Index 2: Dark (Quiet & Cozy Dark Mode)
  static const Color darkBg = Color(0xFF1F2933);               // Dark Background
  static const Color darkSurface = Color(0xFF2B3642);          // Dark Surface
  static const Color darkPrimary = Color(0xFF7EB7EA);          // Dark Calm Blue
  static const Color darkSecondary = Color(0xFF8FD8C0);        // Dark Soft Mint
  static const Color darkText = Color(0xFFE7EDF3);             // Dark Text

  // Supporting Colors (Common)
  static const Color successColor = Color(0xFFA8D5BA);         // Gentle Success
  static const Color attentionColor = Color(0xFFE7C9A9);       // Soft Attention
  static const Color softShadowColor = Color(0x1428323C);      // Soft Shadow (8% opacity)

  // Calming Gradients
  static const LinearGradient primaryBreathingGradient = LinearGradient(
    colors: [Color(0xFF6FA8DC), Color(0xFF7FC8B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient reflectionGradient = LinearGradient(
    colors: [Color(0xFFC9C3E6), Color(0xFFF5F7F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient panicRecoveryGradient = LinearGradient(
    colors: [Color(0xFF89B6E5), Color(0xFFDCEFE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fallback gradients matching old names to maintain compatibility
  static const LinearGradient breezeGradient = primaryBreathingGradient;
  static const LinearGradient sageGradient = primaryBreathingGradient;
  static const LinearGradient sunsetGradient = reflectionGradient;
  static const LinearGradient darkCalmGradient = panicRecoveryGradient;
  static const LinearGradient pulseGradient = primaryBreathingGradient;

  static List<BoxShadow> softShadow(BuildContext context) {
    return const [
      BoxShadow(
        color: softShadowColor,
        blurRadius: 16,
        spreadRadius: 2,
        offset: Offset(0, 8),
      ),
    ];
  }

  // Retrieve theme dynamically based on index selection
  static ThemeData getThemeForIndex(int index) {
    switch (index) {
      case 0:
        return forestTheme;
      case 1:
        return lavendelTheme;
      case 2:
      default:
        return darkTheme;
    }
  }

  // 1. Forest Theme (Index 0)
  static ThemeData get forestTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: forestBg,
      primaryColor: forestPrimary,
      colorScheme: const ColorScheme.light(
        primary: forestPrimary,
        secondary: Color(0xFF6B82A1),
        tertiary: Color(0xFF8B85A8),
        background: forestBg,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: forestText,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: forestText,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: forestText,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: forestText,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: forestText,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF55605B),
          height: 1.4,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: forestPrimary,
        inactiveTrackColor: Color(0xFFE0DFDD),
        thumbColor: forestPrimary,
        valueIndicatorColor: forestPrimary,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }

  // 2. Lavendel Theme (Index 1)
  static ThemeData get lavendelTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lavendelBg,
      primaryColor: lavendelPrimary,
      colorScheme: const ColorScheme.light(
        primary: lavendelPrimary,
        secondary: lavendelSecondary,
        tertiary: lavendelAccent,
        background: lavendelBg,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lavendelText,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: lavendelText,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: lavendelText,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lavendelText,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lavendelText,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF677381),
          height: 1.4,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: lavendelPrimary,
        inactiveTrackColor: Color(0xFFE2E6E5),
        thumbColor: lavendelPrimary,
        valueIndicatorColor: lavendelPrimary,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }

  // 3. Cozy Dark Theme (Index 2)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        tertiary: Color(0xFFA5A0BF),
        background: darkBg,
        surface: darkSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: darkText,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: darkText,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkText,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF9FB2A9),
          height: 1.4,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: darkPrimary,
        inactiveTrackColor: Color(0xFF181D2B),
        thumbColor: darkPrimary,
        valueIndicatorColor: darkPrimary,
      ),
      cardTheme: CardThemeData(
        color: darkSurface.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.5),
        ),
      ),
    );
  }
}
