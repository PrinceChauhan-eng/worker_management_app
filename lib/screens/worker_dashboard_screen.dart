import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../services/session_manager.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_menu_button.dart';
import 'my_attendance_screen.dart';
import 'my_salary_screen.dart';
import 'my_advance_screen.dart';
import 'request_advance_screen.dart';
import 'login_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkTodayLoginStatus();
  }

  Future<void> _checkTodayLoginStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
    
    if (userProvider.currentUser != null) {
      await loginStatusProvider.checkTodayLoginStatus(userProvider.currentUser!.id!);
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      Fluttertoast.showToast(
        msg: 'User not found',
        backgroundColor: Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final result = await loginStatusProvider.workerLogin(userProvider.currentUser!);

    setState(() {
      _isLoading = false;
    });

    Fluttertoast.showToast(
      msg: result['message'],
      backgroundColor: result['success'] ? Colors.green : Colors.red,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      Fluttertoast.showToast(
        msg: 'User not found',
        backgroundColor: Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final result = await loginStatusProvider.workerLogout(userProvider.currentUser!);

    setState(() {
      _isLoading = false;
    });

    Fluttertoast.showToast(
      msg: result['message'],
      backgroundColor: result['success'] ? Colors.green : Colors.red,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context);
    final workerName = userProvider.currentUser?.name ?? 'Worker';
    final isLoggedIn = loginStatusProvider.isLoggedIn;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hello, $workerName 👷',
        actions: const [
          ProfileMenuButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Login/Logout Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLoggedIn
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isLoggedIn ? Colors.green : Colors.orange).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? 'Logged In' : 'Not Logged In',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (isLoggedIn && loginStatusProvider.todayLoginStatus != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Since: ${loginStatusProvider.todayLoginStatus!.loginTime}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Icon(
                        isLoggedIn ? Icons.check_circle : Icons.info_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : (isLoggedIn ? _handleLogout : _handleLogin),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              isLoggedIn ? Icons.logout : Icons.login,
                              size: 20,
                            ),
                      label: Text(
                        _isLoading
                            ? 'Processing...'
                            : isLoggedIn
                                ? 'Logout Now'
                                : 'Login Now',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isLoggedIn ? Colors.green.shade700 : Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
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
                    title: 'Request Advance',
                    icon: Icons.add_card,
                    color: const Color(0xFF9C27B0), // Purple
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RequestAdvanceScreen()),
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