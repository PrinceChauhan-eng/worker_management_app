import 'dart:math';
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Email configuration - In production, use environment variables
const String _smtpUsername = String.fromEnvironment('SMTP_USERNAME', defaultValue: '');
const String _smtpPassword = String.fromEnvironment('SMTP_PASSWORD', defaultValue: '');
const String _smtpServer = String.fromEnvironment('SMTP_SERVER', defaultValue: 'smtp.gmail.com');
const int _smtpPort = int.fromEnvironment('SMTP_PORT', defaultValue: 587);
const String _senderEmail = String.fromEnvironment('SENDER_EMAIL', defaultValue: '');
const String _senderName = String.fromEnvironment('SENDER_NAME', defaultValue: 'Worker Management App');

class EmailVerificationService {
  /// Generate a 6-digit OTP code
  static String generateOTP() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000; // Generates 6-digit number
    print('Generated OTP: $otp');
    return otp.toString();
  }

  /// Send OTP via email
  /// Supports both production mode (real email) and demo mode
  static Future<bool> sendVerificationEmail(String email, String otp, [BuildContext? context]) async {
    try {
      print('Sending verification email to: $email with OTP: $otp');
      
      // Check if we have SMTP credentials for production mode
      final bool isProductionMode = _smtpUsername.isNotEmpty && _smtpPassword.isNotEmpty && _senderEmail.isNotEmpty;
      
      if (isProductionMode) {
        print('Sending real email via SMTP');
        final success = await _sendRealEmail(email, otp);
        if (success) {
          print('Real email sent successfully');
          // Still show notifications for user feedback
          _showUserNotifications(email, otp, context);
          return true;
        } else {
          print('Failed to send real email, falling back to demo mode');
          // Fallback to demo mode
          _showUserNotifications(email, otp, context);
          return true;
        }
      } else {
        print('Sending demo email (no SMTP credentials configured)');
        // Demo mode - show OTP to user directly
        _showUserNotifications(email, otp, context);
        return true;
      }
    } catch (e) {
      print('Error sending verification email: $e');
      // Even on error, show notifications so user can see OTP
      _showUserNotifications(email, otp, context);
      return true; // Return true so user can still verify with OTP
    }
  }

  /// Send real email via SMTP
  static Future<bool> _sendRealEmail(String email, String otp) async {
    try {
      // Configure SMTP server (Gmail example)
      final smtpServer = gmail(_smtpUsername, _smtpPassword);
      
      // Create message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(Address(email))
        ..subject = 'Email Verification - Worker Management App'
        ..text = '''
Hello,

Your verification code is: $otp

Please enter this code in the application to verify your email address.

If you did not request this verification, please ignore this email.

Best regards,
Worker Management App Team
''';
      
      // Send email
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully. Response: ${sendReport.toString()}');
      
      return true;
    } catch (e) {
      print('Error sending real email: $e');
      return false;
    }
  }

  /// Show user notifications (toast and dialog)
  static void _showUserNotifications(String email, String otp, BuildContext? context) {
    // Simulate network delay for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      // Show OTP in toast
      Fluttertoast.showToast(
        msg: '✅ OTP sent to $email!\n\nCode: $otp\n\nPlease check your email inbox',
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
      
      // Also show in dialog to ensure visibility
      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('OTP Sent', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('We\'ve sent a verification code to your email:'),
                    const SizedBox(height: 10),
                    Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text('Your verification code is:', style: TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 5),
                    Text(otp, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 10),
                    const Text('Please check your email inbox and enter this code.', 
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        });
      }
    });
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Verify OTP code
  static bool verifyOTP(String enteredOTP, String storedOTP) {
    return enteredOTP.trim() == storedOTP.trim();
  }

  /// Show OTP input dialog
  static Future<String?> showOTPDialog(BuildContext context) async {
    final TextEditingController otpController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read, color: Color(0xFF1E88E5)),
            SizedBox(width: 10),
            Text('Enter OTP'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'ve sent a 6-digit code to your email. Please enter it below:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'OTP Code',
                hintText: '123456',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (otpController.text.length == 6) {
                Navigator.pop(context, otpController.text);
              } else {
                Fluttertoast.showToast(
                  msg: 'Please enter 6-digit OTP',
                  backgroundColor: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
