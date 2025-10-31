import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/advance.dart';
import '../models/salary.dart';
import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/login_status_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class ProcessSalaryScreen extends StatefulWidget {
  const ProcessSalaryScreen({super.key});

  @override
  State<ProcessSalaryScreen> createState() => _ProcessSalaryScreenState();
}

class _ProcessSalaryScreenState extends State<ProcessSalaryScreen> {
  User? _selectedWorker;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isLoading = false;
  bool _isCalculating = false;
  
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
    _loadData();
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadWorkers();
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

  Future<void> _processSalary() async {
    if (_netSalary == null) {
      Fluttertoast.showToast(
        msg: 'Please calculate salary first',
        backgroundColor: Colors.red,
      );
      return;
    }

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
      setState(() {
        _isLoading = true;
      });

      try {
        final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
        final advanceProvider = Provider.of<AdvanceProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Create salary record
        final salary = Salary(
          workerId: _selectedWorker!.id!,
          month: DateFormat('MMMM').format(DateTime.parse('$_selectedMonth-01')),
          year: _selectedMonth.split('-')[0],
          totalDays: _totalDays!,
          presentDays: _presentDays!,
          absentDays: _absentDays!,
          grossSalary: _grossSalary!,
          totalAdvance: _totalAdvance!,
          netSalary: _netSalary!,
          paid: false,
          paidDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );

        // Save salary
        final success = await salaryProvider.addSalary(salary);

        if (success) {
          // Mark advances as deducted
          for (var advance in _approvedAdvances) {
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
              deductedFromSalaryId: salary.id,
            );
            await advanceProvider.updateAdvance(updatedAdvance);
          }

          setState(() {
            _isLoading = false;
          });

          Fluttertoast.showToast(
            msg: 'Salary processed successfully!',
            backgroundColor: Colors.green,
          );

          // Reset form
          setState(() {
            _selectedWorker = null;
            _resetCalculation();
          });

        } else {
          setState(() {
            _isLoading = false;
          });
          Fluttertoast.showToast(
            msg: 'Failed to process salary',
            backgroundColor: Colors.red,
          );
        }

      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error processing salary: $e',
          backgroundColor: Colors.red,
        );
      }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                        '${worker.name} (₹${worker.wage}/day)',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }).toList(),
                  onChanged: (worker) {
                    setState(() {
                      _selectedWorker = worker;
                      _resetCalculation();
                    });
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
                        Text(
                          DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01')),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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
                  ),
                  child: const Icon(Icons.edit_calendar),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Calculate Button
            CustomButton(
              text: 'Calculate Salary',
              onPressed: _calculateSalary,
              isLoading: _isCalculating,
            ),
            const SizedBox(height: 30),

            // Calculation Results
            if (_grossSalary != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate, color: const Color(0xFF1E88E5)),
                        const SizedBox(width: 10),
                        Text(
                          'Salary Calculation',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Attendance Summary
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('Total Days', '$_totalDays days', Icons.calendar_today),
                          _buildInfoRow('Present Days', '$_presentDays days', Icons.check_circle, Colors.green),
                          _buildInfoRow('Absent Days', '$_absentDays days', Icons.cancel, Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Salary Breakdown
                    _buildSummaryRow('Daily Wage', '₹${_selectedWorker!.wage.toStringAsFixed(2)}'),
                    _buildSummaryRow('Working Days', '$_presentDays days'),
                    const Divider(height: 30),
                    _buildSummaryRow('Gross Salary', '₹${_grossSalary!.toStringAsFixed(2)}', isTotal: true),
                    
                    const SizedBox(height: 20),

                    // Advances Section
                    if (_approvedAdvances.isNotEmpty) ...[
                      Text(
                        'Approved Advances (${_approvedAdvances.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ..._approvedAdvances.map((adv) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${adv.purpose ?? "Advance"} - ${DateFormat('dd MMM').format(DateTime.parse(adv.date))}',
                                      style: GoogleFonts.poppins(fontSize: 13),
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
                                Text(
                                  'Total Advances',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

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
                          Text(
                            'Net Salary',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
              CustomButton(
                text: 'Process & Save Salary',
                onPressed: _processSalary,
                isLoading: _isLoading,
              ),
            ],
          ],
        ),
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
}
