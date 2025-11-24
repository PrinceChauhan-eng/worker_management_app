import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../process_salary_screen.dart';
import '../manage_advances_screen.dart';
import '../salary_advance_screen.dart';
import '../reports_screen.dart';
import 'automated_salary_screen.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salary Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Process salaries and manage advances',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate item height based on screen size
                double itemHeight =
                    (constraints.maxWidth / 2 - 20) *
                    1.2; // Maintain aspect ratio
                double totalHeight = itemHeight * 2 + 20; // 2 rows with spacing

                return SizedBox(
                  height: totalHeight,
                  child: GridView.count(
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable scrolling since we're in a scrollable parent
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.2,
                    children: [
                      buildFeatureCard(
                        context,
                        title: 'Process Salary',
                        icon: Icons.payments,
                        color: const Color(0xFF4CAF50),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProcessSalaryScreen(),
                            ),
                          );
                        },
                      ),
                      buildFeatureCard(
                        context,
                        title: 'Manage Advances',
                        icon: Icons.account_balance,
                        color: const Color(0xFFFF9800),
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
                      buildFeatureCard(
                        context,
                        title: 'Automated Salary',
                        icon: Icons.auto_graph,
                        color: const Color(0xFF1E88E5),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AutomatedSalaryScreen(),
                            ),
                          );
                        },
                      ),
                      buildFeatureCard(
                        context,
                        title: 'Salary & Advance',
                        icon: Icons.account_balance_wallet,
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SalaryAdvanceScreen(),
                            ),
                          );
                        },
                      ),
                      buildFeatureCard(
                        context,
                        title: 'Reports',
                        icon: Icons.bar_chart,
                        color: const Color(0xFF9C27B0),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeatureCard(
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
              color: Colors.grey.withValues(alpha: 0.1),
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
                color: color.withValues(alpha: 0.1),
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
