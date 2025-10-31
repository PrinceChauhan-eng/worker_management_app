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
import '../services/location_service.dart';
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
  String _selectedRole = 'worker'; // Default role
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;
  bool _isPhoneVerified = false;
  final String _otpCode = '';
  
  // Email validation fields
  bool _isEmailValid = false;
  bool _isEmailChecking = false;
  bool _isEmailDuplicate = false;
  Timer? _emailDebounceTimer;
  
  // Location fields
  double? _workLocationLatitude;
  double? _workLocationLongitude;
  String? _workLocationAddress;
  bool _isLocationCaptured = false;
  bool _isCapturingLocation = false;

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

  // Email validation methods
  void _onEmailChanged(String value) {
    // Cancel previous timer
    _emailDebounceTimer?.cancel();
    
    // Reset validation states
    setState(() {
      _isEmailValid = false;
      _isEmailChecking = false;
      _isEmailDuplicate = false;
    });
    
    // If email is empty, do nothing
    if (value.isEmpty) return;
    
    // Validate email format first
    final emailValidation = Validators.validateEmail(value);
    if (emailValidation != null) {
      setState(() {
        _isEmailValid = false;
      });
      return;
    }
    
    // Set checking state
    setState(() {
      _isEmailChecking = true;
    });
    
    // Start debounce timer
    _emailDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _checkEmailAvailability(value);
    });
  }

  Future<void> _checkEmailAvailability(String email) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Check if email already exists in database
      final users = userProvider.workers;
      bool isDuplicate = users.any((user) => user.email?.toLowerCase() == email.toLowerCase());
      
      if (mounted) {
        setState(() {
          _isEmailChecking = false;
          _isEmailValid = !isDuplicate;
          _isEmailDuplicate = isDuplicate;
        });
      }
    } catch (e) {
      print('Error checking email availability: $e');
      if (mounted) {
        setState(() {
          _isEmailChecking = false;
          _isEmailValid = false;
        });
      }
    }
  }

  Widget _emailValidationIcon() {
    if (_emailController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    
    if (_isEmailChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }
    
    if (_isEmailDuplicate) {
      return const Icon(
        Icons.error,
        color: Colors.red,
        size: 20,
      );
    }
    
    if (_isEmailValid) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 20,
      );
    }
    
    return const Icon(
      Icons.warning,
      color: Colors.orange,
      size: 20,
    );
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _joinDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _sendOTP() async {
    // Validate phone number first
    final phoneValidation = Validators.validatePhoneNumber(_phoneController.text);
    if (phoneValidation != null) {
      Fluttertoast.showToast(
        msg: phoneValidation,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final whatsappService = WhatsAppService();
      final success = await whatsappService.sendOTP(
        _phoneController.text.trim(),
        context,
      );

      if (success) {
        // Show OTP input dialog
        if (mounted) {
          _showOTPDialog();
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to send OTP. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print('Error sending OTP: $e');
      Fluttertoast.showToast(
        msg: 'Error sending OTP: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOTPDialog() {
    final otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Color(0xFF1E88E5)),
            const SizedBox(width: 10),
            Text(
              'Enter OTP',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 6-digit OTP sent to your WhatsApp',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF1E88E5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final whatsappService = WhatsAppService();
              final isValid = whatsappService.verifyOTP(
                _phoneController.text.trim(),
                otpController.text.trim(),
              );

              if (isValid) {
                setState(() {
                  _isPhoneVerified = true;
                });
                Navigator.pop(context);
                Fluttertoast.showToast(
                  msg: '✓ Phone number verified successfully!',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                );
              } else {
                Fluttertoast.showToast(
                  msg: 'Invalid OTP. Please try again.',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
            ),
            child: Text(
              'Verify',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isCapturingLocation = true;
    });

    try {
      // Get current position
      final position = await LocationService.getCurrentLocation();
      
      if (position == null) {
        Fluttertoast.showToast(
          msg: 'Unable to get location. Please enable location services.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
        setState(() {
          _isCapturingLocation = false;
        });
        return;
      }

      // Get address from coordinates
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _workLocationLatitude = position.latitude;
        _workLocationLongitude = position.longitude;
        _workLocationAddress = address;
        _isLocationCaptured = true;
        _isCapturingLocation = false;
      });

      Fluttertoast.showToast(
        msg: '✓ Work location captured successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      print('Error capturing location: $e');
      Fluttertoast.showToast(
        msg: 'Error capturing location: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      setState(() {
        _isCapturingLocation = false;
      });
    }
  }

  _registerWorker() async {
    print('Register user button pressed');
    
    // Check if phone is verified
    if (!_isPhoneVerified) {
      Fluttertoast.showToast(
        msg: 'Please verify your phone number first',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    // Check if location is captured for workers
    if (_selectedRole == 'worker' && !_isLocationCaptured) {
      Fluttertoast.showToast(
        msg: 'Please capture work location first',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      print('Form validation passed');
      // Check if passwords match
      if (_passwordController.text != _confirmPasswordController.text) {
        print('Passwords do not match');
        Fluttertoast.showToast(
          msg: 'Passwords do not match',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Ensure database is initialized before adding user
        print('Initializing database before user registration...');
        await userProvider.loadWorkers(); // This ensures DB is initialized
        
        // Clean phone number before saving
        String cleanPhone = Validators.cleanPhoneNumber(_phoneController.text.trim());
        
        // Create user object with selected role and location data
        final user = User(
          name: _nameController.text.trim(),
          phone: cleanPhone,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          password: _passwordController.text.trim(),
          role: _selectedRole, // Use selected role
          wage: double.tryParse(_wageController.text) ?? 0.0,
          joinDate: _joinDate,
          workLocationLatitude: _workLocationLatitude,
          workLocationLongitude: _workLocationLongitude,
          workLocationAddress: _workLocationAddress,
          locationRadius: 100.0, // Default 100 meters
        );
        
        print('Creating user: ${user.name}, phone: ${user.phone}, role: ${user.role}, wage: ${user.wage}');
        if (_selectedRole == 'worker') {
          print('Work location: ${user.workLocationLatitude}, ${user.workLocationLongitude}');
          print('Work address: ${user.workLocationAddress}');
        }

        // Add user to database
        final success = await userProvider.addUser(user);
        print('User addition result: $success');

        setState(() {
          _isLoading = false;
        });

        if (success) {
          Fluttertoast.showToast(
            msg: '${_selectedRole == 'admin' ? 'Admin' : 'Worker'} Registered Successfully!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
          );
          
          // Auto-login after successful signup
          try {
            // Authenticate the newly created user
            final authenticatedUser = await userProvider.authenticateUser(
              cleanPhone,
              _passwordController.text.trim(),
            );
            
            if (authenticatedUser != null) {
              // If user provided email, verify it
              if (_emailController.text.trim().isNotEmpty) {
                final emailVerified = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmailVerificationScreen(
                      user: authenticatedUser,
                      email: _emailController.text.trim(),
                    ),
                  ),
                );
                
                // If email verification was cancelled, ask user if they want to continue
                if (emailVerified == null) {
                  // User cancelled, continue without email verification
                  Fluttertoast.showToast(
                    msg: 'Email verification skipped',
                    backgroundColor: Colors.orange,
                  );
                }
              }
              
              // Save session for auto-login
              final sessionManager = SessionManager();
              await sessionManager.setLoginSession(authenticatedUser.id!, authenticatedUser.role);
              
              // Navigate to appropriate dashboard
              if (authenticatedUser.role == 'admin') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  (route) => false,
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
                  (route) => false,
                );
              }
            } else {
              // Fallback to login screen if auto-login fails
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          } catch (authError) {
            print('Auto-login failed: $authError');
            // Fallback to login screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Registration failed. Please try again.',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        print('Error during user registration: $e');
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Registration failed: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Account',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5), // Royal Blue
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please fill in all the details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              // Role Selector
              Text(
                'Select Role',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
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
                      hintText: 'Enter your full name',
                      prefixIcon: Icons.person,
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 20),
                    // Phone number with verify button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _phoneController,
                            labelText: 'Phone Number',
                            hintText: 'Enter 10-digit phone',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            enabled: !_isPhoneVerified,
                            validator: Validators.validatePhoneNumber,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ElevatedButton.icon(
                            onPressed: _isPhoneVerified ? null : _sendOTP,
                            icon: Icon(
                              _isPhoneVerified 
                                  ? Icons.check_circle 
                                  : Icons.verified_user,
                              size: 18,
                            ),
                            label: Text(
                              _isPhoneVerified ? 'Verified' : 'Verify',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isPhoneVerified 
                                  ? Colors.green 
                                  : const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Email with real-time validation
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      hintText: 'Enter your email address',
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
                      hintText: 'Enter your role/designation',
                      prefixIcon: Icons.work,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your designation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _wageController,
                      labelText: 'Daily Wage',
                      hintText: 'Enter your daily wage',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your daily wage';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Joining Date
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: CustomTextField(
                          labelText: 'Joining Date',
                          hintText: 'Select joining date',
                          prefixIcon: Icons.calendar_today,
                          controller: TextEditingController(text: _joinDate),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select joining date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Work Location (only for workers)
                    if (_selectedRole == 'worker') ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Work Location',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _isLocationCaptured
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isLocationCaptured
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isLocationCaptured) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Location Captured',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.grey[600],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          _workLocationAddress ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Lat: ${_workLocationLatitude?.toStringAsFixed(6)}, Lng: ${_workLocationLongitude?.toStringAsFixed(6)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_off,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Work location not captured',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'This location will be used to verify attendance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isCapturingLocation
                                        ? null
                                        : _captureLocation,
                                    icon: _isCapturingLocation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : Icon(
                                            _isLocationCaptured
                                                ? Icons.location_searching
                                                : Icons.my_location,
                                            size: 20,
                                          ),
                                    label: Text(
                                      _isCapturingLocation
                                          ? 'Capturing...'
                                          : _isLocationCaptured
                                              ? 'Re-capture Location'
                                              : 'Capture Work Location',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isLocationCaptured
                                          ? Colors.blue.shade600
                                          : const Color(0xFF1E88E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
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
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: Icons.lock,
                      obscureText: _isConfirmObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmObscure
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmObscure = !_isConfirmObscure;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    CustomButton(
                      text: 'Register ${_selectedRole == 'admin' ? 'Admin' : 'Worker'}',
                      onPressed: _registerWorker,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}