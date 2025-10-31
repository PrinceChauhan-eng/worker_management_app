import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/session_manager.dart';
import '../services/database_helper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

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
  bool _rememberMe = false; // Remember me checkbox
  String _loginMethod = 'phone'; // phone, email, or id
  String? _lastLoginTime; // Store last login time

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
          _phoneController.text = remembered['phone'] ?? '';
          _rememberMe = true;
        });
      } else {
        // Set default admin phone number
        setState(() {
          _phoneController.text = '8104246218';
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

  Future<void> _trackLoginAttempt(User? user, String input) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.initDB();
      
      final loginHistory = {
        'user_id': user?.id ?? 0,
        'user_name': user?.name ?? 'Unknown',
        'user_role': user?.role ?? 'unknown',
        'login_time': DateTime.now().millisecondsSinceEpoch,
        'ip_address': '127.0.0.1', // In a real app, you'd get the actual IP
        'user_agent': kIsWeb ? 'Web Browser' : 'Mobile App',
        'success': user != null ? 1 : 0,
        'failure_reason': user != null ? null : 'Invalid credentials',
      };
      
      await dbHelper.insertLoginHistory(loginHistory);
      print('Login attempt tracked successfully');
    } catch (e) {
      print('Error tracking login attempt: $e');
      // Don't let tracking errors affect the login process
    }
  }

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
        print('Attempting to authenticate user with $_loginMethod: ${_phoneController.text.trim()} and password: ${_passwordController.text.trim()}');
        print('Selected role: $_selectedRole');
        
        // Clean input based on login method
        String cleanInput;
        if (_loginMethod == 'phone') {
          cleanInput = Validators.cleanPhoneNumber(_phoneController.text.trim());
        } else {
          cleanInput = _phoneController.text.trim();
        }
        
        // Add some debug information
        print('Current user provider state:');
        print('  Workers count: ${userProvider.workers.length}');
        print('  Current user: ${userProvider.currentUser}');
        
        final user = await userProvider.authenticateUser(
          cleanInput,
          _passwordController.text.trim(),
        );
        print('Authentication completed. Result: ${user != null ? "SUCCESS" : "FAILED"}');

        // Track login attempt
        await _trackLoginAttempt(user, cleanInput);

        setState(() {
          _isLoading = false;
        });

        if (user != null) {
          print('User authenticated. User role: ${user.role}, Selected role: $_selectedRole');
          if (user.role == _selectedRole) {
            print('User authenticated successfully. Role: ${user.role}, Selected role: $_selectedRole');
            try {
              // Ensure database is initialized
              print('Ensuring database is initialized...');
              final dbHelper = DatabaseHelper();
              await dbHelper.initDB();
              print('Database initialized successfully');
              
              // Save session
              SessionManager sessionManager = SessionManager();
              print('Saving session for user ID: ${user.id}, role: ${user.role}');
              await sessionManager.setLoginSession(user.id!, user.role);
                            
              // Handle remember me
              if (_rememberMe) {
                await sessionManager.setRememberMe(_phoneController.text.trim());
                print('Remember me set for phone: ${_phoneController.text.trim()}');
              } else {
                await sessionManager.clearRememberMe();
                print('Remember me cleared');
              }
                            
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
                    // Phone/Email/ID selector
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
                                setState(() {
                                  _loginMethod = 'phone';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _loginMethod == 'phone'
                                      ? const Color(0xFF1E88E5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Phone',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _loginMethod == 'phone'
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
                                setState(() {
                                  _loginMethod = 'email';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _loginMethod == 'email'
                                      ? const Color(0xFF1E88E5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Email',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _loginMethod == 'email'
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
                                setState(() {
                                  _loginMethod = 'id';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _loginMethod == 'id'
                                      ? const Color(0xFF1E88E5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'ID',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _loginMethod == 'id'
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
                    const SizedBox(height: 20),
                    // Dynamic input field based on login method
                    if (_loginMethod == 'phone')
                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhoneNumber,
                      )
                    else if (_loginMethod == 'email')
                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Email Address',
                        hintText: 'Enter your email address',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email address';
                          }
                          // Basic email validation
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      )
                    else
                      CustomTextField(
                        controller: _phoneController,
                        labelText: 'Employee ID',
                        hintText: 'Enter your employee ID',
                        prefixIcon: Icons.badge,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your employee ID';
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
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 15),
                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF1E88E5),
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
                    // Last Login Time Display
                    if (_lastLoginTime != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF1E88E5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Last login: $_lastLoginTime',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Login',
                      onPressed: _login,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Sign Up Option (for both admin and worker)
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
              const SizedBox(height: 10),
              // Forgot Password
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ),
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