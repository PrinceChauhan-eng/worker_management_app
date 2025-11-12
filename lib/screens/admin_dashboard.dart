import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/summary_card.dart';
import '../widgets/hover_toggle_button.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/theme_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: _buildAppBar(context, themeProvider),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildStatisticsSection(context),
                const SizedBox(height: 30),
                _buildWorkerManagementSection(context),
                const SizedBox(height: 30),
                _buildQuickActionsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return AppBar(
      title: Text(
        'Admin Dashboard',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your workforce efficiently',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Consumer3<LoginStatusProvider, UserProvider, AttendanceProvider>(
          builder: (context, loginStatusProvider, userProvider, attendanceProvider, child) {
            return FutureBuilder<Map<String, int>>(
              future: _getStatistics(context, userProvider, attendanceProvider),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {
                  'total': 0,
                  'loggedIn': 0,
                  'absent': 0,
                  'paidSalaries': 0,
                };

                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      // Desktop layout
                      return Row(
                        children: [
                          Expanded(
                            child: SummaryCard(
                              title: 'Total Workers',
                              value: stats['total'].toString(),
                              icon: Icons.people,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: SummaryCard(
                              title: 'Logged In',
                              value: stats['loggedIn'].toString(),
                              icon: Icons.check_circle,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: SummaryCard(
                              title: 'Absent',
                              value: stats['absent'].toString(),
                              icon: Icons.cancel,
                              color: const Color(0xFFF44336),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: SummaryCard(
                              title: 'Paid Salaries',
                              value: stats['paidSalaries'].toString(),
                              icon: Icons.account_balance_wallet,
                              color: const Color(0xFFFFC107),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  title: 'Total Workers',
                                  value: stats['total'].toString(),
                                  icon: Icons.people,
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: SummaryCard(
                                  title: 'Logged In',
                                  value: stats['loggedIn'].toString(),
                                  icon: Icons.check_circle,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: SummaryCard(
                                  title: 'Absent',
                                  value: stats['absent'].toString(),
                                  icon: Icons.cancel,
                                  color: const Color(0xFFF44336),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: SummaryCard(
                                  title: 'Paid Salaries',
                                  value: stats['paidSalaries'].toString(),
                                  icon: Icons.account_balance_wallet,
                                  color: const Color(0xFFFFC107),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorkerManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Worker Management',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Workers',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  HoverToggleButton(
                    labelOn: 'Active',
                    labelOff: 'Inactive',
                    initialValue: true,
                    onChanged: (value) {
                      // Handle toggle change
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Worker list would go here
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add worker screen
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Worker'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              // Desktop layout
              return Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Manage Workers',
                      icon: Icons.people,
                      color: const Color(0xFF1E88E5),
                      onTap: () {
                        // Navigate to workers management
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Attendance',
                      icon: Icons.check_circle,
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        // Navigate to attendance management
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Salary Processing',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFFFFC107),
                      onTap: () {
                        // Navigate to salary processing
                      },
                    ),
                  ),
                ],
              );
            } else {
              // Mobile layout
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          title: 'Manage Workers',
                          icon: Icons.people,
                          color: const Color(0xFF1E88E5),
                          onTap: () {
                            // Navigate to workers management
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          title: 'Attendance',
                          icon: Icons.check_circle,
                          color: const Color(0xFF4CAF50),
                          onTap: () {
                            // Navigate to attendance management
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildQuickActionCard(
                    context,
                    title: 'Salary Processing',
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFFFFC107),
                    onTap: () {
                      // Navigate to salary processing
                    },
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, int>> _getStatistics(
    BuildContext context,
    UserProvider userProvider,
    AttendanceProvider attendanceProvider,
  ) async {
    // Get total workers
    final totalWorkers = userProvider.workers
        .where((user) => user.role == 'worker')
        .length;

    // Get attendance statistics
    final attendanceStats = await attendanceProvider.getTodaySummary();
    final presentCount = attendanceStats['present'] ?? 0;
    final absentCount = totalWorkers - presentCount;

    // For paid salaries, we would need to query the salary table
    final paidSalaries = 0; // Placeholder

    return {
      'total': totalWorkers,
      'loggedIn': presentCount,
      'absent': absentCount > 0 ? absentCount : 0,
      'paidSalaries': paidSalaries,
    };
  }
}