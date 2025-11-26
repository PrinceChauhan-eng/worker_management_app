import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/error_reporter.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../services/session_manager.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard/worker_dashboard_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;
  String _selectedRole = 'admin';
  bool _rememberMe = false;
  String? _lastLoginTime;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
    _loadLastLoginTime();
  }

  Future<void> _loadRememberMe() async {
    try {
      final sessionManager = SessionManager();
      final remembered = await sessionManager.getRememberMe();
      if (remembered != null) {
        setState(() {
          _identifierController.text = remembered['phone'] ?? '';
          _rememberMe = true;
        });
      } else {
        // Don't pre-fill any data when there's no remembered data
        setState(() {
          _identifierController.text = '';
        });
      }
    } catch (e) {
      print('Error loading remembered data: $e');
    }
  }

  Future<void> _loadLastLoginTime() async {
    try {
      final sessionManager = SessionManager();
      final lastLogin = await sessionManager.getLastLoginTime();
      if (lastLogin != null) {
        setState(() {
          _lastLoginTime = lastLogin;
        });
      }
    } catch (e) {
      print('Error loading last login time: $e');
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper methods for validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Remove any spaces, dashes, or brackets
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return false;
    }

    // Check for valid length (10 digits for most countries, including India)
    if (cleanPhone.length < 10) {
      return false;
    }

    if (cleanPhone.length > 15) {
      return false;
    }

    // For India: Check if it starts with 6-9 (valid mobile number prefix)
    if (cleanPhone.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(cleanPhone)) {
        return false;
      }
    }

    return true;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        final identifier = _identifierController.text.trim();
        
        // Use the new auth provider for login
        final success = await authProvider.login(
          identifier: identifier,
          password: _passwordController.text,
          role: _selectedRole,
          rememberMe: _rememberMe,
        );

        if (success) {
          // Login successful
          final user = authProvider.currentUser!;
          
          // Set current user in user provider for backward compatibility
          userProvider.currentUser = user;
          
          // Show success message
          Fluttertoast.showToast(
            msg: 'Login successful! Welcome back, ${user.name}',
            backgroundColor: Colors.green,
          );

          // Navigate to appropriate dashboard
          if (user.role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
            );
          }
        } else {
          // Login failed
          final errorMessage = authProvider.errorMessage ?? 'Invalid credentials';
          
          Fluttertoast.showToast(
            msg: errorMessage,
            backgroundColor: Colors.red,
          );
        }
      } catch (e, stackTrace) {
        print('Login error: $e');
        ErrorReporter.reportError(e, stackTrace, context: 'Login Process');
        Fluttertoast.showToast(
          msg: 'Login failed. Please try again.',
          backgroundColor: Colors.red,
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E88E5), // Royal Blue
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.work,
                      size: 60,
                      color: Color(0xFF1E88E5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Worker Management',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Login to your account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Unified identifier field (phone/email/user ID)
                          CustomTextField(
                            controller: _identifierController,
                            labelText: 'Phone, Email, or User ID',
                            hintText: 'Enter phone, email, or user ID',
                            prefixIcon: Icons.person,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone, email, or user ID';
                              }
                              // Check if it's a valid phone, email, or numeric ID
                              if (!_isValidPhone(value) && 
                                  !_isValidEmail(value) && 
                                  !RegExp(r'^\d+$').hasMatch(value)) {
                                return 'Please enter a valid phone, email, or user ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Password field
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock,
                            obscureText: _isObscure,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Role selection
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'worker',
                                    child: Text('Worker'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedRole = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Remember me checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              Text(
                                'Remember me',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Login button
                          CustomButton(
                            text: 'Login',
                            onPressed: _login,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Additional options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1E88E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'User Management',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1E88E5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_lastLoginTime != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Last login: $_lastLoginTime',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              // User management information
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ℹ️ User Management Information',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '• Admins: Added via database (SQL queries)\n'
                      '• Workers: Added by admins through the application',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}