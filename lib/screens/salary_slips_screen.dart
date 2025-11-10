// ✅ 100% FIXED — NO MISSING BRACKETS, NO SYNTAX ERRORS

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/salary.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../providers/salary_provider.dart';
import '../providers/user_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/notification_provider.dart';
import '../utils/pdf_utils.dart';
import '../widgets/custom_app_bar.dart';

class SalarySlipsScreen extends StatefulWidget {
  const SalarySlipsScreen({super.key});

  @override
  State<SalarySlipsScreen> createState() => _SalarySlipsScreenState();
}

class _SalarySlipsScreenState extends State<SalarySlipsScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<Salary> _paidSalaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaidSalaries();
  }

  Future<void> _loadPaidSalaries() async {
    setState(() => _isLoading = true);

    try {
      final salaryProvider = Provider.of<SalaryProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await salaryProvider.loadSalaries();
      await userProvider.loadWorkers();

      // Filter for paid salaries that match the selected month
      _paidSalaries = salaryProvider.salaries
          .where((salary) => salary.paid && salary.month.startsWith(_selectedMonth))
          .toList();

      print('Found ${_paidSalaries.length} paid salaries for month $_selectedMonth');
      
      // Also print details of each salary for debugging
      for (var salary in _paidSalaries) {
        print('Salary ID: ${salary.id}, Worker ID: ${salary.workerId}, Month: ${salary.month}, Paid: ${salary.paid}');
      }
    } catch (e) {
      print('Error loading paid salaries: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading paid salaries: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() => _selectedMonth = DateFormat('yyyy-MM').format(picked));
      _loadPaidSalaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Paid Salary Slips',
          onLeadingPressed: () => Navigator.pop(context),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paid Salary Slips',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'View salary slips of paid workers',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => _selectMonth(context),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Month: $_selectedMonth',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _paidSalaries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _paidSalaries.length,
                        itemBuilder: (context, index) {
                          return _buildSalaryCard(_paidSalaries[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No paid salaries found for this month',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard(Salary salary) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final worker = userProvider.workers.firstWhere(
      (u) => u.id == salary.workerId,
      orElse: () => User(
        id: salary.workerId,
        name: 'Unknown Worker',
        phone: '',
        password: '',
        role: 'worker',
        wage: 0,
        joinDate: '',
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    worker.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Paid',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),
            Text(
              'Worker ID: ${salary.workerId}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(child: _buildInfoRow('Month', salary.month)),
                Expanded(
                  child: _buildInfoRow(
                    'Net Salary',
                    '₹${salary.netSalary?.toStringAsFixed(2) ?? salary.totalSalary.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    'Present Days',
                    '${salary.presentDays ?? 0}',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    'Paid Date',
                    salary.paidDate != null
                        ? DateFormat(
                            'dd MMM yyyy',
                          ).format(DateTime.parse(salary.paidDate!))
                        : 'N/A',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSalarySlip(salary, worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                ),
                child: Text(
                  'View Salary Slip',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showSalarySlip(Salary salary, User worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: true, // Make sure it expands
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SalarySlipDetail(salary: salary, worker: worker);
        },
      ),
    );
  }
}

// ✅ SalarySlipDetail CLASS — FULLY FIXED BELOW
// (No missing parentheses, no missing brackets)

class SalarySlipDetail extends StatefulWidget {
  final Salary salary;
  final User worker;

  const SalarySlipDetail({
    super.key,
    required this.salary,
    required this.worker,
  });

  @override
  State<SalarySlipDetail> createState() => _SalarySlipDetailState();
}

class _SalarySlipDetailState extends State<SalarySlipDetail> {
  List<dynamic> _advances = [];

  @override
  void initState() {
    super.initState();
    _loadAdvances();
  }

  Future<void> _loadAdvances() async {
    try {
      final advanceProvider = Provider.of<AdvanceProvider>(
        context,
        listen: false,
      );
      _advances = await advanceProvider.getAdvancesByWorkerIdAndMonth(
        widget.worker.id!,
        widget.salary.month,
      );
    } catch (e) {
      print('Error loading advances: $e');
    }

    setState(() {});
  }

  Future<pw.Document> _generateSalarySlipPdf() async {
    return await PdfUtils.generateSalarySlipPdf(
      widget.salary,
      widget.worker,
      _advances,
    );
  }

  Future<void> _downloadSalarySlip() async {
    try {
      final pdf = await _generateSalarySlipPdf();
      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Salary slip downloaded!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendSlipToWorker() async {
    try {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      final notification = NotificationModel(
        title: 'Salary Paid',
        message: 'Your salary for ${widget.salary.month} is paid.',
        type: 'salary',
        userId: widget.worker.id!,
        userRole: 'worker',
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
        relatedId: widget.salary.id?.toString(),
      );

      await notificationProvider.addNotification(notification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent to worker!', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAdvance = _advances.fold<double>(
      0.0,
      (sum, adv) => sum + (adv['amount'] as double? ?? 0.0),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Salary Slip',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Center(
                child: Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Worker Info
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.worker.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Worker ID: ${widget.worker.id}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Phone: ${widget.worker.phone}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Month',
                      widget.salary.month,
                      Icons.calendar_month,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoCard(
                      'Present Days',
                      '${widget.salary.presentDays ?? 0}',
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreakdownItem(
                        'Gross Salary',
                        '₹${widget.salary.grossSalary?.toStringAsFixed(2) ?? ((widget.worker.wage) * (widget.salary.presentDays ?? 0)).toStringAsFixed(2)}',
                        Icons.calculate,
                      ),
                      const Divider(),

                      if (_advances.isNotEmpty) ...[
                        Text(
                          'Advances',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._advances.map(
                          (advance) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  advance['purpose'] ?? 'Advance',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '₹${(advance['amount'] as double?)?.toStringAsFixed(2) ?? "0.00"}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                      ],

                      _buildBreakdownItem(
                        'Total Advances',
                        '₹${totalAdvance.toStringAsFixed(2)}',
                        Icons.money_off,
                        valueColor: Colors.red,
                      ),
                      const Divider(),

                      _buildBreakdownItem(
                        'Net Salary',
                        '₹${widget.salary.netSalary?.toStringAsFixed(2) ?? widget.salary.totalSalary.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        valueColor: Colors.green,
                        isBold: true,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _downloadSalarySlip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                              ),
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Download PDF',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sendSlipToWorker,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              icon: const Icon(Icons.send, color: Colors.white),
                              label: Text(
                                'Send Slip',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? const Color(0xFF1E88E5)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String value,
    IconData icon, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E88E5)),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}
