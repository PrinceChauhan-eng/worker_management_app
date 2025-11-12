import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/hover_toggle_button.dart';
import '../widgets/summary_card.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _currentIndex = 0;
  final bool _isLoading = false;

  final List<Widget> _screens = [
    const _DashboardHome(),
    const _AttendanceScreen(),
    const _SalaryScreen(),
    const _AdvanceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      // Load user data if not already loaded
      if (userProvider.currentUser != null) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: _buildAppBar(context, themeProvider),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
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
            icon: Icon(Icons.history),
            label: 'Advances',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return AppBar(
      title: Text(
        'Worker Dashboard',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Notification icon
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    // Navigate to notifications screen
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
        // Theme toggle button
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}

// Dashboard Home Screen
class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _loginTime = '';
  String _logoutTime = '';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 30),
              _buildAttendanceSection(),
              const SizedBox(height: 30),
              _buildSalarySection(),
              const SizedBox(height: 30),
              _buildLocationSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;
        if (user == null) {
          return const SizedBox();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.15),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today is ${DateFormat('EEEE, MMMM d').format(DateTime.now())}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Attendance',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<LoginStatusProvider>(
            builder: (context, loginStatusProvider, child) {
              final loginStatus = loginStatusProvider.todayLoginStatus;
              
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status:',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      HoverToggleButton(
                        labelOn: 'Logged In',
                        labelOff: 'Logged Out',
                        initialValue: loginStatus?.isLoggedIn ?? false,
                        onChanged: (value) {
                          _handleLoginToggle(value);
                        },
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (loginStatus?.isLoggedIn == true) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.login,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Login Time: ${loginStatus?.loginTime ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Logout Time: ${loginStatus?.logoutTime ?? 'Not logged out'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'You are currently logged out',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _handleLoginAction();
                    },
                    icon: Icon(
                      loginStatus?.isLoggedIn == true
                          ? Icons.logout
                          : Icons.login,
                    ),
                    label: Text(
                      loginStatus?.isLoggedIn == true
                          ? 'Logout'
                          : 'Login',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salary Summary',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              HoverToggleButton(
                labelOn: 'Paid',
                labelOff: 'Unpaid',
                initialValue: false,
                onChanged: (value) {
                  // Handle salary status toggle
                },
                activeColor: Colors.green,
                inactiveColor: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SummaryCard(
            title: 'This Month',
            value: '₹15,000',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFFFFC107),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Work Location: Sector 12, Delhi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Fetch current location
            },
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Fetch Current Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLoginToggle(bool isLoggedIn) async {
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    if (isLoggedIn) {
      _loginTime = DateFormat('HH:mm').format(DateTime.now());
    } else {
      _logoutTime = DateFormat('HH:mm').format(DateTime.now());
    }
  }

  Future<void> _handleLoginAction() async {
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoggedIn) {
        // Logout
        final result = await loginStatusProvider.workerLogout(
          userProvider.currentUser!,
        );
        Fluttertoast.showToast(
          msg: result['message'],
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        );
      } else {
        // Login
        final result = await loginStatusProvider.workerLogin(
          userProvider.currentUser!,
        );
        Fluttertoast.showToast(
          msg: result['message'],
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        );
      }

      setState(() {
        _isLoggedIn = !_isLoggedIn;
        if (_isLoggedIn) {
          _loginTime = DateFormat('HH:mm').format(DateTime.now());
        } else {
          _logoutTime = DateFormat('HH:mm').format(DateTime.now());
        }
        _isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error processing request: $e',
        backgroundColor: Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Placeholder screens for other tabs
class _AttendanceScreen extends StatelessWidget {
  const _AttendanceScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Attendance Screen'),
    );
  }
}

class _SalaryScreen extends StatelessWidget {
  const _SalaryScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Salary Screen'),
    );
  }
}

class _AdvanceScreen extends StatelessWidget {
  const _AdvanceScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Advance Screen'),
    );
  }
}