import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../services/session_manager.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;
  String _selectedRole = 'admin'; // Default role

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  _login() async {
    print('Login button pressed');
    try {
      if (_formKey.currentState!.validate()) {
        print('Form validation passed');
        setState(() {
          _isLoading = true;
        });

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        print('Attempting to authenticate user with phone: ${_phoneController.text.trim()} and password: ${_passwordController.text.trim()}');
        print('Selected role: $_selectedRole');
        
        // Add some debug information
        print('Current user provider state:');
        print('  Workers count: ${userProvider.workers.length}');
        print('  Current user: ${userProvider.currentUser}');
        
        final user = await userProvider.authenticateUser(
          _phoneController.text.trim(),
          _passwordController.text.trim(),
        );
        print('Authentication completed. Result: ${user != null ? "SUCCESS" : "FAILED"}');

        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          print('User authenticated. User role: ${user.role}, Selected role: $_selectedRole');
          if (user.role == _selectedRole) {
            print('User authenticated successfully. Role: ${user.role}, Selected role: $_selectedRole');
            try {
              // Save session
              SessionManager sessionManager = SessionManager();
              print('Saving session for user ID: ${user.id}, role: ${user.role}');
              await sessionManager.setLoginSession(user.id!, user.role);
              print('Session saved successfully');

              // Set current user in provider
              print('Setting current user in provider');
              userProvider.setCurrentUser(user);
              print('Current user set in provider');

              // Navigate to appropriate dashboard
              if (user.role == 'admin') {
                print('Navigating to Admin Dashboard');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                );
              } else {
                print('Navigating to Worker Dashboard');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
                );
              }
            } catch (e, stackTrace) {
              print('Error saving session or navigating: $e');
              print('Stack trace: $stackTrace');
              Fluttertoast.showToast(
                msg: 'Error occurred during login. Please try again.',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
            }
          } else {
            print('Role mismatch. User role: ${user.role}, Selected role: $_selectedRole');
            Fluttertoast.showToast(
              msg: 'Invalid credentials or role mismatch',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        } else {
          print('Authentication failed. User is null.');
          Fluttertoast.showToast(
            msg: 'Invalid credentials or role mismatch',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      } else {
        print('Form validation failed');
      }
    } catch (e, stackTrace) {
      print('Error during login process: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // App Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.work,
                  size: 60,
                  color: Color(0xFF1E88E5), // Royal Blue
                ),
              ),
              const SizedBox(height: 30),
              // App Title
              Text(
                'Worker Management',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5), // Royal Blue
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Login to your account',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // Role Selector
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          print('Admin role selected');
                          setState(() {
                            _selectedRole = 'admin';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'admin'
                                ? const Color(0xFF1E88E5) // Royal Blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Admin',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _selectedRole == 'admin'
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          print('Worker role selected');
                          setState(() {
                            _selectedRole = 'worker';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'worker'
                                ? const Color(0xFF1E88E5) // Royal Blue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Worker',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _selectedRole == 'worker'
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icons.lock,
                      obscureText: _isObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
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
                    const SizedBox(height: 30),
                    CustomButton(
                      text: 'Login',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Sign Up Option (only for workers)
              if (_selectedRole == 'worker')
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                        );
                      },
                      child: Text(
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5), // Royal Blue
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              // Footer
              Text(
                'Managed by Worker Management System',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}