import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/login_status_provider.dart';
import '../../models/user.dart';
import '../../models/attendance.dart';
import '../../models/login_status.dart'; // Add this import
import '../admin/worker_attendance_screen.dart';
import '../admin/worker_profile_view_screen.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/dashboard_summary_row.dart';
import '../process_salary_screen.dart';
import '../admin/advance_management_screen.dart';
import '../reports_screen.dart';

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
              const SizedBox(height: 24), // Uniform vertical spacing
              Text(
                'Manage your workforce efficiently',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24), // Uniform vertical spacing

              // Statistics Cards
              Text(
                'Today\'s Overview',
                style: GoogleFonts.poppins(
                  fontSize: 20, // Increased font size
                  fontWeight: FontWeight.w600, // Increased font weight
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

                      // Replace the Row of EnhancedDashboardCard widgets with DashboardSummaryRow
                      return DashboardSummaryRow(
                        totalWorkers: stats['total'] ?? 0,
                        loggedIn: stats['loggedIn'] ?? 0,
                        absent: stats['absent'] ?? 0,
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
                  fontSize: 20, // Increased font size
                  fontWeight: FontWeight.w600, // Increased font weight
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
                      itemHeight * 2 + 15 * 1; // 2 rows with spacing

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
                          title: 'Edit Attendance',
                          icon: Icons.edit_calendar, // Filled icon
                          color: const Color(0xFF43A047),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WorkerAttendanceScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Advance Management',
                          icon: Icons.account_balance_wallet, // Filled icon
                          color: const Color(0xFF8E24AA),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdvanceManagementScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Process Payroll',
                          icon: Icons.payments, // Filled icon
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
                          title: 'Reports',
                          icon: Icons.bar_chart, // Filled icon
                          color: const Color(0xFF1976D2),
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
              const SizedBox(height: 24), // Uniform vertical spacing
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
      child: const _WorkerAttendanceSessionCard(), // Use the new stateful widget
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

class _WorkerAttendanceSessionCard extends StatefulWidget {
  const _WorkerAttendanceSessionCard();

  @override
  State<_WorkerAttendanceSessionCard> createState() => _WorkerAttendanceSessionCardState();
}

class _WorkerAttendanceSessionCardState extends State<_WorkerAttendanceSessionCard> {
  int _page = 0;
  List<Attendance> _todayAttendance = [];
  bool _loadingAttendance = false;
  
  // Add state variables for search, filter, and sort
  String _searchQuery = "";
  String _filter = "ALL"; // ALL | PRESENT | ABSENT | LOGGED_IN
  String _sort = "DEFAULT"; // DEFAULT | NAME_AZ | NAME_ZA | STATUS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTodayAttendance());
  }

  Future<void> _loadTodayAttendance() async {
    setState(() => _loadingAttendance = true);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final list = await provider.getTodayAttendancePaged(page: _page);
    setState(() {
      _todayAttendance = list;
      _loadingAttendance = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                Icons.people, // Filled icon
                color: const Color(0xFF1E88E5),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add UI controls for search, filter, and sort
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search worker...",
                    prefixIcon: Icon(Icons.search), // Filled icon
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim().toLowerCase());
                    _loadTodayAttendance();
                  },
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                onSelected: (val) {
                  setState(() => _filter = val);
                  _loadTodayAttendance();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: "ALL", child: Text("All")),
                  const PopupMenuItem(value: "PRESENT", child: Text("Present")),
                  const PopupMenuItem(value: "LOGGED_IN", child: Text("Logged In")),
                  const PopupMenuItem(value: "ABSENT", child: Text("Absent")),
                ],
                child: const Icon(Icons.filter_alt), // Filled icon
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                onSelected: (val) {
                  setState(() => _sort = val);
                  _loadTodayAttendance();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: "DEFAULT", child: Text("Default")),
                  const PopupMenuItem(value: "NAME_AZ", child: Text("Name A-Z")),
                  const PopupMenuItem(value: "NAME_ZA", child: Text("Name Z-A")),
                  const PopupMenuItem(value: "STATUS", child: Text("Status Order")),
                ],
                child: const Icon(Icons.sort), // Filled icon
              ),
            ],
          ),
          const SizedBox(height: 10),
          _loadingAttendance
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    ..._todayAttendance.map((att) {
                      final timeIn = att.inTime.isNotEmpty
                          ? DateFormat('hh:mm a').format(DateFormat("HH:mm:ss").parse(att.inTime))
                          : '--';

                      final timeOut = att.outTime.isNotEmpty
                          ? DateFormat('hh:mm a').format(DateFormat("HH:mm:ss").parse(att.outTime))
                          : '--';

                      String status;
                      Color color;

                      if (!att.present) {
                        status = 'Absent';
                        color = Colors.red;
                      } else if (att.present && att.outTime.isEmpty) {
                        status = 'Logged In';
                        color = Colors.orange;
                      } else {
                        status = 'Present';
                        color = Colors.green;
                      }

                      return FutureBuilder<User?>(
                        future: Provider.of<UserProvider>(context, listen: false).getUser(att.workerId),
                        builder: (context, snapshot) {
                          final workerName = snapshot.data?.name ?? 'Unknown Worker';
                          
                          // Apply filtering based on search query and filter selection
                          bool matchesSearch = _searchQuery.isEmpty || workerName.toLowerCase().contains(_searchQuery);
                          bool matchesFilter = true;
                          
                          if (_filter == "PRESENT") {
                            matchesFilter = att.present && att.outTime.isNotEmpty;
                          } else if (_filter == "LOGGED_IN") {
                            matchesFilter = att.present && att.outTime.isEmpty;
                          } else if (_filter == "ABSENT") {
                            matchesFilter = !att.present;
                          }
                          
                          // If item doesn't match filters, don't show it
                          if (!matchesSearch || !matchesFilter) {
                            return const SizedBox.shrink(); // Hide this item
                          }
                          
                          return ListTile(
                            onTap: () {
                              // Show quick profile popup
                              _showWorkerQuickProfile(context, snapshot.data!);
                            },
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundImage: snapshot.data?.profilePhoto != null
                                  ? NetworkImage(snapshot.data!.profilePhoto!)
                                  : null,
                              child: snapshot.data?.profilePhoto == null
                                  ? const Icon(Icons.person)
                                  : null,
                              backgroundColor: color.withOpacity(.2),
                            ),
                            title: Text(workerName),
                            subtitle: Text("In: $timeIn   |   Out: $timeOut"),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withOpacity(.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      );
                    }).where((widget) => widget is! SizedBox), // Remove hidden items

                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _page == 0
                              ? null
                              : () {
                                  setState(() => _page--);
                                  _loadTodayAttendance();
                                },
                          child: const Text("<< Prev"),
                        ),
                        Text("Page ${_page + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: _todayAttendance.length < 5
                              ? null
                              : () {
                                  setState(() => _page++);
                                  _loadTodayAttendance();
                                },
                          child: const Text("Next >>"),
                        ),
                      ],
                    )
                  ],
                ),
        ],
      ),
    );
  }

  void _showWorkerQuickProfile(BuildContext context, User worker) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // profile photo
              CircleAvatar(
                radius: 40,
                backgroundImage: worker.profilePhoto != null
                    ? NetworkImage(worker.profilePhoto!)
                    : null,
                child: worker.profilePhoto == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),

              const SizedBox(height: 10),

              Text(
                worker.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                worker.phone ?? "No phone",
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkerProfileViewScreen(worker: worker),
                    ),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text("View Full Profile"),
              ),
            ],
          ),
        );
      },
    );
  }
}
