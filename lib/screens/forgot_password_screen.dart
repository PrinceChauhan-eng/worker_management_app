import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';
import '../services/database_helper.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _showOtpField = false;
  String? _generatedOtp;
  int? _userId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.initDB();
        
        // Clean phone number
        String cleanPhone = Validators.cleanPhoneNumber(_phoneController.text.trim());
        
        // Check if user exists
        final user = await dbHelper.getUserByPhoneAndPassword(cleanPhone, '');
        
        if (user != null) {
          // Generate 6-digit OTP
          final otp = _generateOTP();
          _generatedOtp = otp;
          _userId = user.id;
          
          // In real app, send OTP via SMS
          // For demo, show in toast
          Fluttertoast.showToast(
            msg: 'OTP sent to your phone! (Demo: $otp)',
            backgroundColor: Colors.blue,
            toastLength: Toast.LENGTH_LONG,
          );
          
          setState(() {
            _showOtpField = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          
          Fluttertoast.showToast(
            msg: 'No account found with this phone number',
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        Fluttertoast.showToast(
          msg: 'Error sending OTP. Please try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  String _generateOTP() {
    // Generate 6-digit random OTP
    final random = (DateTime.now().millisecondsSinceEpoch % 1000000);
    return (100000 + (random % 900000)).toString();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim() == _generatedOtp) {
      // OTP verified, navigate to reset password
      Fluttertoast.showToast(
        msg: 'OTP verified successfully!',
        backgroundColor: Colors.green,
      );
      
      // Navigate to reset password screen (would be implemented separately)
      Navigator.pop(context); // For now, just go back to login
    } else {
      Fluttertoast.showToast(
        msg: 'Invalid OTP. Please try again.',
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Text(
                'Reset Your Password',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter your phone number to receive OTP',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: 'Enter your registered phone number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhoneNumber,
              ),
              
              if (!_showOtpField) ...[
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Send OTP',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                ),
              ],
              
              if (_showOtpField) ...[
                const SizedBox(height: 20),
                Text(
                  'Enter the 6-digit OTP sent to your phone',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _otpController,
                  labelText: 'OTP',
                  hintText: 'Enter 6-digit code',
                  prefixIcon: Icons.lock,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter OTP';
                    }
                    if (value.length != 6) {
                      return 'OTP must be 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Verify OTP',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),
              ],
              
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
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