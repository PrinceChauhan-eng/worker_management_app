import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/salary.dart';
import '../models/advance.dart';
import '../models/notification.dart';
import '../providers/user_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/salary_slip_dialog.dart';

class ProcessSalaryScreen extends StatefulWidget {
  const ProcessSalaryScreen({super.key});

  @override
  State<ProcessSalaryScreen> createState() => _ProcessSalaryScreenState();
}

class _ProcessSalaryScreenState extends State<ProcessSalaryScreen> {
  User? _selectedWorker;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isCalculating = false;
  bool _isLoading = false;

  // Calculation results
  int? _totalDays;
  int? _presentDays;
  int? _absentDays;
  double? _grossSalary;
  List<Advance> _approvedAdvances = [];
  double? _totalAdvance;
  double? _netSalary;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
        // Reset calculation when month changes
        _resetCalculation();
      });
    }
  }

  void _resetCalculation() {
    setState(() {
      _totalDays = null;
      _presentDays = null;
      _absentDays = null;
      _grossSalary = null;
      _approvedAdvances = [];
      _totalAdvance = null;
      _netSalary = null;
    });
  }

  Future<void> _calculateSalary() async {
    if (_selectedWorker == null) {
      Fluttertoast.showToast(
        msg: 'Please select a worker',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
      final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);

      // Load login statuses for the month
      await loginStatusProvider.loadLoginStatusesByWorkerId(_selectedWorker!.id!);
      
      // Filter for selected month
      final monthStatuses = loginStatusProvider.loginStatuses
          .where((ls) => ls.date.startsWith(_selectedMonth))
          .toList();

      // Calculate working days (days with logout recorded)
      final workingDays = monthStatuses.where((ls) => ls.logoutTime != null).length;
      
      // Get days in month
      final year = int.parse(_selectedMonth.split('-')[0]);
      final month = int.parse(_selectedMonth.split('-')[1]);
      final daysInMonth = DateTime(year, month + 1, 0).day;

      // Calculate gross salary
      final grossSalary = workingDays * _selectedWorker!.wage;

      // Load all advances for this worker
      await advanceProvider.loadAdvances();
      
      // Get approved advances for this month (not yet deducted)
      final approvedAdvances = advanceProvider.advances.where((adv) =>
        adv.workerId == _selectedWorker!.id! &&
        adv.status == 'approved' &&
        adv.date.startsWith(_selectedMonth)
      ).toList();

      // Calculate total advances
      final totalAdvance = approvedAdvances.fold<double>(
        0.0,
        (sum, adv) => sum + adv.amount,
      );

      // Calculate net salary
      final netSalary = grossSalary - totalAdvance;

      setState(() {
        _totalDays = daysInMonth;
        _presentDays = workingDays;
        _absentDays = daysInMonth - workingDays;
        _grossSalary = grossSalary;
        _approvedAdvances = approvedAdvances;
        _totalAdvance = totalAdvance;
        _netSalary = netSalary;
        _isCalculating = false;
      });

    } catch (e) {
      setState(() {
        _isCalculating = false;
      });
      Fluttertoast.showToast(
        msg: 'Error calculating salary: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _showSalaryPreview() async {
    if (_netSalary == null) {
      Fluttertoast.showToast(
        msg: 'Please calculate salary first',
        backgroundColor: Colors.red,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: true, // Make sure it expands to full screen
        initialChildSize: 0.95, // Start at 95% of screen height for better visibility
        minChildSize: 0.5, // Minimum 50% of screen height
        maxChildSize: 1.0, // Maximum 100% of screen height
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Salary Preview',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Worker Info
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedWorker!.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Month: ${DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Salary Breakdown
                  Text(
                    'Earnings',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPreviewItem('Present Days', '$_presentDays days'),
                  _buildPreviewItem('Daily Wage', '₹${_selectedWorker!.wage.toStringAsFixed(2)}'),
                  _buildPreviewItem('Gross Salary', '₹${_grossSalary!.toStringAsFixed(2)}', isBold: true),
                  
                  const SizedBox(height: 20),
                  Text(
                    'Deductions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  if (_approvedAdvances.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No advances taken this month',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else ...[
                    ..._approvedAdvances.map((adv) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adv.purpose ?? 'Advance',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (adv.note != null && adv.note!.isNotEmpty)
                                  Text(
                                    adv.note!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${adv.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Total Advances',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '₹${_totalAdvance!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Net Salary with enhanced styling
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _netSalary! >= 0
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Net Salary',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '₹${_netSalary!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_netSalary! < 0) ...[
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Negative balance of ₹${(-_netSalary!).toStringAsFixed(2)} will be carried forward to next month',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  // Action Buttons with fixed layout
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _actuallyProcessSalary();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(
                                'Process',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Preview Options Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPreviewOptions();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Color(0xFF1E88E5)),
                      ),
                      child: Text(
                        'Preview Options',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E88E5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Add some padding at the bottom
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Show preview options dialog with send and download functionality
  Future<void> _showPreviewOptions() async {
    // Create a temporary salary object for preview
    final previewSalary = Salary(
      workerId: _selectedWorker!.id!,
      month: _selectedMonth,
      year: _selectedMonth.split('-')[0],
      totalDays: _totalDays ?? 0,
      presentDays: _presentDays ?? 0,
      absentDays: _absentDays ?? 0,
      grossSalary: _grossSalary ?? 0.0,
      totalAdvance: _totalAdvance ?? 0.0,
      netSalary: _netSalary ?? 0.0,
      paid: false,
      paidDate: null,
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Salary Preview Options',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'What would you like to do with this salary preview for ${_selectedWorker!.name}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show detailed preview with options
                _showDetailedPreview(previewSalary, _approvedAdvances);
              },
              child: Text(
                'View Details',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show detailed preview with send and download options
  Future<void> _showDetailedPreview(Salary salary, List<Advance> advances) async {
    // Check if a salary already exists for this worker and month
    final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
    Salary? existingSalary;
    
    try {
      existingSalary = await salaryProvider.getSalaryByWorkerIdAndMonth(
        _selectedWorker!.id!, 
        _selectedMonth
      );
    } catch (e) {
      print('Error checking existing salary: $e');
    }
    
    if (existingSalary != null) {
      // Show existing salary details
      await showDialog(
        context: context,
        builder: (context) {
          return SalarySlipDialog(
            salary: existingSalary!,
            worker: _selectedWorker!,
            advances: advances,
          );
        },
      );
    } else {
      // Show preview salary
      await showDialog(
        context: context,
        builder: (context) {
          return SalarySlipDialog(
            salary: salary,
            worker: _selectedWorker!,
            advances: advances,
          );
        },
      );
    }
  }

  Widget _buildPreviewItem(String label, String value, {bool isBold = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : (isBold ? Colors.black : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSalary() async {
    if (_netSalary == null) {
      Fluttertoast.showToast(
        msg: 'Please calculate salary first',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Show preview first
    _showSalaryPreview();
  }

  Future<void> _actuallyProcessSalary() async {
    print('=== PROCESSING SALARY ===');
    
    // Validate required data before proceeding
    if (_selectedWorker == null) {
      print('ERROR: No worker selected');
      Fluttertoast.showToast(
        msg: 'Please select a worker',
        backgroundColor: Colors.red,
      );
      return;
    }
    
    print('Selected worker: ${_selectedWorker!.name} (ID: ${_selectedWorker!.id})');
    
    if (_netSalary == null || _grossSalary == null || _totalAdvance == null) {
      print('ERROR: Salary not calculated');
      Fluttertoast.showToast(
        msg: 'Please calculate salary first',
        backgroundColor: Colors.red,
      );
      return;
    }

    print('Salary data:');
    print('  Net Salary: $_netSalary');
    print('  Gross Salary: $_grossSalary');
    print('  Total Advance: $_totalAdvance');
    print('  Total Days: $_totalDays');
    print('  Present Days: $_presentDays');
    print('  Absent Days: $_absentDays');
    print('  Month: $_selectedMonth');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Salary Processing',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Process salary for ${_selectedWorker!.name}?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 15),
            _buildSummaryRow('Gross Salary', '₹${_grossSalary!.toStringAsFixed(2)}'),
            _buildSummaryRow('Total Advances', '₹${_totalAdvance!.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow(
              'Net Salary',
              '₹${_netSalary!.toStringAsFixed(2)}',
              isTotal: true,
            ),
            if (_netSalary! < 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Negative balance will carry forward to next month',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Process'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      print('User confirmed salary processing');
      setState(() {
        _isLoading = true;
      });

      try {
        final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
        final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);

        // Validate required data
        if (_selectedWorker == null || 
            _totalDays == null || 
            _presentDays == null || 
            _absentDays == null || 
            _grossSalary == null || 
            _totalAdvance == null || 
            _netSalary == null) {
          throw Exception('Missing required salary data');
        }

        print('Creating salary record...');
        // Create salary record
        final salary = Salary(
          workerId: _selectedWorker!.id!,
          month: _selectedMonth, // Store the formatted month (yyyy-MM) instead of just the name
          year: _selectedMonth.split('-')[0],
          totalDays: _totalDays!,
          presentDays: _presentDays!,
          absentDays: _absentDays!,
          grossSalary: _grossSalary!,
          totalAdvance: _totalAdvance!,
          netSalary: _netSalary!,
          paid: true, // Mark as paid when processed
          paidDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );

        print('Salary object created: ${salary.toMap()}');
        
        // Check if salary already exists for this worker and month
        Salary? existingSalary;
        try {
          existingSalary = await salaryProvider.getSalaryByWorkerIdAndMonth(
            _selectedWorker!.id!, 
            _selectedMonth
          );
        } catch (e) {
          print('Error checking existing salary: $e');
        }
        
        bool success;
        if (existingSalary != null) {
          // Update existing salary
          print('Updating existing salary with ID: ${existingSalary.id}');
          final updatedSalary = Salary(
            id: existingSalary.id,
            workerId: salary.workerId,
            month: salary.month,
            year: salary.year,
            totalDays: salary.totalDays,
            presentDays: salary.presentDays,
            absentDays: salary.absentDays,
            grossSalary: salary.grossSalary,
            totalAdvance: salary.totalAdvance,
            netSalary: salary.netSalary,
            paid: salary.paid,
            paidDate: salary.paidDate,
          );
          success = await salaryProvider.updateSalary(updatedSalary);
          print('Salary update result: $success');
        } else {
          // Save new salary
          print('Saving new salary...');
          success = await salaryProvider.addSalary(salary);
          print('Salary save result: $success');
        }

        if (success) {
          print('Salary processed successfully');
          
          // Instead of trying to find the salary in the list, let's get it directly from the database
          Salary? savedSalary;
          try {
            print('Getting saved salary directly from database...');
            final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
            savedSalary = await salaryProvider.getSalaryByWorkerIdAndMonth(
              _selectedWorker!.id!, 
              _selectedMonth
            );
            
            if (savedSalary != null) {
              print('Found saved salary with ID: ${savedSalary?.id}');
            } else {
              print('No saved salary found in database');
            }
          } catch (e) {
            // If there's any error, use the original salary object
            savedSalary = salary;
            print('Error retrieving saved salary from database: $e');
            print('Using original salary object');
          }
          
          // Mark advances as deducted
          print('Processing ${_approvedAdvances.length} approved advances');
          for (var advance in _approvedAdvances) {
            try {
              print('Updating advance ID: ${advance.id}');
              final updatedAdvance = Advance(
                id: advance.id,
                workerId: advance.workerId,
                amount: advance.amount,
                date: advance.date,
                purpose: advance.purpose,
                note: advance.note,
                status: 'deducted',
                approvedBy: advance.approvedBy,
                approvedDate: advance.approvedDate,
                deductedFromSalaryId: savedSalary?.id, // Handle nullable savedSalary
              );
              await advanceProvider.updateAdvance(updatedAdvance);
              print('Advance ${advance.id} updated successfully');
            } catch (e) {
              print('Error updating advance ${advance.id}: $e');
              // Continue with other advances even if one fails
            }
          }

          setState(() {
            _isLoading = false;
          });

          // Show salary slip dialog with send and download options
          if (savedSalary != null) {
            print('Showing salary slip dialog');
            _showSalarySlipDialog(savedSalary, _approvedAdvances);

            // Send notifications
            print('Sending salary notifications');
            _sendSalaryNotifications(savedSalary);
          }

          // Reset form
          print('Resetting form');
          setState(() {
            _selectedWorker = null;
            _resetCalculation();
          });
          print('Salary processing completed successfully');

        } else {
          print('ERROR: Failed to process salary');
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: 'Failed to process salary',
            backgroundColor: Colors.red,
          );
        }

      } catch (e, stackTrace) {
        setState(() {
          _isLoading = false;
        });
        print('!!! ERROR PROCESSING SALARY !!!');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        
        String errorMessage = 'Error processing salary';
        if (e.toString().contains('UNIQUE constraint failed')) {
          errorMessage = 'Salary already processed for this worker and month. Use "View Details" to update existing record.';
        } else if (e.toString().contains('database is locked')) {
          errorMessage = 'Database is busy, please try again';
        } else {
          errorMessage = 'Error processing salary: ${e.toString().substring(0, 50)}...';
        }
        
        Fluttertoast.showToast(
          msg: errorMessage,
          backgroundColor: Colors.red,
        );
      }
    } else {
      print('User cancelled salary processing');
    }
  }

  // Show salary slip dialog with send and download options
  Future<void> _showSalarySlipDialog(Salary salary, List<Advance> advances) async {
    try {
      // Get worker details
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final worker = await userProvider.getUser(salary.workerId);
      
      if (worker == null) {
        Fluttertoast.showToast(
          msg: 'Failed to load worker details',
          backgroundColor: Colors.red,
        );
        return;
      }
      
      // Show the salary slip in a bottom sheet for better visibility
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: true,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: SalarySlipDialog(
                salary: salary,
                worker: worker,
                advances: advances,
              ),
            );
          },
        ),
      );
    } catch (e, stackTrace) {
      print('Error showing salary slip dialog: $e');
      print('Stack trace: $stackTrace');
      Fluttertoast.showToast(
        msg: 'Error showing salary slip: $e',
        backgroundColor: Colors.red,
      );
    }
  }


  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? const Color(0xFF4CAF50) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workers = userProvider.workers.where((u) => u.role == 'worker').toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Process Salary',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - Scaffold.of(context).appBarMaxHeight! - 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculate & Process Salary',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Automatically deducts approved advances from salary',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Worker Selection
                  Text(
                    'Select Worker',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<User>(
                        isExpanded: true,
                        hint: Text(
                          'Select Worker',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                        value: _selectedWorker,
                        items: workers.map((worker) {
                          return DropdownMenuItem<User>(
                            value: worker,
                            child: Text(
                              '${worker.name} (₹${worker.wage.toStringAsFixed(2)}/day)',
                              style: GoogleFonts.poppins(),
                            ),
                          );
                        }).toList(),
                        onChanged: (worker) {
                          if (worker != null) {
                            setState(() {
                              _selectedWorker = worker;
                              _resetCalculation();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Month Selection
                  Text(
                    'Select Month',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01')),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_month, color: Color(0xFF1E88E5)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _selectMonth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          padding: const EdgeInsets.all(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.edit_calendar, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Calculate Button
                  CustomButton(
                    text: 'Calculate Salary',
                    onPressed: _isCalculating ? () {} : _calculateSalary,
                    isLoading: _isCalculating,
                  ),
                  const SizedBox(height: 30),

                  // Results Section
                  if (_netSalary != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salary Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Attendance Info
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: _buildInfoRow(
                                        'Total Days',
                                        '$_totalDays',
                                        Icons.calendar_today,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoRow(
                                        'Present',
                                        '$_presentDays',
                                        Icons.check_circle,
                                        Colors.green,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoRow(
                                        'Absent',
                                        '$_absentDays',
                                        Icons.cancel,
                                        Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Salary Breakdown
                          Text(
                            'Breakdown',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Earnings
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Earnings',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildInfoRow(
                                  'Gross Salary ($_presentDays days × ₹${_selectedWorker?.wage.toStringAsFixed(2)})',
                                  '₹${_grossSalary!.toStringAsFixed(2)}',
                                  Icons.payments,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Deductions
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deductions',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_approvedAdvances.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'No advances taken this month',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else ...[
                                  ..._approvedAdvances.map((adv) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                adv.purpose ?? 'Advance',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (adv.note != null && adv.note!.isNotEmpty)
                                                Text(
                                                  adv.note!,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₹${adv.amount.toStringAsFixed(2)}',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Total Advances',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        '₹${_totalAdvance!.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Net Salary
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _netSalary! >= 0
                                    ? [Colors.green.shade400, Colors.green.shade600]
                                    : [Colors.red.shade400, Colors.red.shade600],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Net Salary',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${_netSalary!.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_netSalary! < 0) ...[
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, color: Colors.red.shade700),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Negative balance of ₹${(-_netSalary!).toStringAsFixed(2)} will be carried forward to next month',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Process Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Process & Save Salary',
                        onPressed: _processSalary,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Send notifications for salary processing
  Future<void> _sendSalaryNotifications(Salary salary) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      // Get worker details
      final worker = await userProvider.getUser(salary.workerId);
      
      if (worker != null) {
        // Create notification for worker
        final workerNotification = NotificationModel(
          title: 'Salary Processed',
          message: 'Your salary for ${salary.month} ${salary.year} has been processed. Net Salary: ₹${salary.netSalary?.toStringAsFixed(2) ?? '0.00'}. Paid Date: ${salary.paidDate}',
          type: 'salary',
          userId: worker.id!,
          userRole: 'worker',
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
          relatedId: salary.id?.toString(),
        );
        
        // Save notification to database and show local notification
        await notificationProvider.addNotification(workerNotification);
        
        // Create notification for admin
        final adminNotification = NotificationModel(
          title: 'Salary Processed',
          message: 'Salary processed for worker ${worker.name}. Net Salary: ₹${salary.netSalary?.toStringAsFixed(2) ?? '0.00'}. Month: ${salary.month} ${salary.year}',
          type: 'salary',
          userId: userProvider.currentUser?.id ?? 0,
          userRole: 'admin',
          isRead: false,
          createdAt: DateTime.now().toIso8601String(),
          relatedId: salary.id?.toString(),
        );
        
        // Save notification to database and show local notification
        await notificationProvider.addNotification(adminNotification);
      }
    } catch (e) {
      print('Error sending salary notifications: $e');
    }
  }
}
