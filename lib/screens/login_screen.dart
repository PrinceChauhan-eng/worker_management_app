import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../services/session_manager.dart';
import '../services/database_helper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/validators.dart';
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
        'ip_address': '127.0.0.1',
        'user_agent': kIsWeb ? 'Web Browser' : 'Mobile App',
        'success': user != null ? 1 : 0,
        'failure_reason': user != null ? null : 'Invalid credentials',
      };

      await dbHelper.insertLoginHistory(loginHistory);
    } catch (e) {
      print('Error tracking login attempt: $e');
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  _login() async {
    try {
      if (_formKey.currentState!.validate()) {
        setState(() => _isLoading = true);

        final userProvider = Provider.of<UserProvider>(context, listen: false);

        String cleanInput = _loginMethod == 'phone'
            ? Validators.cleanPhoneNumber(_phoneController.text.trim())
            : _phoneController.text.trim();

        final user = await userProvider.authenticateUser(
          cleanInput,
          _passwordController.text.trim(),
        );

        await _trackLoginAttempt(user, cleanInput);
        setState(() => _isLoading = false);

        if (user != null && user.role == _selectedRole) {
          final sessionManager = SessionManager();
          final dbHelper = DatabaseHelper();

          await dbHelper.initDB();
          await sessionManager.setLoginSession(user.id!, user.role);

          if (_rememberMe) {
            await sessionManager.setRememberMe(_phoneController.text.trim());
          } else {
            await sessionManager.clearRememberMe();
          }

          userProvider.setCurrentUser(user);

          final notificationProvider =
              Provider.of<NotificationProvider>(context, listen: false);
          await notificationProvider.loadNotifications(
              user.id!, user.role);

          if (user.role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Invalid credentials or role mismatch',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: 'An error occurred. Please try again.',
        backgroundColor: Colors.red,
      );
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
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF0D47A1),
              ],
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
                          color: Colors.black.withOpacity(0.2),
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
                          color: Colors.black.withOpacity(0.15),
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
                                  icon: Icon(_isObscure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                                validator: Validators.validatePassword,
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
                color: _selectedRole == role
                    ? Colors.white
                    : Colors.grey[700],
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
                color: _loginMethod == method
                    ? Colors.white
                    : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
