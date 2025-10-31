import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/location_service.dart';
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
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  
  String _joinDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isObscure = true;
  bool _isLoading = false;
  bool _isCapturingLocation = false;
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
      
      // Populate location if available
      if (_editingUser!.workLocationLatitude != null) {
        _latitudeController.text = _editingUser!.workLocationLatitude!.toStringAsFixed(6);
      }
      if (_editingUser!.workLocationLongitude != null) {
        _longitudeController.text = _editingUser!.workLocationLongitude!.toStringAsFixed(6);
      }
      if (_editingUser!.workLocationAddress != null) {
        _addressController.text = _editingUser!.workLocationAddress!;
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
    _latitudeController.dispose();
    _longitudeController.dispose();
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

  Future<void> _captureCurrentLocation() async {
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
        _latitudeController.text = position.latitude.toStringAsFixed(6);
        _longitudeController.text = position.longitude.toStringAsFixed(6);
        _addressController.text = address ?? '';
        _isCapturingLocation = false;
      });

      Fluttertoast.showToast(
        msg: '✓ Location captured successfully!',
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

  _saveWorker() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Parse location data
      double? latitude;
      double? longitude;
      if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
        latitude = double.tryParse(_latitudeController.text);
        longitude = double.tryParse(_longitudeController.text);
      }
      
      // Create user object with location
      final user = User(
        id: _editingUser?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'worker',
        wage: double.tryParse(_wageController.text) ?? 0.0,
        joinDate: _joinDate,
        workLocationLatitude: latitude,
        workLocationLongitude: longitude,
        workLocationAddress: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        locationRadius: 100.0, // Default 100 meters
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
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 30),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 30),
                    
                    // Work Location Section
                    Text(
                      'Work Location',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Set the worker\'s work location for attendance tracking',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // GPS Capture Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCapturingLocation ? null : _captureCurrentLocation,
                        icon: _isCapturingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.my_location, size: 20),
                        label: Text(
                          _isCapturingLocation
                              ? 'Fetching Location...'
                              : 'Fetch Current Location (GPS)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Manual Location Entry
                    Text(
                      'Or Enter Manually',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Address Field
                    CustomTextField(
                      controller: _addressController,
                      labelText: 'Work Address',
                      hintText: 'Enter work location address',
                      prefixIcon: Icons.location_on,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 15),
                    
                    // Latitude and Longitude Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _latitudeController,
                            labelText: 'Latitude',
                            hintText: 'e.g. 28.6139',
                            prefixIcon: Icons.map,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: CustomTextField(
                            controller: _longitudeController,
                            labelText: 'Longitude',
                            hintText: 'e.g. 77.2090',
                            prefixIcon: Icons.map,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Location Info
                    if (_latitudeController.text.isNotEmpty && 
                        _longitudeController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Location set: ${_latitudeController.text}, ${_longitudeController.text}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 30),
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