import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_menu_button.dart';
import '../models/login_status.dart';
import 'worker_attendance_history_screen.dart';
import 'my_salary_screen.dart';
import 'my_advance_screen.dart';
import 'request_advance_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    _DashboardHome(),
    WorkerAttendanceHistoryScreen(), // Updated to use new screen
    MySalaryScreen(),
    MyAdvanceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      print('Initializing worker dashboard data...');
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      // Load user data if not already loaded
      if (userProvider.currentUser != null) {
        print(
          'Loading user data for worker ID: ${userProvider.currentUser!.id}',
        );
        await userProvider.loadWorkers();
      }

      // Check today's login status
      await _checkTodayLoginStatus();

      // Load notifications for the current user
      if (userProvider.currentUser != null) {
        await notificationProvider.loadNotifications(
          userProvider.currentUser!.id!,
          userProvider.currentUser!.role,
        );
      }

      print('Worker dashboard data initialized successfully');
    } catch (e) {
      print('Error initializing worker dashboard data: $e');
    }
  }

  Future<void> _checkTodayLoginStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser != null) {
      await loginStatusProvider.checkTodayLoginStatus(
        userProvider.currentUser!.id!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Worker Dashboard',
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Advances'),
        ],
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
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    // Refresh login status periodically to catch admin changes
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTodayLoginStatus();
    });

    // Check for notifications periodically
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForAttendanceNotifications();
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      print('Loading initial data for dashboard home...');
      await _checkTodayLoginStatus();
      
      // Mark absentees on app start
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      await attendanceProvider.markAbsentees();
      
      print('Initial data loaded successfully');
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkTodayLoginStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser != null) {
      await loginStatusProvider.checkTodayLoginStatus(
        userProvider.currentUser!.id!,
      );
    }
  }

  Future<void> _checkForAttendanceNotifications() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final loginStatusProvider = Provider.of<LoginStatusProvider>(
        context,
        listen: false,
      );
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );

      if (userProvider.currentUser != null) {
        // Load all notifications for the user
        await notificationProvider.loadNotifications(
          userProvider.currentUser!.id!,
          userProvider.currentUser!.role,
        );

        // Get unread notifications
        final unreadNotifications = notificationProvider.notifications
            .where((notification) => !notification.isRead)
            .toList();

        // Filter for attendance notifications
        final attendanceNotifications = unreadNotifications
            .where((notification) => notification.type == 'attendance')
            .toList();

        if (attendanceNotifications.isNotEmpty) {
          print(
            'Found ${attendanceNotifications.length} new attendance notifications',
          );

          // Refresh login status to reflect admin changes
          await _checkTodayLoginStatus();

          // Check if the worker was marked as absent and is currently logged in
          if (loginStatusProvider.isLoggedIn) {
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final todayStatus = await loginStatusProvider.getLoginStatusForDate(
              userProvider.currentUser!.id!,
              today,
            );

            // If worker was marked absent but is still logged in, auto-logout
            if (todayStatus != null && !todayStatus.isLoggedIn) {
              // Worker was marked absent, auto-logout
              await _handleAutoLogout();
            }
          }

          // Mark notifications as read
          for (var notification in attendanceNotifications) {
            await notificationProvider.markAsRead(notification.id!);
          }

          // Show a toast message about the update
          if (attendanceNotifications.length == 1) {
            Fluttertoast.showToast(
              msg: attendanceNotifications.first.message,
              backgroundColor: Colors.blue,
              toastLength: Toast.LENGTH_LONG,
            );
          } else {
            Fluttertoast.showToast(
              msg:
                  'You have ${attendanceNotifications.length} attendance updates',
              backgroundColor: Colors.blue,
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for attendance notifications: $e');
    }
  }

  Future<void> _handleAutoLogout() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );

    if (userProvider.currentUser != null) {
      // Update the login status to logged out
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      LoginStatus updatedStatus;

      if (loginStatusProvider.todayLoginStatus?.id != null) {
        // Update existing record
        updatedStatus = LoginStatus(
          id: loginStatusProvider.todayLoginStatus!.id,
          workerId: userProvider.currentUser!.id!,
          date: today,
          loginTime: loginStatusProvider.todayLoginStatus?.loginTime,
          logoutTime: currentTime,
          isLoggedIn: false,
        );
      } else {
        // Create new record
        updatedStatus = LoginStatus(
          workerId: userProvider.currentUser!.id!,
          date: today,
          loginTime: loginStatusProvider.todayLoginStatus?.loginTime,
          logoutTime: currentTime,
          isLoggedIn: false,
        );
      }

      await loginStatusProvider.updateLoginStatus(updatedStatus);

      // Also update attendance record with logout time
      await attendanceProvider.markLogout(
        workerId: userProvider.currentUser!.id!,
        outTime: currentTime,
      );

      Fluttertoast.showToast(
        msg: 'You have been marked absent by admin. Auto-logout performed.',
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );

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

    final result = await loginStatusProvider.workerLogin(
      userProvider.currentUser!,
    );

    // If login was successful, also mark attendance
    if (result['success'] == true) {
      final loginStatus = result['loginStatus'] as LoginStatus;
      await attendanceProvider.markLogin(
        workerId: userProvider.currentUser!.id!,
        inTime: loginStatus.loginTime ?? DateFormat('HH:mm:ss').format(DateTime.now()),
        address: loginStatus.loginAddress,
        latitude: loginStatus.loginLatitude,
        longitude: loginStatus.loginLongitude,
      );
    }

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
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );

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

    final result = await loginStatusProvider.workerLogout(
      userProvider.currentUser!,
    );

    // If logout was successful, also mark attendance
    if (result['success'] == true) {
      final loginStatus = loginStatusProvider.todayLoginStatus;
      
      if (loginStatus != null) {
        await attendanceProvider.markLogout(
          workerId: userProvider.currentUser!.id!,
          outTime: loginStatus.logoutTime ?? DateFormat('HH:mm:ss').format(DateTime.now()),
          address: loginStatus.logoutAddress,
          latitude: loginStatus.logoutLatitude,
          longitude: loginStatus.logoutLongitude,
        );
      }
    }

    setState(() {
      _isLoading = false;
    });

    Fluttertoast.showToast(
      msg: result['message'],
      backgroundColor: result['success'] ? Colors.green : Colors.red,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  // Quick action card builder
  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = loginStatusProvider.isLoggedIn;
    final user = userProvider.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Welcome Card with Profile Image
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true 
                              ? user!.name[0].toUpperCase() 
                              : 'W',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Welcome text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            user?.name ?? 'Worker',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Today is ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Enhanced Login/Logout Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoggedIn
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isLoggedIn ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn
                                  ? 'You are logged in'
                                  : 'You are logged out',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (isLoggedIn &&
                                loginStatusProvider.todayLoginStatus != null)
                              Text(
                                'Since: ${loginStatusProvider.todayLoginStatus!.loginTime}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
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
                            : (isLoggedIn ? _handleLogoutWithConfirmation : _handleLogin),
                        icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
                        label: Text(
                          isLoggedIn ? 'Logout' : 'Login',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isLoggedIn
                              ? Colors.red
                              : Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Quick Actions Section
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate item height based on screen size
                  double itemHeight =
                      (constraints.maxWidth / 2 - 15) *
                      1.2; // Maintain aspect ratio
                  double totalHeight =
                      itemHeight * 2 + 15; // 2 rows with spacing

                  return SizedBox(
                    height: totalHeight,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.2, // Width to height ratio
                      children: [
                        _buildEnhancedQuickActionCard(
                          context,
                          title: 'My Profile',
                          icon: Icons.person,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildEnhancedQuickActionCard(
                          context,
                          title: 'My Attendance',
                          icon: Icons.check_circle,
                          color: const Color(0xFF1E88E5),
                          onTap: () {
                            // Navigate to attendance tab
                            final parentState = context
                                .findAncestorStateOfType<
                                  _WorkerDashboardScreenState
                                >();
                            parentState?.setState(() {
                              parentState._currentIndex = 1;
                            });
                          },
                        ),
                        _buildEnhancedQuickActionCard(
                          context,
                          title: 'My Advance',
                          icon: Icons.history,
                          color: Colors.teal,
                          onTap: () {
                            // Navigate to advance tab
                            final parentState = context
                                .findAncestorStateOfType<
                                  _WorkerDashboardScreenState
                                >();
                            parentState?.setState(() {
                              parentState._currentIndex = 3;
                            });
                          },
                        ),
                        _buildEnhancedQuickActionCard(
                          context,
                          title: 'Advance Request',
                          icon: Icons.payment,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RequestAdvanceScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced quick action card with better design
  Widget _buildEnhancedQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      icon,
                      size: 32,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Handle logout with confirmation dialog
  Future<void> _handleLogoutWithConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to logout and save today\'s location?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Handle worker logout directly
                _handleLogout();
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
