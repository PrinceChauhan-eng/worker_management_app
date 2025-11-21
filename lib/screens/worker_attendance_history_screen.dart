import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../widgets/custom_app_bar.dart';

class WorkerAttendanceHistoryScreen extends StatefulWidget {
  const WorkerAttendanceHistoryScreen({super.key});

  @override
  State<WorkerAttendanceHistoryScreen> createState() => _WorkerAttendanceHistoryScreenState();
}

class _WorkerAttendanceHistoryScreenState extends State<WorkerAttendanceHistoryScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now().toLocal());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceData();
    });
  }

  Future<void> _loadAttendanceData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
    
    if (userProvider.currentUser != null) {
      await loginStatusProvider.loadLoginStatusesByWorkerId(userProvider.currentUser!.id!);
    }
  }

  _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().toLocal(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked.toLocal());
      });
      
      // Reload attendance for selected month
      _loadAttendanceData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context);
    
    final workerId = userProvider.currentUser?.id;
    
    // Filter login statuses for selected month and current worker
    final loginStatuses = workerId != null 
        ? loginStatusProvider.loginStatuses
            .where((status) => 
                status.workerId == workerId && 
                status.date.startsWith(_selectedMonth))
            .toList()
        : [];
    
    // Calculate present and absent counts
    int presentCount = loginStatuses.where((status) => status.isLoggedIn).length;
    int absentCount = loginStatuses.length - presentCount;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Attendance',
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance History',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View your attendance records',
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
            const SizedBox(height: 20),
            // Summary Card
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
                      Color(0xFF4CAF50), // Green
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Present', presentCount.toString(), Colors.white),
                    _buildVerticalDivider(),
                    _buildSummaryItem('Absent', absentCount.toString(), Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Attendance List
            Text(
              'Attendance Records',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: loginStatuses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No attendance records found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: loginStatuses.length,
                      itemBuilder: (context, index) {
                        final status = loginStatuses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: status.isLoggedIn
                                    ? const Color(0xFF4CAF50) // Green
                                    : const Color(0xFFF44336), // Red
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                status.isLoggedIn
                                    ? Icons.check
                                    : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              DateFormat('dd MMM yyyy').format(
                                DateFormat('yyyy-MM-dd').parse(status.date).toLocal(),
                              ),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: status.isLoggedIn
                                ? Text(
                                    '${status.loginTime ?? '--:--'} - ${status.logoutTime ?? 'Still logged in'}',
                                    style: GoogleFonts.poppins(),
                                  )
                                : Text(
                                    'Absent',
                                    style: GoogleFonts.poppins(),
                                  ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: status.isLoggedIn
                                    ? const Color(0xFFE8F5E9) // Light Green
                                    : const Color(0xFFFFEBEE), // Light Red
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                status.isLoggedIn ? 'Present' : 'Absent',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status.isLoggedIn
                                      ? const Color(0xFF4CAF50) // Green
                                      : const Color(0xFFF44336), // Red
                                ),
                              ),
                            ),
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

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.5),
    );
  }
}