import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/session_manager.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';
import '../services/whatsapp_service.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';
import 'email_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _wageController = TextEditingController();
  final _designationController = TextEditingController();

  String _joinDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _selectedRole = 'worker';
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;
  bool _isPhoneVerified = false;

  bool _isEmailValid = false;
  bool _isEmailChecking = false;
  bool _isEmailDuplicate = false;
  Timer? _emailDebounceTimer;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _wageController.dispose();
    _designationController.dispose();
    _emailDebounceTimer?.cancel();
    super.dispose();
  }

  // EMAIL VALIDATION
  void _onEmailChanged(String value) {
    _emailDebounceTimer?.cancel();

    setState(() {
      _isEmailValid = false;
      _isEmailChecking = false;
      _isEmailDuplicate = false;
    });

    if (value.isEmpty) return;

    final emailValidation = Validators.validateEmail(value);
    if (emailValidation != null) {
      setState(() => _isEmailValid = false);
      return;
    }

    setState(() => _isEmailChecking = true);

    _emailDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkEmailAvailability(value);
    });
  }

  Future<void> _checkEmailAvailability(String email) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = userProvider.workers;

      bool isDuplicate = users.any(
        (user) => (user.email ?? '').toLowerCase() == email.toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _isEmailChecking = false;
          _isEmailValid = !isDuplicate;
          _isEmailDuplicate = isDuplicate;
        });
      }
    } catch (e) {
      setState(() {
        _isEmailChecking = false;
        _isEmailValid = false;
      });
    }
  }

  Widget _emailValidationIcon() {
    if (_emailController.text.isEmpty) return const SizedBox.shrink();

    if (_isEmailChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.blue)),
      );
    }

    if (_isEmailDuplicate) {
      return const Icon(Icons.error, color: Colors.red, size: 20);
    }

    if (_isEmailValid) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }

    return const Icon(Icons.warning, color: Colors.orange, size: 20);
  }

  // SELECT DATE
  _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _joinDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  // SEND OTP
  Future<void> _sendOTP() async {
    final phoneValidation =
        Validators.validatePhoneNumber(_phoneController.text);
    if (phoneValidation != null) {
      Fluttertoast.showToast(msg: phoneValidation, backgroundColor: Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = WhatsAppService();
      final success =
          await service.sendOTP(_phoneController.text.trim(), context);

      setState(() => _isLoading = false);

      if (success) {
        await _showOTPDialog();
      } else {
        Fluttertoast.showToast(msg: 'Failed to send OTP', backgroundColor: Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: 'OTP Error: $e', backgroundColor: Colors.red);
    }
  }

  // OTP DIALOG
  Future<void> _showOTPDialog() async {
    final otpController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text('Verify Phone', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the OTP sent to your phone', style: GoogleFonts.poppins()),
              const SizedBox(height: 20),
              CustomTextField(
                controller: otpController,
                labelText: 'OTP',
                hintText: '6-digit code',
                prefixIcon: Icons.lock,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                final service = WhatsAppService();
                final valid = service.verifyOTP(
                    _phoneController.text.trim(), otpController.text.trim());

                if (valid) {
                  setState(() => _isPhoneVerified = true);
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                      msg: 'Phone Verified!',
                      backgroundColor: Colors.green);
                } else {
                  Fluttertoast.showToast(
                      msg: 'Invalid OTP', backgroundColor: Colors.red);
                }
              },
              child: Text('Verify', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // REGISTER USER
  _registerWorker() async {
    if (!_isPhoneVerified) {
      Fluttertoast.showToast(
          msg: 'Verify phone first', backgroundColor: Colors.orange);
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        Fluttertoast.showToast(msg: 'Passwords do not match');
        return;
      }

      setState(() => _isLoading = true);

      try {
        final provider = Provider.of<UserProvider>(context, listen: false);
        await provider.loadWorkers();

        final cleanPhone =
            Validators.cleanPhoneNumber(_phoneController.text.trim());

        final user = User(
          name: _nameController.text.trim(),
          phone: cleanPhone,
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          wage: double.tryParse(_wageController.text) ?? 0.0,
          joinDate: _joinDate,
        );

        final success = await provider.addUser(user);

        setState(() => _isLoading = false);

        if (success) {
          Fluttertoast.showToast(msg: 'Registered Successfully!', backgroundColor: Colors.green);

          final authUser = await provider.authenticateUser(
            cleanPhone,
            _passwordController.text.trim(),
          );

          if (authUser != null) {
            if (_emailController.text.trim().isNotEmpty) {
              final verified = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmailVerificationScreen(
                    user: authUser,
                    email: _emailController.text.trim(),
                  ),
                ),
              );

              if (verified == true) {
                final updated = authUser.copyWith(
                  email: _emailController.text.trim(),
                  emailVerified: true,
                );
                await provider.updateUser(updated);
              }
            }

            final session = SessionManager();
            await session.setLoginSession(authUser.id!, authUser.role);

            provider.setCurrentUser(authUser);

            if (authUser.role == 'admin') {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen()));
            } else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WorkerDashboardScreen()));
            }
          }
        } else {
          Fluttertoast.showToast(msg: 'Registration Failed', backgroundColor: Colors.red);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: 'Error: $e', backgroundColor: Colors.red);
      }
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Create Account',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Account',
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E88E5))),
                const SizedBox(height: 10),
                Text('Please fill all details',
                    style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 30),

                // ROLE SELECTOR
                Text('Select Role',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = 'worker'),
                          child: _roleButton(
                              'Worker', _selectedRole == 'worker'),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = 'admin'),
                          child: _roleButton('Admin', _selectedRole == 'admin'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        labelText: 'Full Name',
                        hintText: 'Enter full name',
                        prefixIcon: Icons.person,
                        validator: Validators.validateName,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _phoneController,
                              labelText: 'Phone Number',
                              hintText: '10-digit number',
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              enabled: !_isPhoneVerified,
                              validator: Validators.validatePhoneNumber,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _isPhoneVerified ? null : _sendOTP,
                            icon: Icon(
                                _isPhoneVerified
                                    ? Icons.check_circle
                                    : Icons.verified_user,
                                size: 18),
                            label: Text(
                                _isPhoneVerified ? 'Verified' : 'Verify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isPhoneVerified
                                  ? Colors.green
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'Enter email',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                        onChanged: _onEmailChanged,
                        suffixIcon: _emailValidationIcon(),
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _designationController,
                        labelText: 'Designation',
                        prefixIcon: Icons.work,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter designation' : null,
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _wageController,
                        labelText: 'Daily Wage',
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter wage' : null,
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: CustomTextField(
                            labelText: 'Joining Date',
                            prefixIcon: Icons.calendar_today,
                            controller:
                                TextEditingController(text: _joinDate),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Select date' : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock,
                        obscureText: _isObscure,
                        suffixIcon: IconButton(
                          icon: Icon(_isObscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _isObscure = !_isObscure),
                        ),
                        validator: Validators.validatePassword,
                      ),

                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        prefixIcon: Icons.lock,
                        obscureText: _isConfirmObscure,
                        suffixIcon: IconButton(
                          icon: Icon(_isConfirmObscure
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _isConfirmObscure = !_isConfirmObscure),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Confirm password';
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      CustomButton(
                        text:
                            "Register ${_selectedRole == 'admin' ? 'Admin' : 'Worker'}",
                        onPressed: _registerWorker,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E88E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: active ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
