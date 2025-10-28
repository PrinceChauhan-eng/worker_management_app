import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/advance_provider.dart';
import '../providers/salary_provider.dart';
import '../widgets/custom_app_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadWorkers();
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.loadAttendances();
      final advanceProvider =
          Provider.of<AdvanceProvider>(context, listen: false);
      advanceProvider.loadAdvances();
      final salaryProvider =
          Provider.of<SalaryProvider>(context, listen: false);
      salaryProvider.loadSalaries();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final advanceProvider = Provider.of<AdvanceProvider>(context);
    final salaryProvider = Provider.of<SalaryProvider>(context);

    // Calculate report data
    final workers = userProvider.workers
        .where((user) => user.role == 'worker')
        .toList();
    
    final attendances = attendanceProvider.attendances
        .where((att) => att.date.startsWith(_selectedMonth))
        .toList();
    
    final advances = advanceProvider.advances
        .where((adv) => adv.date.startsWith(_selectedMonth))
        .toList();
    
    final salaries = salaryProvider.salaries
        .where((sal) => sal.month == _selectedMonth)
        .toList();

    // Calculate totals
    int totalWorkers = workers.length;
    int totalAttendanceDays = attendances
        .where((att) => att.present)
        .length;
    
    double totalAdvance = 0;
    for (var advance in advances) {
      totalAdvance += advance.amount;
    }
    
    double totalSalaryPaid = 0;
    for (var salary in salaries) {
      if (salary.paid) {
        totalSalaryPaid += salary.totalSalary;
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reports',
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
              'Monthly Reports',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Summary for selected month',
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
            // Summary Cards
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildSummaryCard(
                    title: 'Total Workers',
                    value: totalWorkers.toString(),
                    icon: Icons.group,
                    color: const Color(0xFF1E88E5), // Royal Blue
                  ),
                  _buildSummaryCard(
                    title: 'Attendance Days',
                    value: totalAttendanceDays.toString(),
                    icon: Icons.check_circle,
                    color: const Color(0xFF4CAF50), // Green
                  ),
                  _buildSummaryCard(
                    title: 'Advance Given',
                    value: '₹${totalAdvance.toStringAsFixed(2)}',
                    icon: Icons.payments,
                    color: const Color(0xFFFFA726), // Orange
                  ),
                  _buildSummaryCard(
                    title: 'Salary Paid',
                    value: '₹${totalSalaryPaid.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFFAB47BC), // Purple
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Detailed Reports Section
            Text(
              'Detailed Reports',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.file_download,
                  color: Color(0xFF1E88E5), // Royal Blue
                ),
                title: Text(
                  'Export to CSV',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Export all reports data to CSV file',
                  style: GoogleFonts.poppins(),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Future implementation for CSV export
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('CSV export feature coming soon!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}