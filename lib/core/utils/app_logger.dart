import 'package:flutter/foundation.dart';

/// Simple logger utility for the app
/// Only logs in debug mode to avoid production logs
class AppLogger {
  static const String _prefix = '🔷 TurnoTrack';

  /// Log info message
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ℹ️ $tagStr $message');
    }
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix ❌ $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  /// Log warning message
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ⚠️ $tagStr $message');
    }
  }

  /// Log debug message
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix 🐛 $tagStr $message');
    }
  }

  /// Log success message
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix ✅ $tagStr $message');
    }
  }
}
