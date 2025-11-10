import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../models/advance.dart';
import '../models/notification.dart';
import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/logger.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RequestAdvanceScreen extends StatefulWidget {
  const RequestAdvanceScreen({super.key});

  @override
  State<RequestAdvanceScreen> createState() => _RequestAdvanceScreenState();
}

class _RequestAdvanceScreenState extends State<RequestAdvanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String? _selectedPurpose;
  bool _isLoading = false;

  final List<String> _purposes = [
    'Medical',
    'Personal',
    'Emergency',
    'Family',
    'Education',
    'Transportation',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPurpose == null) {
        Fluttertoast.showToast(
          msg: 'Please select a purpose',
          backgroundColor: Colors.red,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      final advance = Advance(
        workerId: userProvider.currentUser!.id!,
        amount: double.parse(_amountController.text),
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        purpose: _selectedPurpose,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        status: 'pending',
      );

      // Force database upgrade before inserting advance
      // This is no longer needed with Supabase
      
      bool success = await advanceProvider.addAdvance(advance);

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Send notification to admin
        final adminNotification = NotificationModel(
          title: 'New Advance Request',
          message: '${userProvider.currentUser!.name} has requested an advance of ₹${_amountController.text} for $_selectedPurpose',
          type: 'advance',
          userId: 0, // Admin user ID (we'll use 0 for admin notifications)
          userRole: 'admin',
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
          relatedId: advance.id?.toString(),
        );
        
        await notificationProvider.addNotification(adminNotification);
        
        Fluttertoast.showToast(
          msg: 'Advance request submitted successfully!',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to submit advance request. Please check your network connection and try again.',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Request Advance',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request an Advance',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Fill in the details for your advance request',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // Amount Field
              CustomTextField(
                controller: _amountController,
                labelText: 'Amount',
                hintText: 'Enter advance amount',
                prefixIcon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Purpose Dropdown
              Text(
                'Purpose',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text(
                      'Select purpose',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    value: _selectedPurpose,
                    items: _purposes.map((purpose) {
                      IconData icon;
                      switch (purpose) {
                        case 'Medical':
                          icon = Icons.medical_services;
                          break;
                        case 'Emergency':
                          icon = Icons.warning_amber;
                          break;
                        case 'Family':
                          icon = Icons.family_restroom;
                          break;
                        case 'Education':
                          icon = Icons.school;
                          break;
                        case 'Transportation':
                          icon = Icons.directions_car;
                          break;
                        default:
                          icon = Icons.payment;
                      }

                      return DropdownMenuItem<String>(
                        value: purpose,
                        child: Row(
                          children: [
                            Icon(icon, size: 20, color: const Color(0xFF1E88E5)),
                            const SizedBox(width: 10),
                            Text(
                              purpose,
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPurpose = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Note Field
              CustomTextField(
                controller: _noteController,
                labelText: 'Note (Optional)',
                hintText: 'Explain why you need this advance',
                prefixIcon: Icons.note_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 10),

              // Info Card
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your request will be reviewed by admin. You will be notified once approved.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              CustomButton(
                text: 'Submit Request',
                onPressed: _submitRequest,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
