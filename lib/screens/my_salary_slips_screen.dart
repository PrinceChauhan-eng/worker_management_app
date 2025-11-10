import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/salary.dart';
import '../providers/salary_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_app_bar.dart';

class MySalarySlipsScreen extends StatefulWidget {
  const MySalarySlipsScreen({super.key});

  @override
  State<MySalarySlipsScreen> createState() => _MySalarySlipsScreenState();
}

class _MySalarySlipsScreenState extends State<MySalarySlipsScreen> {
  final String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<Salary> _paidSalaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaidSalaries();
  }

  Future<void> _loadPaidSalaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Load all data
      await salaryProvider.loadSalaries();
      
      // Filter for paid salaries of the current user and selected month
      _paidSalaries = salaryProvider.salaries
          .where((salary) => 
              salary.paid && 
              salary.workerId == userProvider.currentUser!.id &&
              salary.month.startsWith(_selectedMonth))
          .toList();

      print('Found ${_paidSalaries.length} paid salaries for worker ID ${userProvider.currentUser!.id} and month $_selectedMonth');
      
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Salary Slips',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Salary Slips',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View your paid salary slips',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // Paid Salaries List
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_paidSalaries.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No paid salaries found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _paidSalaries.length,
                  itemBuilder: (context, index) {
                    return _buildSalaryCard(_paidSalaries[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryCard(Salary salary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Salary Slip',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Month', '${salary.month} ${salary.year}'),
                ),
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
                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(salary.paidDate!))
                        : 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _viewSalarySlip(salary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Salary Slip',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (salary.pdfUrl != null && salary.pdfUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _downloadSalarySlip(salary),
                  child: Text(
                    'Download PDF',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E88E5),
                    ),
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
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  void _viewSalarySlip(Salary salary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return MySalarySlipDetail(salary: salary);
      },
    );
  }

  Future<void> _downloadSalarySlip(Salary salary) async {
    try {
      // In a real implementation, this would download the PDF from the pdfUrl
      // For now, we'll show a message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'In a real implementation, this would download the PDF from: ${salary.pdfUrl}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download salary slip: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class MySalarySlipDetail extends StatefulWidget {
  final Salary salary;

  const MySalarySlipDetail({
    super.key,
    required this.salary,
  });

  @override
  State<MySalarySlipDetail> createState() => _MySalarySlipDetailState();
}

class _MySalarySlipDetailState extends State<MySalarySlipDetail> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final worker = userProvider.currentUser!;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
                      worker.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Worker ID: ${worker.id}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Salary Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Month',
                      '${widget.salary.month} ${widget.salary.year}',
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
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Daily Wage',
                      '₹${worker.wage.toStringAsFixed(2)}',
                      Icons.account_balance,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInfoCard(
                      'Status',
                      widget.salary.paid ? 'Paid' : 'Unpaid',
                      widget.salary.paid ? Icons.check_circle : Icons.pending,
                      color: widget.salary.paid ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Salary Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _buildBreakdownItem(
                'Gross Salary',
                '₹${widget.salary.grossSalary?.toStringAsFixed(2) ?? ((worker.wage) * (widget.salary.presentDays ?? 0)).toStringAsFixed(2)}',
                Icons.calculate,
              ),
              const Divider(),
              _buildBreakdownItem(
                'Total Advances',
                '₹${widget.salary.totalAdvance?.toStringAsFixed(2) ?? '0.00'}',
                Icons.payments,
                isBold: true,
                valueColor: Colors.red,
              ),
              const Divider(),
              _buildBreakdownItem(
                'Net Salary',
                '₹${widget.salary.netSalary?.toStringAsFixed(2) ?? widget.salary.totalSalary.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                isBold: true,
                valueColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 20),
              if (widget.salary.paidDate != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Paid on ${DateFormat('dd MMM yyyy').format(DateTime.parse(widget.salary.paidDate!))}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _downloadSalarySlip,
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'Download PDF',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color ?? const Color(0xFF1E88E5),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.black,
            ),
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
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _downloadSalarySlip() async {
    try {
      // In a real implementation, this would download the PDF from the pdfUrl
      // For now, we'll show a message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'In a real implementation, this would download the PDF from: ${widget.salary.pdfUrl}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download salary slip: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}