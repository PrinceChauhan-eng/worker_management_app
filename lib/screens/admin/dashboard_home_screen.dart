import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/login_status_provider.dart';
import '../../models/user.dart';
import '../../models/login_status.dart';
import '../../widgets/enhanced_dashboard_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../login_status_screen.dart';
import '../manage_advances_screen.dart';
import '../advance_only_screen.dart';
import '../process_salary_screen.dart';
import '../salary_slips_screen.dart';
import '../reports_screen.dart';
import '../settings_screen.dart';

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

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

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
                'Manage your workforce efficiently',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // Statistics Cards
              Text(
                'Today\'s Overview',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 15),
              Consumer2<LoginStatusProvider, UserProvider>(
                builder: (context, loginStatusProvider, userProvider, child) {
                  // Use a post-frame callback to avoid setState during build
                  return FutureBuilder<Map<String, int>>(
                    future: _getStatistics(context, userProvider),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stats =
                          snapshot.data ?? {'total': 0, 'loggedIn': 0, 'absent': 0};

                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total Workers',
                              value: stats['total'].toString(),
                              icon: Icons.people,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Logged In',
                              value: stats['loggedIn'].toString(),
                              icon: Icons.check_circle,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Absent',
                              value: stats['absent'].toString(),
                              icon: Icons.cancel,
                              color: const Color(0xFFF44336),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 30),

              // Worker Attendance Session Card
              _buildWorkerAttendanceSessionCard(context),

              const SizedBox(height: 30),

              // Quick Actions - Static section
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
                      itemHeight * 4 + 15 * 3; // 4 rows with spacing

                  return SizedBox(
                    height: totalHeight,
                    child: GridView.count(
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling since we're in a scrollable parent
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.2,
                      children: [
                        _buildQuickActionCard(
                          context,
                          title: 'Login Status',
                          icon: Icons.check_circle,
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginStatusScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Manage Advances',
                          icon: Icons.approval,
                          color: const Color(0xFF9C27B0),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageAdvancesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Advance Management',
                          icon: Icons.account_balance_wallet,
                          color: const Color(0xFFFFA726),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdvanceOnlyScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Process Payroll',
                          icon: Icons.payments_outlined,
                          color: const Color(0xFFE91E63),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProcessSalaryScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Salary Paid',
                          icon: Icons.receipt,
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SalarySlipsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Reports',
                          icon: Icons.bar_chart,
                          color: const Color(0xFFAB47BC),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Settings',
                          icon: Icons.settings,
                          color: const Color(0xFF26C6DA),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Add bottom padding
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getStatistics(BuildContext context, UserProvider userProvider) async {
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );
    
    // Get today's login status data
    final todayLoginStatus = await loginStatusProvider.getTodayLoginStatus();
    
    // Get total workers from user provider
    final totalWorkers = userProvider.workers
        .where((user) => user.role == 'worker')
        .length;
    
    // Use login status data for accurate statistics
    final loggedInCount = todayLoginStatus.where((s) => s['is_logged_in'] == true).length;
    final absentCount = totalWorkers - loggedInCount;
    
    return {
      'total': totalWorkers,
      'loggedIn': loggedInCount, // Use logged in count from login status
      'absent': absentCount > 0 ? absentCount.toInt() : 0,
    };
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return EnhancedDashboardCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      isAnimated: true,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
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

  Widget _buildWorkerAttendanceSessionCard(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Worker Attendance Sessions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
                Icon(
                  Icons.people,
                  color: const Color(0xFF1E88E5),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<LoginStatusProvider>(
              builder: (context, loginStatusProvider, _) {
                return FutureBuilder<List<LoginStatus>>(
                  future: loginStatusProvider.getCurrentlyLoggedInWorkers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    final loggedInWorkers = snapshot.data ?? [];

                    if (loggedInWorkers.isEmpty) {
                      return Center(
                        child: Text(
                          'No workers currently logged in',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: loggedInWorkers.length,
                        itemBuilder: (context, index) {
                          final loginStatus = loggedInWorkers[index];
                          return _buildWorkerSessionItem(context, loginStatus);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerSessionItem(BuildContext context, LoginStatus loginStatus) {
    return FutureBuilder<User?>(
      future: Provider.of<UserProvider>(context, listen: false).getUser(loginStatus.workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(height: 60);
        }
        
        final worker = snapshot.data;
        final workerName = worker?.name ?? 'Unknown Worker';
        final loginTime = formatTimeString(loginStatus.loginTime, loginStatus.date);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            title: Text(
              workerName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Logged in at $loginTime',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}