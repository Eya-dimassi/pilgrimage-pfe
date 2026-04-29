import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF1F6F5B);
  static const Color primaryDark = Color(0xFF13483B);
  static const Color primaryLight = Color(0xFF2E8B72);
  static const Color gold = Color(0xFFC9A54C);
  static const Color goldBright = Color(0xFFDDB662);
  static const Color goldSoft = Color(0xFFFBF5E6);
  static const Color textPrimary = Color(0xFF18312A);
  static const Color textSecondary = Color(0xFF6E7C77);
  static const Color textHint = Color(0xFFA6B1AC);
  static const Color background = Color(0xFFF5F6F3);
  static const Color backgroundSoft = Color(0xFFF9FAF7);
  static const Color card = Colors.white;
  static const Color section = Color(0xFFF2F5F1);
  static const Color border = Color(0xFFE0E6E2);
  static const Color borderSoft = Color(0xFFF0F3EF);
  static const Color success = Color(0xFF3BA96A);
  static const Color successSoft = Color(0xFFE8F6EE);
  static const Color blue = Color(0xFF6B7FD7);
  static const Color blueSoft = Color(0xFFEEF0F9);
  static const Color red = Color(0xFFD33E43);
  static const Color redSoft = Color(0xFFFBE9EA);

  static const Color text = textPrimary;
  static const Color textMuted = textSecondary;
  static const Color textFaint = textHint;
  static const Color green = primaryLight;
  static const Color greenSoft = Color(0xFFEAF4EF);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double sm = 12;
  static const double m = 16;
  static const double lg = 20;
  static const double l = 24;
  static const double xl = 32;
}

class AppRadii {
  const AppRadii._();

  static const double sm = 14;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 30;
  static const double pill = 999;
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x140B241C),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> lifted = [
    BoxShadow(
      color: Color(0x1A0B241C),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
}

class AppGradients {
  const AppGradients._();

  static const LinearGradient hero = LinearGradient(
    colors: [
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.primaryLight,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroSoft = LinearGradient(
    colors: [
      Color(0xFFF4F9F6),
      Colors.white,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emergency = LinearGradient(
    colors: [
      Color(0xFFD33E43),
      Color(0xFFBE2D31),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.card,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        side: BorderSide(color: AppColors.borderSoft),
      ),
    ),
    dividerColor: AppColors.border,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      hintStyle: const TextStyle(color: AppColors.textHint),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: AppColors.background,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
        disabledForegroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: 16,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  );
}
