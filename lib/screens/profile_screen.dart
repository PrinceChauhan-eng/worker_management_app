import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/user_provider.dart';
import '../services/image_service.dart';
import '../services/email_verification_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'email_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String? _profilePhotoPath;
  String? _idProofPath;
  String? _pendingEmail; // Email waiting for verification

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    print('Loading user data into profile screen');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    print('Current user in provider: ${user?.name} (ID: ${user?.id})');
    if (user != null) {
      print('User details: Email=${user.email}, Address=${user.address}, Photo=${user.profilePhoto}');
      _emailController.text = user.email ?? '';
      _addressController.text = user.address ?? '';
      _profilePhotoPath = user.profilePhoto;
      _idProofPath = user.idProof;
      print('Profile data loaded successfully');
    } else {
      print('No user found in provider');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _addressController.dispose();
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
    print('Starting email verification process');
    final email = _emailController.text.trim();
    print('Email entered: $email');
    
    if (email.isEmpty) {
      print('Email is empty');
      Fluttertoast.showToast(
        msg: 'Please enter an email address',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!EmailVerificationService.isValidEmail(email)) {
      print('Email is invalid: $email');
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
        setState(() {
          _pendingEmail = email;
        });
        _loadUserData();
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final currentUser = userProvider.currentUser!;

        print('Saving profile...');
        print('Profile photo path: $_profilePhotoPath');
        print('ID proof path: $_idProofPath');
        print('Email: ${_emailController.text.trim()}');
        print('Address: ${_addressController.text.trim()}');

        final updatedUser = currentUser.copyWith(
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          profilePhoto: _profilePhotoPath,
          idProof: _idProofPath,
        );

        print('Calling updateUser...');
        final success = await userProvider.updateUser(updatedUser);
        print('Update result: $success');

        setState(() {
          _isLoading = false;
          if (success) {
            _isEditing = false; // Only exit edit mode on success
          }
        });

        if (success) {
          Fluttertoast.showToast(
            msg: 'Profile updated successfully!',
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_LONG,
          );
          // Reload user data to refresh UI
          _loadUserData();
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to update profile. Please try again.',
            backgroundColor: Colors.red,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      } catch (e) {
        print('Error saving profile: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Profile',
          onLeadingPressed: () => Navigator.pop(context),
        ),
        body: const Center(child: Text('No user data')),
      );
    }

    final completionPercentage = user.profileCompletionPercentage;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Profile',
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
                              backgroundColor: Colors.white.withOpacity(0.3),
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
                    backgroundColor: const Color(0xFF1E88E5),
                    backgroundImage: _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty
                        ? (kIsWeb
                            ? NetworkImage(_profilePhotoPath!)
                            : FileImage(File(_profilePhotoPath!)) as ImageProvider)
                        : null,
                    child: _profilePhotoPath == null || _profilePhotoPath!.isEmpty
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              
              // User Name & Role
              Text(
                user.name,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user.role == 'admin'
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.role == 'admin' ? Colors.red.shade700 : Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Phone (Read-only)
              _buildInfoCard(
                icon: Icons.phone,
                label: 'Phone Number',
                value: user.phone,
                isEditable: false,
              ),
              const SizedBox(height: 15),

              // Email (Editable with Verification)
              if (_isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      hintText: 'Enter your email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!EmailVerificationService.isValidEmail(value)) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    if (_emailController.text.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _sendVerificationEmail,
                        icon: Icon(
                          user.emailVerified == true && user.email == _emailController.text.trim()
                              ? Icons.verified
                              : Icons.mark_email_unread,
                          size: 18,
                        ),
                        label: Text(
                          user.emailVerified == true && user.email == _emailController.text.trim()
                              ? 'Email Verified ✓'
                              : 'Verify Email',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.emailVerified == true && user.email == _emailController.text.trim()
                              ? Colors.green
                              : const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                  ],
                )
              else
                _buildInfoCard(
                  icon: Icons.email,
                  label: 'Email',
                  value: user.email ?? 'Not provided',
                  isEditable: false,
                  isVerified: user.emailVerified == true,
                ),
              const SizedBox(height: 15),

              // Address (Editable)
              if (_isEditing)
                CustomTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  hintText: 'Enter your address',
                  prefixIcon: Icons.home,
                  maxLines: 3,
                )
              else
                _buildInfoCard(
                  icon: Icons.home,
                  label: 'Address',
                  value: user.address ?? 'Not provided',
                  isEditable: false,
                ),
              const SizedBox(height: 15),

              // Daily Wage (Read-only for workers)
              if (user.role == 'worker')
                _buildInfoCard(
                  icon: Icons.currency_rupee,
                  label: 'Daily Wage',
                  value: '₹${user.wage.toStringAsFixed(2)}',
                  isEditable: false,
                ),
              const SizedBox(height: 15),

              // Work Location
              if (user.workLocationAddress != null)
                _buildInfoCard(
                  icon: Icons.location_on,
                  label: 'Work Location',
                  value: user.workLocationAddress!,
                  isEditable: false,
                ),
              const SizedBox(height: 20),

              // ID Proof Section
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID Proof',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isEditing)
                          ElevatedButton.icon(
                            onPressed: _pickIdProof,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_idProofPath != null && _idProofPath!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _idProofPath!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_idProofPath!),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      )
                    else
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.badge, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'No ID proof uploaded',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Save/Cancel Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _loadUserData(); // Reset form
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: CustomButton(
                        text: 'Save Changes',
                        onPressed: _saveProfile,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditable,
    bool isVerified = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1E88E5)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
