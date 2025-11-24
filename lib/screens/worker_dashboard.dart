// Dashboard Home Screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/base_provider.dart';
import '../widgets/hover_toggle_button.dart';

// Helper function to format time strings with proper timezone conversion
String formatTimeString(String? timeStr, String dateStr) {
  if (timeStr == null || timeStr.isEmpty) return 'N/A';
  try {
    // If backend stored full ISO like 2025-11-20T13:16:30Z, parse and convert to local
    DateTime dt;
    if (timeStr.contains('T')) {
      dt = DateTime.parse(timeStr).toLocal();
    } else {
      // If you store just HH:mm:ss along with dateStr:
      dt = DateTime.parse('$dateStr $timeStr').toLocal();
    }
    return DateFormat.Hms().format(dt);
  } catch (e) {
    return timeStr;
  }
}

class _DashboardHome extends StatefulWidget {
  const _DashboardHome();

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  final bool _isLoggedIn = false;
  final String _loginTime = '';
  final String _logoutTime = '';

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
        // Show skeleton while loading
        if (userProvider.state == ViewState.busy && userProvider.currentUser == null) {
          return _buildWelcomeSkeleton();
        }

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
                      'Today is ${DateFormat('EEEE, MMMM d').format(DateTime.now().toLocal())}',
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

  Widget _buildWelcomeSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 100,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 24,
                  width: 150,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  width: 200,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Show skeleton while loading initial data
        if (userProvider.state == ViewState.busy && userProvider.currentUser == null) {
          return _buildAttendanceSkeleton();
        }

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
                              // Handle toggle change
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
                              'Login Time: ${formatTimeString(loginStatus?.loginTime, loginStatus?.date ?? '')}',
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
                              'Logout Time: ${formatTimeString(loginStatus?.logoutTime, loginStatus?.date ?? '')}',
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
                          // Handle login/logout action
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
      },
    );
  }

  Widget _buildAttendanceSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            height: 20,
            width: 150,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 16,
                width: 80,
                color: Colors.grey[300],
              ),
              Container(
                width: 80,
                height: 30,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 14,
            width: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildSalarySection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Show skeleton while loading
        if (userProvider.state == ViewState.busy && userProvider.currentUser == null) {
          return _buildSalarySkeleton();
        }

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
                    'Monthly Salary',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '₹15,000',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advance Taken',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '₹2,000',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Salary',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '₹13,000',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to salary details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalarySkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            height: 20,
            width: 150,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 16,
                width: 100,
                color: Colors.grey[300],
              ),
              Container(
                height: 16,
                width: 80,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 16,
                width: 100,
                color: Colors.grey[300],
              ),
              Container(
                height: 16,
                width: 80,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 16,
                width: 100,
                color: Colors.grey[300],
              ),
              Container(
                height: 16,
                width: 80,
                color: Colors.grey[300],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Show skeleton while loading
        if (userProvider.state == ViewState.busy && userProvider.currentUser == null) {
          return _buildLocationSkeleton();
        }

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
      },
    );
  }

  Widget _buildLocationSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            height: 20,
            width: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 14,
                  width: 200,
                  color: Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 40,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}