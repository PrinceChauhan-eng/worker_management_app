import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/email_verification_service.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.user,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  String _otpCode = '';
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _generateAndSendOTP();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _generateAndSendOTP() async {
    setState(() {
      _otpCode = EmailVerificationService.generateOTP();
      _isResending = true;
    });

    try {
      final success = await EmailVerificationService.sendVerificationEmail(
        widget.email,
        _otpCode,
        context,
      );

      Fluttertoast.showToast(
        msg: success
            ? 'Verification code sent to ${widget.email}'
            : 'Failed to send verification code',
        backgroundColor: success ? Colors.green : Colors.red,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error sending verification code: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isResending = false;
        _resendCountdown = 30;
      });

      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _resendCountdown--;
        });

        if (_resendCountdown <= 0) {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _verifyEmail() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      Fluttertoast.showToast(
        msg: 'Please enter a 6-digit verification code',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      if (EmailVerificationService.verifyOTP(_otpController.text, _otpCode)) {
        final userProvider =
            Provider.of<UserProvider>(context, listen: false);

        final updatedUser = widget.user.copyWith(
          email: widget.email,
          emailVerified: true,
        );

        final success = await userProvider.updateUser(updatedUser);

        Fluttertoast.showToast(
          msg: success
              ? 'Email verified successfully!'
              : 'Failed to update email verification status',
          backgroundColor: success ? Colors.green : Colors.red,
        );

        if (success && mounted) {
          Navigator.pop(context, true);
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Invalid verification code. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error verifying email: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verify Email',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Verification',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please verify your email address to complete registration',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 10),
                        Text(
                          'Verification Email Sent',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.email,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Please check your inbox for the verification code.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                'Enter Verification Code',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF1E88E5),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Verify Email',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code?",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  TextButton(
                    onPressed: _resendCountdown > 0 || _isResending
                        ? null
                        : _generateAndSendOTP,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : Text(
                            _resendCountdown > 0
                                ? 'Resend in $_resendCountdown sec'
                                : 'Resend Code',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _resendCountdown > 0
                                  ? Colors.grey
                                  : const Color(0xFF1E88E5),
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
