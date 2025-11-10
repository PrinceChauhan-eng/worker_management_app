import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/user_provider.dart';
import '../services/image_service.dart';
import '../services/email_verification_service.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'email_verification_screen.dart';
import '../utils/logger.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _designationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _profilePhotoPath;
  String? _idProofPath;
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSessionData();
  }

  void _loadUserData() {
    Logger.info('Loading admin user data into profile screen');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    Logger.info('Current admin user in provider: ${user?.name} (ID: ${user?.id})');
    if (user != null) {
      Logger.debug('Admin user details: Email=${user.email}, Address=${user.address}, Photo=${user.profilePhoto}, Designation=${user.designation}, Phone=${user.phone}');
      _emailController.text = user.email ?? '';
      _addressController.text = user.address ?? '';
      _designationController.text = user.designation ?? '';
      _phoneController.text = user.phone;
      _profilePhotoPath = user.profilePhoto;
      _idProofPath = user.idProof;
      Logger.info('Admin profile data loaded successfully');
    } else {
        Logger.warning('No admin user found in provider');
    }
  }

  void _loadSessionData() async {
    final sessionManager = SessionManager();
    _currentSessionId = await sessionManager.getCurrentUserId();
    Logger.info('Current session ID: $_currentSessionId');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
    _designationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ImageService.pickImageFromGallery();
                if (imagePath != null) {
                  setState(() {
                    _profilePhotoPath = imagePath;
                  });
                }
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final imagePath = await ImageService.pickImageFromCamera();
                  if (imagePath != null) {
                    setState(() {
                      _profilePhotoPath = imagePath;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIdProof() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ImageService.pickImageFromGallery();
                if (imagePath != null) {
                  setState(() {
                    _idProofPath = imagePath;
                  });
                }
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final imagePath = await ImageService.pickImageFromCamera();
                  if (imagePath != null) {
                    setState(() {
                      _idProofPath = imagePath;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVerificationEmail() async {
    Logger.info('Starting email verification process for admin');
    final email = _emailController.text.trim();
    Logger.info('Admin email entered: $email');
    
    if (email.isEmpty) {
      Logger.warning('Email is empty');
      Fluttertoast.showToast(
        msg: 'Please enter an email address',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!EmailVerificationService.isValidEmail(email)) {
      Logger.warning('Email is invalid: $email');
      Fluttertoast.showToast(
        msg: 'Please enter a valid email',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Navigate to email verification screen
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser != null) {
      final emailVerified = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationScreen(
            user: currentUser,
            email: email,
          ),
        ),
      );
      
      if (emailVerified == true) {
        // Email was verified, update the UI
        _loadUserData();
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Check if email is entered but not verified
      final email = _emailController.text.trim();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser!;
      
      if (email.isNotEmpty) {
        // If email has changed or is not verified, require verification
        if (currentUser.email != email || currentUser.emailVerified != true) {
          // Email is entered but not verified, show verification first
          Fluttertoast.showToast(
            msg: 'Please verify your email before saving',
            backgroundColor: Colors.orange,
            toastLength: Toast.LENGTH_LONG,
          );
          
          // Trigger email verification automatically
          await _sendVerificationEmail();
          
          // Check if email is now verified
          // We need to get the updated user from the provider
          final updatedUserProvider = Provider.of<UserProvider>(context, listen: false);
          final updatedCurrentUser = updatedUserProvider.currentUser!;
          
          if (updatedCurrentUser.email == email && updatedCurrentUser.emailVerified == true) {
            // Email is now verified, continue with save
            await _performSaveProfile();
          }
          return;
        }
      }
      
      // No email or email already verified, proceed normally
      await _performSaveProfile();
    }
  }
  
  Future<void> _performSaveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser!;

      Logger.info('Saving admin profile...');
      Logger.debug('Profile photo path: $_profilePhotoPath');
      Logger.debug('ID proof path: $_idProofPath');
      Logger.debug('Email: ${_emailController.text.trim()}');
      Logger.debug('Address: ${_addressController.text.trim()}');
      Logger.debug('Designation: ${_designationController.text.trim()}');
      Logger.debug('Phone: ${_phoneController.text.trim()}');

      final updatedUser = currentUser.copyWith(
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        profilePhoto: _profilePhotoPath,
        idProof: _idProofPath,
        designation: _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );

      Logger.info('Calling updateUser for admin...');
      final success = await userProvider.updateUser(updatedUser);
      Logger.info('Admin update result: $success');

      setState(() {
        _isLoading = false;
        if (success) {
          _isEditing = false; // Only exit edit mode on success
        }
      });

      if (success) {
        Fluttertoast.showToast(
          msg: 'Admin profile updated successfully!',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        // Reload user data to refresh UI
        _loadUserData();
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to update admin profile. Please try again.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e) {
      Logger.error('Error saving admin profile: $e', e);
      setState(() {
        _isLoading = false;
        // Keep in edit mode so user can try again
      });
      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _viewSessionInfo() async {
    final sessionManager = SessionManager();
    final currentUserId = await sessionManager.getCurrentUserId();
    final activeSessions = await sessionManager.getActiveSessions();
    final lastLoginTime = await sessionManager.getLastLoginTime();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Current Session ID: $currentUserId',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),
              Text(
                'Active Sessions: ${activeSessions.length}',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),
              Text(
                'Last Login: ${lastLoginTime ?? "Unknown"}',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Admin Profile',
          onLeadingPressed: () => Navigator.pop(context),
        ),
        body: const Center(child: Text('No user data')),
      );
    }

    final completionPercentage = user.profileCompletionPercentage;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Profile',
        onLeadingPressed: () => Navigator.pop(context),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _viewSessionInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Completion Progress
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: completionPercentage >= 70
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : completionPercentage >= 40
                              ? [Colors.orange.shade400, Colors.orange.shade600]
                              : [Colors.red.shade400, Colors.red.shade600],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Profile Completion',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: completionPercentage / 100,
                                minHeight: 10,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$completionPercentage%',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Profile Photo Section
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profilePhotoPath != null
                          ? (kIsWeb
                              ? NetworkImage(_profilePhotoPath!)
                              : FileImage(File(_profilePhotoPath!))) as ImageProvider
                          : null,
                      child: _profilePhotoPath == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _pickProfilePhoto,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Admin Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_isEditing)
                        CustomTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number',
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        )
                      else
                        _buildInfoRow('Phone', user.phone.isNotEmpty ? user.phone : 'Not set'),
                      const SizedBox(height: 15),
                      if (_isEditing)
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        )
                      else
                        _buildInfoRow('Email', user.email ?? 'Not set'),
                      const SizedBox(height: 15),
                      if (_isEditing)
                        CustomTextField(
                          controller: _designationController,
                          labelText: 'Designation',
                          prefixIcon: Icons.work,
                        )
                      else
                        _buildInfoRow('Designation', user.designation ?? 'Not set'),
                      const SizedBox(height: 15),
                      if (_isEditing)
                        CustomTextField(
                          controller: _addressController,
                          labelText: 'Address',
                          prefixIcon: Icons.location_on,
                          maxLines: 3,
                        )
                      else
                        _buildInfoRow('Address', user.address ?? 'Not set', maxLines: 3),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ID Proof Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Proof',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_idProofPath != null)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: kIsWeb
                              ? Image.network(_idProofPath!, fit: BoxFit.contain)
                              : Image.file(File(_idProofPath!), fit: BoxFit.contain),
                        )
                      else
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.grey[100],
                          ),
                          child: const Icon(
                            Icons.insert_drive_file,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 15),
                      if (_isEditing)
                        Center(
                          child: CustomButton(
                            text: _idProofPath == null ? 'Upload ID Proof' : 'Change ID Proof',
                            onPressed: _pickIdProof,
                            width: 200,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Session Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Information',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildInfoRow('Current Session ID', _currentSessionId?.toString() ?? 'Unknown'),
                      const SizedBox(height: 10),
                      FutureBuilder<List<Session>>(
                        future: SessionManager().getActiveSessions(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _buildInfoRow('Active Sessions', '${snapshot.data!.length}');
                          } else {
                            return _buildInfoRow('Active Sessions', 'Loading...');
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<String?>(
                        future: SessionManager().getLastLoginTime(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return _buildInfoRow('Last Login', snapshot.data ?? 'Unknown');
                          } else {
                            return _buildInfoRow('Last Login', 'Loading...');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _loadUserData(); // Reset form fields
                            });
                          },
                          color: Colors.grey[300],
                          textColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: CustomButton(
                          text: _isLoading ? 'Saving...' : 'Save Profile',
                          onPressed: _isLoading ? () {} : () async {
                            await _saveProfile();
                          },
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: maxLines,
          overflow: maxLines > 1 ? TextOverflow.ellipsis : null,
        ),
      ],
    );
  }
}