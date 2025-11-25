import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Providers
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/notification_provider.dart';

// Widgets
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_menu_button.dart';

// Services
import '../services/route_guard.dart';

// Screens
import 'notifications_screen.dart';

// Admin module screens
import 'admin/dashboard_home_screen.dart';
import 'admin/workers_screen.dart';
import 'admin/attendance_screen.dart';
import 'admin/salary_screen.dart';
import 'admin/admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardHomeScreen(),
    WorkersScreen(),
    AttendanceScreen(),
    SalaryScreen(),
    AdminReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );

    await userProvider.loadWorkers();
    await loginStatusProvider.getLoginStatistics();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    
    // Enhanced route guard
    if (user?.role != "admin") {
      // Redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RouteGuard.redirectToLogin(context);
      });
      return const SizedBox(); // block access
    }
    
    final adminName =
        Provider.of<UserProvider>(context).currentUser?.name ?? 'Admin';

    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Welcome, $adminName 👨‍💼',
          showLiveClock: true, // Enable live clock
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

                    // ✅ Notification badge
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

            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),

            const ProfileMenuButton(),
          ],
        ),

        // ✅ Show current screen
        body: _screens[_currentIndex],

        // ✅ Enhanced Navigation bar with better styling
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF1E88E5),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(),
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard, size: 24),
                activeIcon: Icon(Icons.dashboard, size: 28),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people, size: 24),
                activeIcon: Icon(Icons.people, size: 28),
                label: 'Workers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle, size: 24),
                activeIcon: Icon(Icons.check_circle, size: 28),
                label: 'Attendance',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet, size: 24),
                activeIcon: Icon(Icons.account_balance_wallet, size: 28),
                label: 'Salary',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart, size: 24),
                activeIcon: Icon(Icons.bar_chart, size: 28),
                label: 'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }
}