import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
// Removed location_service import since we're removing location features
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class AddWorkerScreen extends StatefulWidget {
  final User? editUser;
  
  const AddWorkerScreen({super.key, this.editUser});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _wageController = TextEditingController();
  final _designationController = TextEditingController();
  final _addressController = TextEditingController();
  // Removed latitude and longitude controllers since we're removing location features
  
  String _joinDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isObscure = true;
  bool _isLoading = false;
  // Removed _isCapturingLocation since we're removing location features
  User? _editingUser;

  @override
  void initState() {
    super.initState();
    
    // If editing, populate fields with existing data
    if (widget.editUser != null) {
      _editingUser = widget.editUser;
      _nameController.text = _editingUser!.name;
      _phoneController.text = _editingUser!.phone;
      _passwordController.text = _editingUser!.password;
      _wageController.text = _editingUser!.wage.toString();
      _joinDate = _editingUser!.joinDate.split(' ')[0]; // Extract date only
      
      // Populate address if available (removed location coordinates)
      if (_editingUser!.address != null) {
        _addressController.text = _editingUser!.address!;
      }
    }
    
    // Load workers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadWorkers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _wageController.dispose();
    _designationController.dispose();
    _addressController.dispose();
    // Removed latitude and longitude controller disposal
    super.dispose();
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

  // Removed _captureCurrentLocation method since we're removing location features

  _saveWorker() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Create user object without location data
      final user = User(
        id: _editingUser?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'worker',
        wage: double.tryParse(_wageController.text) ?? 0.0,
        joinDate: _joinDate,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        designation: _designationController.text.trim().isNotEmpty 
            ? _designationController.text.trim() 
            : null, // Add designation field
      );

      bool success;
      if (_editingUser == null) {
        // Add new worker
        success = await userProvider.addUser(user);
        if (success) {
          Fluttertoast.showToast(
            msg: 'Worker added successfully!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
          );
        }
      } else {
        // Update existing worker
        success = await userProvider.updateUser(user);
        if (success) {
          Fluttertoast.showToast(
            msg: 'Worker updated successfully!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
          );
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: 'Operation failed. Please try again.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _editingUser == null ? 'Add Worker' : 'Edit Worker',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15), // Reduced from 20
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingUser == null ? 'Add New Worker' : 'Edit Worker',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5), // Royal Blue
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _editingUser == null
                    ? 'Fill in worker details'
                    : 'Update worker information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20), // Reduced from 30
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      hintText: 'Enter worker\'s full name',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter worker\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15), // Reduced from 20
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: 'Enter worker\'s phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter worker\'s phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15), // Reduced from 20
                    CustomTextField(
                      controller: _designationController,
                      labelText: 'Designation',
                      hintText: 'Enter worker\'s role/designation',
                      prefixIcon: Icons.work,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter worker\'s designation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15), // Reduced from 20
                    CustomTextField(
                      controller: _wageController,
                      labelText: 'Daily Wage',
                      hintText: 'Enter daily wage',
                      prefixIcon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter daily wage';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15), // Reduced from 20
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
                    const SizedBox(height: 15), // Reduced from 20
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: 'Set worker\'s password',
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
                          return 'Please set a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20), // Reduced from 30
                    
                    // Work Address Section (simplified)
                    Text(
                      'Work Address',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the worker\'s work address',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10), // Reduced from 15
                    
                    // Address Field
                    CustomTextField(
                      controller: _addressController,
                      labelText: 'Work Address',
                      hintText: 'Enter work location address',
                      prefixIcon: Icons.location_on,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20), // Reduced from 30
                    CustomButton(
                      text: _editingUser == null ? 'Add Worker' : 'Update Worker',
                      onPressed: _saveWorker,
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