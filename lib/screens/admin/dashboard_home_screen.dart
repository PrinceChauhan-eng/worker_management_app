import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/login_status.dart';
import '../../models/user.dart';
import '../../providers/login_status_provider.dart';
import '../../providers/user_provider.dart';
import '../login_status_screen.dart';
import '../manage_advances_screen.dart';
import '../advance_only_screen.dart';
import '../process_salary_screen.dart';
import '../salary_slips_screen.dart';
import '../reports_screen.dart';
import '../settings_screen.dart';

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
              FutureBuilder<Map<String, int>>(
                future: _getStatistics(context),
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

  Future<Map<String, int>> _getStatistics(BuildContext context) async {
    final loginStatusProvider = Provider.of<LoginStatusProvider>(
      context,
      listen: false,
    );
    return await loginStatusProvider.getLoginStatistics();
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
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
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
        final worker = snapshot.data;
        final workerName = worker?.name ?? 'Unknown Worker';
        final loginTime = (loginStatus.loginTime?.isNotEmpty ?? false)
            ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(loginStatus.loginTime!))
            : 'Unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4CAF50),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              workerName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Logged in at $loginTime',
              style: GoogleFonts.poppins(
                fontSize: 12,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Mark worker as logged out
                _markWorkerAsLoggedOut(context, loginStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                minimumSize: const Size(80, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _markWorkerAsLoggedOut(BuildContext context, LoginStatus loginStatus) async {
    try {
      final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Get worker details
      final worker = await userProvider.getUser(loginStatus.workerId);
      if (worker == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Worker not found')),
        );
        return;
      }

      // Update login status to logged out
      final updatedLoginStatus = LoginStatus(
        id: loginStatus.id,
        workerId: loginStatus.workerId,
        date: loginStatus.date,
        loginTime: loginStatus.loginTime,
        logoutTime: DateFormat('HH:mm:ss').format(DateTime.now()),
        isLoggedIn: false,
      );

      await loginStatusProvider.updateLoginStatus(updatedLoginStatus);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${worker.name} has been logged out'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );

      // Refresh the card
      (context as Element).markNeedsBuild();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out worker: $e'),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }
}
