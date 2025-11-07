import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/advance.dart';
import '../providers/user_provider.dart';
import '../providers/salary_provider.dart';
import '../providers/advance_provider.dart';
import '../screens/my_salary_slips_screen.dart';
import '../widgets/custom_app_bar.dart';

class MySalaryScreen extends StatefulWidget {
  const MySalaryScreen({super.key});

  @override
  State<MySalaryScreen> createState() => _MySalaryScreenState();
}

class _MySalaryScreenState extends State<MySalaryScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final salaryProvider =
          Provider.of<SalaryProvider>(context, listen: false);
      
      if (userProvider.currentUser != null) {
        salaryProvider.loadSalariesByWorkerId(userProvider.currentUser!.id!);
      }
    });
  }

  _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
      
      // Reload salaries for selected month
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final salaryProvider =
          Provider.of<SalaryProvider>(context, listen: false);
      
      if (userProvider.currentUser != null) {
        salaryProvider.loadSalariesByWorkerId(userProvider.currentUser!.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final salaryProvider = Provider.of<SalaryProvider>(context);
    final advanceProvider = Provider.of<AdvanceProvider>(context);
    
    final workerId = userProvider.currentUser?.id;
    
    // Filter salaries for selected month and current worker
    final salaries = workerId != null 
        ? salaryProvider.salaries
            .where((sal) => 
                sal.workerId == workerId && 
                sal.month == _selectedMonth)
            .toList()
        : [];
    
    final salary = salaries.isNotEmpty ? salaries.first : null;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Salary',
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
              'Salary Details',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View your salary breakdown',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            // Month Selector
            GestureDetector(
              onTap: () => _selectMonth(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5), // Royal Blue
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _selectedMonth,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Salary Details
            if (salary == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No salary record found for this month',
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
              FutureBuilder<List<Advance>>(
                future: workerId != null 
                  ? advanceProvider.getAdvancesByWorkerIdAndMonth(workerId, _selectedMonth)
                  : Future.value([]),
                builder: (context, snapshot) {
                  final advances = snapshot.data ?? [];
                  final totalAdvance = advances.fold<double>(
                    0.0, 
                    (sum, adv) => sum + adv.amount
                  );
                  
                  return Expanded(
                    child: Column(
                      children: [
                        // Salary Summary Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E88E5), // Royal Blue
                                  Color(0xFFFFA726), // Orange
                                ],
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Net Salary',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '₹${salary.netSalary?.toStringAsFixed(2) ?? salary.totalSalary.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: salary.paid
                                        ? const Color(0xFF4CAF50) // Green
                                        : const Color(0xFFF44336), // Red
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    salary.paid ? 'Paid' : 'Unpaid',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Salary Breakdown
                        Text(
                          'Salary Breakdown',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBreakdownItem(
                                  'Present Days',
                                  '${salary.presentDays ?? 0} days',
                                  Icons.calendar_today,
                                ),
                                const Divider(),
                                _buildBreakdownItem(
                                  'Daily Wage',
                                  '₹${userProvider.currentUser?.wage.toStringAsFixed(2) ?? "0.00"}',
                                  Icons.account_balance,
                                ),
                                const Divider(),
                                _buildBreakdownItem(
                                  'Gross Salary',
                                  '₹${salary.grossSalary?.toStringAsFixed(2) ?? ((userProvider.currentUser?.wage ?? 0) * (salary.presentDays ?? 0)).toStringAsFixed(2)}',
                                  Icons.calculate,
                                ),
                                const Divider(),
                                if (advances.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Advances Taken',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ...advances.map((advance) => 
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                advance.purpose ?? 'Advance',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '₹${advance.amount.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (advance.note != null && advance.note!.isNotEmpty)
                                            Text(
                                              advance.note!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          Text(
                                            DateFormat('dd MMM yyyy').format(DateTime.parse(advance.date)),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[500],
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
                                  Icons.payments,
                                  isBold: true,
                                  valueColor: Colors.red,
                                ),
                                const Divider(),
                                _buildBreakdownItem(
                                  'Net Salary',
                                  '₹${salary.netSalary?.toStringAsFixed(2) ?? salary.totalSalary.toStringAsFixed(2)}',
                                  Icons.account_balance_wallet,
                                  isBold: true,
                                  valueColor: const Color(0xFF4CAF50),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
            const SizedBox(height: 20),
            // View All Paid Salary Slips Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MySalarySlipsScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50), // Green
                  padding: const EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'View All Paid Salary Slips',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          color: const Color(0xFF1E88E5), // Royal Blue
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
}