import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_menu_button.dart';
import 'my_attendance_screen.dart';
import 'my_salary_screen.dart';
import 'my_advance_screen.dart';
import 'request_advance_screen.dart';
import 'notifications_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _isLoading = false;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    _DashboardHome(),
    _AttendanceScreen(),
    _SalaryScreen(),
    _AdvanceScreen(),
  ];

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

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Hello, $workerName 👷',
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    if (notificationProvider.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            notificationProvider.unreadCount > 99
                                ? '99+'
                                : notificationProvider.unreadCount.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const ProfileMenuButton(),
          ],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF1E88E5),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Salary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment),
              label: 'Advance',
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Home Screen
class _DashboardHome extends StatefulWidget {
  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh login status periodically to catch admin changes
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTodayLoginStatus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(  // Make the content scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome to your worker dashboard',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            
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
                      onPressed: _isLoading ? null : (isLoggedIn ? _handleLogout : _handleLogin),
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
                        isLoggedIn ? 'Logout' : 'Login',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
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
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 200, // Fixed height for quick actions
              child: GridView.count(
                physics: const AlwaysScrollableScrollPhysics(), // Make it scrollable
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.2, // Adjusted aspect ratio
                children: [
                  _buildQuickActionCard(
                    context,
                    title: 'My Attendance',
                    icon: Icons.check_circle,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAttendanceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    title: 'My Salary',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MySalaryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    title: 'Request Advance',
                    icon: Icons.payment,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestAdvanceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    title: 'My Advances',
                    icon: Icons.history,
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAdvanceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Add some bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Attendance Screen
class _AttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Attendance',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5),
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
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Attendance Records',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'View your login/logout history and attendance records',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAttendanceScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Salary Screen
class _SalaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Salary',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'View your salary details and history',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Salary Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'View your salary slips, advances, and payment history',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MySalaryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Salary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Advance Screen
class _AdvanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advance Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Request and view your advances',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: [
                _buildFeatureCard(
                  context,
                  title: 'Request Advance',
                  icon: Icons.add,
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestAdvanceScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  title: 'My Advances',
                  icon: Icons.history,
                  color: const Color(0xFF9C27B0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyAdvanceScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}