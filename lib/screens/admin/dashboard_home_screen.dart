import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/login_status_provider.dart';
import '../login_status_screen.dart';
import '../manage_advances_screen.dart';
import '../salary_advance_screen.dart';
import '../process_salary_screen.dart';
import '../salary_slips_screen.dart';
import '../reports_screen.dart';
import '../settings_screen.dart';

class DashboardHomeScreen extends StatelessWidget {
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
                  
                  final stats = snapshot.data ?? {'total': 0, 'loggedIn': 0, 'absent': 0};
                  
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
                  double itemHeight = (constraints.maxWidth / 2 - 15) * 1.2; // Maintain aspect ratio
                  double totalHeight = itemHeight * 4 + 15 * 3; // 4 rows with spacing
                  
                  return SizedBox(
                    height: totalHeight,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling since we're in a scrollable parent
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
                                builder: (context) => const ManageAdvancesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Salary Management',
                          icon: Icons.account_balance_wallet,
                          color: const Color(0xFFFFA726),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SalaryAdvanceScreen(),
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
                                builder: (context) => const ProcessSalaryScreen(),
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
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
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
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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