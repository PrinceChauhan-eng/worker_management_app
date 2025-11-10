import 'package:flutter/foundation.dart';

/// Simple logger utility to replace print statements
class Logger {
  static const bool _isDebugMode = kDebugMode;
  
  /// Log debug messages (only in debug mode)
  static void debug(String message) {
    if (_isDebugMode) {
      // In debug mode, we can still use print for development
      debugPrint('[DEBUG] $message');
    }
  }
  
  /// Log info messages
  static void info(String message) {
    if (_isDebugMode) {
      debugPrint('[INFO] $message');
    }
  }
  
  /// Log warning messages
  static void warning(String message) {
    if (_isDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }
  
  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}