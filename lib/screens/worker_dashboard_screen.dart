import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import 'my_attendance_screen.dart';
import 'my_salary_screen.dart';
import 'my_advance_screen.dart';
import 'login_screen.dart';

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workerName = userProvider.currentUser?.name ?? 'Worker';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hello, $workerName 👷',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear session
              SessionManager sessionManager = SessionManager();
              await sessionManager.logout();
              
              // Clear current user in provider
              userProvider.clearCurrentUser();
              
              // Show toast
              Fluttertoast.showToast(
                msg: 'You have been logged out.',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
              );
              
              // Navigate to login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View your attendance, salary and advances',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            // Dashboard Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'My Attendance',
                    icon: Icons.check_circle,
                    color: const Color(0xFF4CAF50), // Green
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyAttendanceScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'My Salary',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFFFFA726), // Soft Orange
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MySalaryScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'My Advances',
                    icon: Icons.payments,
                    color: const Color(0xFF26C6DA), // Teal
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyAdvanceScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Logout',
                    icon: Icons.logout,
                    color: const Color(0xFFF44336), // Red
                    onTap: () async {
                      // Clear session
                      SessionManager sessionManager = SessionManager();
                      await sessionManager.logout();
                      
                      // Clear current user in provider
                      userProvider.clearCurrentUser();
                      
                      // Show toast
                      Fluttertoast.showToast(
                        msg: 'You have been logged out.',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                      
                      // Navigate to login screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
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
                fontSize: 16,
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