import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../models/user.dart';
import '../../services/salary_calculation_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/salary_provider.dart';
import '../../utils/logger.dart';

class AutomatedSalaryScreen extends StatefulWidget {
  const AutomatedSalaryScreen({super.key});

  @override
  State<AutomatedSalaryScreen> createState() => _AutomatedSalaryScreenState();
}

class _AutomatedSalaryScreenState extends State<AutomatedSalaryScreen> {
  User? _selectedWorker;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  bool _isCalculating = false;
  SalaryCalculationResult? _calculationResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Automated Salary Calculation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salary Automation',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Automatic salary calculation based on attendance hours',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Worker Selection
            _buildWorkerSelection(),
            const SizedBox(height: 20),

            // Month Selection
            _buildMonthSelection(),
            const SizedBox(height: 30),

            // Action Buttons
            _buildActionButtons(),
            const SizedBox(height: 30),

            // Results
            if (_calculationResult != null)
              _buildResultsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerSelection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final workers = userProvider.workers
            .where((u) => u.role == 'worker')
            .toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<User>(
              isExpanded: true,
              hint: Text(
                'Select Worker',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              value: _selectedWorker,
              items: workers.map((worker) {
                return DropdownMenuItem<User>(
                  value: worker,
                  child: Text(
                    worker.name,
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (User? worker) {
                setState(() {
                  _selectedWorker = worker;
                  _calculationResult = null; // Reset results when worker changes
                });
              },
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF1E88E5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Month',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                DateFormat('MMMM yyyy').format(
                  DateTime.parse('$_selectedMonth-01'),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text('Change Month', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _calculateSalary,
            icon: _isCalculating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.calculate, size: 20),
            label: Text(
              _isCalculating ? 'Calculating...' : 'Calculate Salary',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (_calculationResult != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSalary,
              icon: const Icon(Icons.save, size: 20),
              label: Text(
                'Save Salary Record',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salary Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Summary Stats
            _buildStatItem('Total Present', _calculationResult!.presentDays.toString(), Colors.green),
            _buildStatItem('Half Day', _calculationResult!.halfDays.toString(), Colors.orange),
            _buildStatItem('Absent', _calculationResult!.absentDays.toString(), Colors.red),
            _buildStatItem('Overtime', '${_calculationResult!.overtimeHours.toStringAsFixed(1)}h', Colors.blue),
            const SizedBox(height: 10),
            
            // Financial Summary
            const Divider(),
            _buildFinancialItem('Gross Salary', '₹${_calculationResult!.grossSalary.toStringAsFixed(2)}'),
            _buildFinancialItem('Advance', '₹${_calculationResult!.totalAdvance.toStringAsFixed(2)}'),
            const Divider(thickness: 2),
            _buildFinancialItem('Final Payable', '₹${_calculationResult!.netSalary.toStringAsFixed(2)}', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse('$_selectedMonth-01'),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
        _calculationResult = null; // Reset results when month changes
      });
    }
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
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      
      final result = await salaryProvider.calculateAutomatedSalary(
        worker: _selectedWorker!,
        month: _selectedMonth,
      );
      
      setState(() {
        _calculationResult = result;
        _isCalculating = false;
      });
      
      Fluttertoast.showToast(
        msg: 'Salary calculated successfully',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Logger.error('Error calculating salary: $e', e);
      setState(() {
        _isCalculating = false;
      });
      Fluttertoast.showToast(
        msg: 'Error calculating salary: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _saveSalary() async {
    if (_calculationResult == null) return;

    try {
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      
      // Generate salary record from calculation
      final salary = await salaryProvider.generateSalaryFromCalculation(_calculationResult!);
      
      // Save to database
      final success = await salaryProvider.addSalary(salary);
      
      if (success) {
        Fluttertoast.showToast(
          msg: 'Salary record saved successfully',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to save salary record',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Logger.error('Error saving salary: $e', e);
      Fluttertoast.showToast(
        msg: 'Error saving salary: $e',
        backgroundColor: Colors.red,
      );
    }
  }
}