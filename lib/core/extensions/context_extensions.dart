import 'package:flutter/material.dart';

/// Extensions útiles para BuildContext
extension ContextExtensions on BuildContext {
  /// Acceso rápido al tema
  ThemeData get theme => Theme.of(this);

  /// Acceso rápido a textTheme
  TextTheme get textTheme => theme.textTheme;

  /// Acceso rápido a colorScheme
  ColorScheme get colors => theme.colorScheme;

  /// Tamaño de pantalla
  Size get screenSize => MediaQuery.of(this).size;

  /// Ancho de pantalla
  double get width => screenSize.width;

  /// Alto de pantalla
  double get height => screenSize.height;

  /// Mostrar SnackBar rápido
  void showSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colors.error : colors.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mostrar SnackBar de éxito
  void showSuccess(String message) {
    showSnackBar(message, isError: false);
  }

  /// Mostrar SnackBar de error
  void showError(String message) {
    showSnackBar(message, isError: true);
  }

  /// Navegar a nueva pantalla
  Future<T?> push<T>(Widget page) {
    return Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// Navegar reemplazando pantalla actual
  Future<T?> pushReplacement<T extends Object?>(Widget page) {
    return Navigator.of(
      this,
    ).pushReplacement<T, T>(MaterialPageRoute(builder: (_) => page));
  }

  /// Volver atrás
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Verificar si el teclado está visible
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;

  /// Padding inferior seguro (notch, barra de navegación)
  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  /// Padding superior seguro (notch, status bar)
  double get topPadding => MediaQuery.of(this).padding.top;
}
