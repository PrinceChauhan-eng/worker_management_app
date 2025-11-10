import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/error_reporter.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../services/session_manager.dart';
import '../services/database_helper.dart';
import '../utils/validators.dart';
import '../utils/password_utils.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';

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
  String _selectedRole = 'admin';
  bool _rememberMe = false;
  String _loginMethod = 'phone';
  String? _lastLoginTime;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
    _loadLastLoginTime();
  }

  String _getLabel() {
    switch (_loginMethod) {
      case 'email':
        return 'Email';
      case 'id':
        return 'User ID';
      default:
        return 'Phone Number';
    }
  }

  String _getHint() {
    switch (_loginMethod) {
      case 'email':
        return 'Enter your email';
      case 'id':
        return 'Enter your user ID';
      default:
        return 'Enter your phone number';
    }
  }

  IconData _getIcon() {
    switch (_loginMethod) {
      case 'email':
        return Icons.email;
      case 'id':
        return Icons.badge;
      default:
        return Icons.phone;
    }
  }

  TextInputType _getKeyboardType() {
    switch (_loginMethod) {
      case 'email':
        return TextInputType.emailAddress;
      case 'id':
        return TextInputType.number;
      default:
        return TextInputType.phone;
    }
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
        // Don't pre-fill any data when there's no remembered data
        setState(() {
          _phoneController.text = '';
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final dbHelper = DatabaseHelper();
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        User? user;

        print('Attempting login with method: $_loginMethod, role: $_selectedRole');
        
        // Authenticate user based on selected role and method
        if (_loginMethod == 'phone') {
          print('Authenticating with phone: ${_phoneController.text.trim()}');
          user = await dbHelper.getUserByPhoneAndPassword(
            _phoneController.text.trim(),
            _passwordController.text,
          );
          // Check role after authentication
          if (user != null && user.role != _selectedRole) {
            print('Role mismatch. User role: ${user.role}, Selected role: $_selectedRole');
            user = null; // Role mismatch
          }
        } else if (_loginMethod == 'email') {
          print('Authenticating with email: ${_phoneController.text.trim()}');
          // For email login, we need to search by email first, then authenticate
          var client = await dbHelper.db;
          var results = await client.query(
            'users',
            where: 'email = ? AND role = ?',
            whereArgs: [_phoneController.text.trim(), _selectedRole],
          );
          
          if (results.isNotEmpty) {
            var userData = results.first;
            var storedPassword = userData['password'] as String;
            
            // Verify password
            bool passwordMatches;
            if (PasswordUtils.isHashed(storedPassword)) {
              passwordMatches = PasswordUtils.verifyPassword(
                _passwordController.text,
                storedPassword,
              );
            } else {
              passwordMatches = _passwordController.text == storedPassword;
            }
            
            if (passwordMatches) {
              user = User.fromMap(userData);
            }
          }
        } else if (_loginMethod == 'id') {
          print('Authenticating with ID: ${_phoneController.text.trim()}');
          // For ID login, we need to search by ID first, then authenticate
          var client = await dbHelper.db;
          var results = await client.query(
            'users',
            where: 'id = ? AND role = ?',
            whereArgs: [int.tryParse(_phoneController.text.trim()) ?? 0, _selectedRole],
          );
          
          if (results.isNotEmpty) {
            var userData = results.first;
            var storedPassword = userData['password'] as String;
            
            // Verify password
            bool passwordMatches;
            if (PasswordUtils.isHashed(storedPassword)) {
              passwordMatches = PasswordUtils.verifyPassword(
                _passwordController.text,
                storedPassword,
              );
            } else {
              passwordMatches = _passwordController.text == storedPassword;
            }
            
            if (passwordMatches) {
              user = User.fromMap(userData);
            }
          }
        }

        if (user != null) {
          print('Login successful for user: ${user.name} (ID: ${user.id})');
          // Set current user in provider
          userProvider.setCurrentUser(user);

          // Add session
          final sessionManager = SessionManager();
          await sessionManager.addSession(user.id!, user.role);
          
          // Set current user ID for this tab
          await sessionManager.setCurrentUserId(user.id!);

          if (_rememberMe) {
            await sessionManager.setRememberMe(_phoneController.text.trim());
          } else {
            await sessionManager.clearRememberMe();
          }

          final notificationProvider = Provider.of<NotificationProvider>(
            context,
            listen: false,
          );
          await notificationProvider.loadNotifications(user.id!, user.role);

          // Navigate to appropriate dashboard
          if (user.role == 'admin') {
            print('Navigating to Admin Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          } else {
            print('Navigating to Worker Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
            );
          }
        } else {
          print('Login failed - Invalid credentials or role mismatch');
          Fluttertoast.showToast(
            msg: 'Invalid credentials or role mismatch',
            backgroundColor: Colors.red,
          );
          // Reset loading state on login failure
          setState(() => _isLoading = false);
        }
      } catch (e, stackTrace) {
        print('=== LOGIN ERROR ===');
        print('Error type: ${e.runtimeType}');
        print('Error message: $e');
        print('Stack trace: $stackTrace');
        print('===================');
        
        setState(() => _isLoading = false);
        
        // Use the error reporter to handle the error
        ErrorReporter.reportError(e, stackTrace, context: 'User Login');
        
        String errorMessage = ErrorReporter.getErrorMessage(e);
        
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            ),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.work,
                      size: 70,
                      color: Color(0xFF1E88E5),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Worker Management',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Login to your account',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _roleButton('admin', 'Admin'),
                              _roleButton('worker', 'Worker'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    _methodButton('phone', 'Phone'),
                                    _methodButton('email', 'Email'),
                                    _methodButton('id', 'ID'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 15),

                              CustomTextField(
                                controller: _phoneController,
                                labelText: _getLabel(),
                                hintText: _getHint(),
                                prefixIcon: _getIcon(),
                                keyboardType: _getKeyboardType(),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your ${_getLabel().toLowerCase()}';
                                  }
                                  if (_loginMethod == 'phone') {
                                    return Validators.validatePhoneNumber(v);
                                  }
                                  if (_loginMethod == 'email') {
                                    return Validators.validateEmail(v);
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 15),

                              CustomTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Icons.lock,
                                obscureText: _isObscure,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                                validator: Validators.validatePasswordForLogin,
                              ),

                              const SizedBox(height: 15),

                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v!),
                                    activeColor: const Color(0xFF1E88E5),
                                  ),
                                  Text(
                                    'Remember me',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_lastLoginTime != null)
                                    Text(
                                      'Last login: $_lastLoginTime',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              CustomButton(
                                text: 'Login',
                                onPressed: _login,
                                isLoading: _isLoading,
                                color: const Color(0xFF1E88E5),
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '© 2025 Worker Management App',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String role, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _selectedRole == role
                ? const Color(0xFF1E88E5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _selectedRole == role ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodButton(String method, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _loginMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _loginMethod == method
                ? const Color(0xFF1E88E5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _loginMethod == method ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
