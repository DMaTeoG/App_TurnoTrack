import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Palette basada en azul profundo y acentos amigables
  static const Color primary = Color(0xFF0B63FF);
  static const Color primaryVariant = Color(0xFF074ED1);
  static const Color accent = Color(0xFFFFA726);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger = Color(0xFFC62828);

  static ThemeData buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: Colors.grey.shade900,
      displayColor: Colors.grey.shade900,
    );

    return base.copyWith(
      // Add custom gradients and color scales in extensions through theme
      extensions: <ThemeExtension<dynamic>>[
        AppGradients(
          primaryGradient: LinearGradient(
            colors: [primary, primaryVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentGradient: LinearGradient(
            colors: [accent.withOpacity(0.9), accent.withOpacity(0.6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ],
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
      ),
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade900,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary.withOpacity(0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// Simple ThemeExtension to expose gradients via Theme.of(context).extension<_AppGradients>()
class AppGradients extends ThemeExtension<AppGradients> {
  const AppGradients({
    required this.primaryGradient,
    required this.accentGradient,
  });

  final Gradient primaryGradient;
  final Gradient accentGradient;

  @override
  AppGradients copyWith({Gradient? primaryGradient, Gradient? accentGradient}) {
    return AppGradients(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      accentGradient: accentGradient ?? this.accentGradient,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    // Gradients are not trivially lerpable; return either end depending on t
    return t < 0.5 ? this : other;
  }
}
