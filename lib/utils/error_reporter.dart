import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'logger.dart';

class ErrorReporter {
  static void reportError(Object error, StackTrace stackTrace, {String? context}) {
    final errorInfo = '''
=== ERROR REPORT ===
Context: ${context ?? 'Unknown'}
Error Type: ${error.runtimeType}
Error Message: $error
Stack Trace: $stackTrace
Timestamp: ${DateTime.now()}
===================
''';
    
    // Log to console
    Logger.error(errorInfo, error);
    
    // Show user-friendly message
    if (!kDebugMode) {
      // In release mode, show a generic message
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
      );
    } else {
      // In debug mode, show more details
      Fluttertoast.showToast(
        msg: 'Error: ${error.toString().substring(0, 50)}...',
        backgroundColor: Colors.red,
      );
    }
  }
  
  static String getErrorMessage(Object error) {
    String message = error.toString();
    
    // Provide more user-friendly error messages
    if (message.contains('database')) {
      return 'Database error. Please restart the application.';
    } else if (message.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (message.contains('password')) {
      return 'Password verification failed. Please try again.';
    } else if (message.contains('null')) {
      return 'Data error. Please try again.';
    } else if (message.contains('format')) {
      return 'Data format error. Please try again.';
    }
    
    return 'An error occurred. Please try again.';
  }
}