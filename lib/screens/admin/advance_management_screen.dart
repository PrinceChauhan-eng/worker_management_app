import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../models/advance.dart';
import '../../models/notification.dart';
import '../../providers/user_provider.dart';
import '../../providers/advance_provider.dart';
import '../../providers/base_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AdvanceManagementScreen extends StatefulWidget {
  const AdvanceManagementScreen({super.key});

  @override
  State<AdvanceManagementScreen> createState() => _AdvanceManagementScreenState();
}

class _AdvanceManagementScreenState extends State<AdvanceManagementScreen> {
  final _advanceFormKey = GlobalKey<FormState>();
  
  // --------- Advance form state ----------
  final _advanceAmountController = TextEditingController();
  final _advanceDateController = TextEditingController();
  final _noteController = TextEditingController(); // Add note controller
  String _advanceDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String? _selectedAdvanceWorkerId;
  String? _selectedPurpose; // Add purpose state

  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Add list of purposes
  final List<String> _purposes = ['Advance', 'Personal', 'Emergency', 'Medical', 'Other'];

  @override
  void initState() {
    super.initState();

    _advanceDateController.text = _advanceDate;

    // Initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);

      await userProvider.loadWorkers();
      await advanceProvider.loadAdvances();
    });
  }

  @override
  void dispose() {
    _advanceAmountController.dispose();
    _advanceDateController.dispose();
    _noteController.dispose(); // Add note controller disposal
    super.dispose();
  }

  // ---------------- Helpers ----------------
  String _formatCurrency(num v) => '₹${v.toStringAsFixed(2)}';

  DateTime _parseYmd(String ymd) => DateFormat('yyyy-MM-dd').parse(ymd);

  // -------------- Pickers ------------------
  Future<void> _pickAdvanceDate() async {
    final initial = _parseYmd(_advanceDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _advanceDate = DateFormat('yyyy-MM-dd').format(picked);
        _advanceDateController.text = _advanceDate;
      });
    }
  }

  // -------------- Actions ------------------
  Future<void> _addAdvance() async {
    if (!_advanceFormKey.currentState!.validate()) return;

    if (_selectedAdvanceWorkerId == null || _selectedAdvanceWorkerId!.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select a worker');
      return;
    }

    // Validate purpose selection
    if (_selectedPurpose == null || _selectedPurpose!.isEmpty) {
      Fluttertoast.showToast(msg: 'Please select a purpose');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);

    // Validate worker selection
    if (_selectedAdvanceWorkerId == null) {
      Fluttertoast.showToast(msg: 'Please select a worker');
      return;
    }
    
    final worker = userProvider.workers.firstWhere(
      (u) => u.id.toString() == _selectedAdvanceWorkerId,
      orElse: () => User(
          name: 'Unknown',
          phone: '',
          password: '',
          role: 'worker',
          wage: 0,
          joinDate: ''),
    );
    
    if (worker.id == null) {
      Fluttertoast.showToast(msg: 'Invalid worker selected');
      return;
    }

    final amount = double.tryParse(_advanceAmountController.text.trim());
    if (amount == null || amount <= 0) {
      Fluttertoast.showToast(msg: 'Enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if current user is admin to auto-approve advances
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final isAdmin = userProvider.currentUser?.role == 'admin';
      
      final advance = Advance(
        workerId: worker.id!,
        amount: amount,
        date: _advanceDate,
        purpose: _selectedPurpose, // Add purpose
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(), // Add note
        status: isAdmin ? 'approved' : 'pending',
        approvedBy: isAdmin ? userProvider.currentUser?.id : null,
        approvedDate: isAdmin ? DateTime.now().toIso8601String() : null,
      );

      final ok = await advanceProvider.addAdvance(advance);

      if (ok) {
        Fluttertoast.showToast(msg: 'Advance added successfully!');
        _advanceAmountController.clear();
        _noteController.clear(); // Clear note field
        setState(() {
          _selectedAdvanceWorkerId = null;
          _selectedPurpose = null; // Clear purpose selection
        });
        // Refresh list
        await advanceProvider.loadAdvances();
      } else {
        Fluttertoast.showToast(msg: 'Failed to add advance. Try again.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error adding advance. Try again.');
      print('Error adding advance: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveAdvance(Advance advance, User worker) async {
    // Create updated advance with all existing properties preserved
    final updatedAdvance = Advance(
      id: advance.id,
      workerId: advance.workerId,
      amount: advance.amount,
      date: advance.date,
      purpose: advance.purpose,
      note: advance.note,
      status: 'approved',
      deductedFromSalaryId: advance.deductedFromSalaryId,
      approvedBy: Provider.of<UserProvider>(context, listen: false).currentUser?.id,
      approvedDate: DateTime.now().toIso8601String(),
    );

    final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
    bool success = await advanceProvider.updateAdvance(updatedAdvance);

    if (success) {
      try {
        // Send notification to worker
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        final notification = NotificationModel(
          title: 'Advance Approved',
          message: 'Your advance of ₹${advance.amount.toStringAsFixed(2)} has been approved',
          type: 'advance',
          userId: worker.id!,
          userRole: 'worker',
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
        );
        await notificationProvider.addNotification(notification);
      } catch (e) {
        print('Error sending notification: $e');
      }
      
      Fluttertoast.showToast(
        msg: 'Advance approved successfully!',
        backgroundColor: Colors.green,
      );
      
      // Refresh the data
      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await advanceProvider.loadAdvances();
      await userProvider.loadWorkers();
    } else {
      print('ERROR: Failed to approve advance. Check logs for details.');
      Fluttertoast.showToast(
        msg: 'Failed to approve advance',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _rejectAdvance(Advance advance, User worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Advance',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Reject ₹${advance.amount.toStringAsFixed(2)} advance for ${worker.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Create updated advance with all existing properties preserved
      final updatedAdvance = Advance(
        id: advance.id,
        workerId: advance.workerId,
        amount: advance.amount,
        date: advance.date,
        purpose: advance.purpose,
        note: advance.note,
        status: 'rejected',
        deductedFromSalaryId: advance.deductedFromSalaryId,
        approvedBy: advance.approvedBy,
        approvedDate: advance.approvedDate,
      );

      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
      bool success = await advanceProvider.updateAdvance(updatedAdvance);

      if (success) {
        Fluttertoast.showToast(
          msg: 'Advance rejected',
          backgroundColor: Colors.orange,
        );
        
        // Refresh the data
        final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await advanceProvider.loadAdvances();
        await userProvider.loadWorkers();
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to reject advance',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  void _showAdvanceDetails(Advance advance, User worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Advance Request Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Worker', worker.name),
              _buildDetailRow('Phone', worker.phone),
              _buildDetailRow('Amount', '₹${advance.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(
                DateFormat('yyyy-MM-dd').parse(advance.date))),
              _buildDetailRow('Purpose', advance.purpose ?? 'N/A'),
              if (advance.note != null && advance.note!.isNotEmpty)
                _buildDetailRow('Note', advance.note!),
              _buildDetailRow('Status', advance.status.toUpperCase()),
              if (advance.approvedDate != null)
                _buildDetailRow(
                  'Approved On',
                  DateFormat('dd MMM yyyy').format(
                    DateFormat('yyyy-MM-dd').parse(advance.approvedDate!)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceCard(Advance advance, User worker) {
    Color statusColor;
    IconData statusIcon;

    switch (advance.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions; // Filled icon
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle; // Filled icon
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel; // Filled icon
        break;
      case 'deducted':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all; // Filled icon
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info; // Filled icon
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Updated to consistent radius
      ),
      elevation: 3, // Updated elevation
      child: InkWell(
        onTap: () => _showAdvanceDetails(advance, worker),
        borderRadius: BorderRadius.circular(16), // Updated to consistent radius
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          advance.purpose ?? 'Advance',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${advance.amount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF9800), // Orange color for money values
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('dd MMM yyyy').format(
                          DateFormat('yyyy-MM-dd').parse(advance.date),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (advance.note != null && advance.note!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note, // Filled icon (changed from outlined)
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advance.note!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (advance.status == 'pending') ...[
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectAdvance(advance, worker),
                        icon: const Icon(Icons.close, size: 18), // Filled icon
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveAdvance(advance, worker),
                        icon: const Icon(Icons.check, size: 18), // Filled icon
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Advance Management", style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ 🟢 NEW ADVANCE FORM SECTION ------------------
            Text("New Advance", style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 12),

            // 👉 COPY COMPLETE FORM & BUTTONS FROM advance_new_screen HERE
            // NOTHING ELSE CHANGES
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final workers = userProvider.workers.where((u) => u.role == 'worker').toList();

                return Form(
                  key: _advanceFormKey,
                  child: Column(
                    children: [
                      // Worker dropdown by ID
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAdvanceWorkerId,
                        hint: Text('Select Worker', style: GoogleFonts.poppins()),
                        items: workers.map((w) {
                          return DropdownMenuItem(
                            value: w.id.toString(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(w.name, style: GoogleFonts.poppins()),
                                Text('₹${w.wage}/day',
                                    style: GoogleFonts.poppins(
                                        color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) => setState(() => _selectedAdvanceWorkerId = id),
                        decoration: InputDecoration(
                          labelText: 'Worker',
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12), // Updated to consistent radius
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Please select a worker' : null,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _advanceAmountController,
                        labelText: 'Amount',
                        hintText: 'Enter advance amount',
                        prefixIcon: Icons.currency_rupee, // Filled icon
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final n = double.tryParse(value.trim());
                          if (n == null || n <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Purpose Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPurpose,
                        items: _purposes
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedPurpose = v),
                        decoration: InputDecoration(
                          labelText: "Purpose",
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Please select a purpose' : null,
                      ),
                      const SizedBox(height: 12),
                      // Note field
                      TextFormField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Note (Optional)",
                          labelStyle: GoogleFonts.poppins(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickAdvanceDate,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _advanceDateController,
                            labelText: 'Date',
                            hintText: 'Select date',
                            prefixIcon: Icons.calendar_today, // Filled icon
                            validator: (value) => (value == null || value.isEmpty)
                                ? 'Please select date'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Add Advance',
                        onPressed: _addAdvance,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // ------------------ 🔵 ADVANCE HISTORY SECTION ------------------
            Text("Advance History", style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 12),

            // 👉 COPY COMPLETE LIST + EDIT/DELETE/PAGINATION
            // FROM advance_history_screen HERE
            // NO CHANGES required
            Consumer2<AdvanceProvider, UserProvider>(
              builder: (context, advanceProvider, userProvider, _) {
                if (advanceProvider.state == ViewState.busy) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Sort advances by date (newest first)
                final allAdvances = List<Advance>.from(advanceProvider.advances)
                  ..sort((a, b) => b.date.compareTo(a.date));
                
                // Paginate advances
                final totalItems = allAdvances.length;
                final totalPages = (totalItems / _itemsPerPage).ceil();
                final startIndex = _currentPage * _itemsPerPage;
                final endIndex = (startIndex + _itemsPerPage < totalItems) 
                    ? startIndex + _itemsPerPage 
                    : totalItems;
                
                final paginatedAdvances = (startIndex < totalItems) 
                    ? allAdvances.sublist(startIndex, endIndex) 
                    : <Advance>[];

                if (paginatedAdvances.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox, // Filled icon (changed from outlined)
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No advances found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedAdvances.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final advance = paginatedAdvances[index];
                        final worker = userProvider.workers.firstWhere(
                          (w) => w.id == advance.workerId,
                          orElse: () => User(
                            name: 'Unknown',
                            phone: '',
                            password: '',
                            role: 'worker',
                            wage: 0,
                            joinDate: '',
                          ),
                        );
                        return _buildAdvanceCard(advance, worker);
                      },
                    ),
                    if (totalPages > 1) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _currentPage > 0 
                                ? () => setState(() => _currentPage--) 
                                : null,
                            child: const Text('Previous'),
                          ),
                          Text(
                            'Page ${_currentPage + 1} of $totalPages',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _currentPage < totalPages - 1 
                                ? () => setState(() => _currentPage++) 
                                : null,
                            child: const Text('Next'),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}