import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class Logger {
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  static void error(String message, Object? error) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR DETAILS] $error');
      }
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      print('[WARN] $message');
    }
  }

  // Normalized time method (Fix #7)
  static String nowTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now().toLocal());
  }
}