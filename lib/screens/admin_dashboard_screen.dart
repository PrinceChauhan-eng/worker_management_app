import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_menu_button.dart';
import '../models/user.dart';
import 'add_worker_screen.dart';
import 'login_status_screen.dart';
import 'salary_advance_screen.dart';
import 'manage_advances_screen.dart';
import 'process_salary_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _statistics = {
    'total': 0,
    'loggedIn': 0,
    'absent': 0,
  };
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingStats = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);

    await userProvider.loadWorkers();
    _statistics = await loginStatusProvider.getLoginStatistics();

    setState(() {
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final adminName = userProvider.currentUser?.name ?? 'Admin';
    final workers = userProvider.workers.where((u) => u.role == 'worker').toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome, $adminName 👨‍💼',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          const ProfileMenuButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
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
              _isLoadingStats
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Workers',
                            value: _statistics['total'].toString(),
                            icon: Icons.people,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Logged In',
                            value: _statistics['loggedIn'].toString(),
                            icon: Icons.check_circle,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Absent',
                            value: _statistics['absent'].toString(),
                            icon: Icons.cancel,
                            color: const Color(0xFFF44336),
                          ),
                        ),
                      ],
                    ),
              
              const SizedBox(height: 30),
              
              // Worker List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workers List',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddWorkerScreen(),
                        ),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Worker',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              workers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No workers yet',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddWorkerScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Worker'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: workers.length,
                      itemBuilder: (context, index) {
                        return _buildWorkerCard(context, workers[index]);
                      },
                    ),
              
              const SizedBox(height: 30),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5,
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
                  _buildQuickActionCard(
                    context,
                    title: 'Salary & Advance',
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
                    title: 'Process Salary',
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
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildWorkerCard(BuildContext context, User worker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          child: Text(
            worker.name[0].toUpperCase(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          worker.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  worker.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.currency_rupee, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 5),
                Text(
                  '${worker.wage}/day',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.payments, color: Color(0xFFFFA726)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalaryAdvanceScreen(),
                  ),
                );
              },
              tooltip: 'Salary & Advance',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () {
                _showWorkerOptions(context, worker);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerOptions(BuildContext context, User worker) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
              title: const Text('Edit Worker'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWorkerScreen(editUser: worker),
                  ),
                ).then((_) => _loadData());
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Color(0xFF1E88E5)),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showWorkerDetails(context, worker);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments, color: Color(0xFFFFA726)),
              title: const Text('Salary & Advance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SalaryAdvanceScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
              title: const Text('Login Status'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginStatusScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFF44336)),
              title: const Text('Delete Worker'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteWorker(context, worker);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerDetails(BuildContext context, User worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          worker.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', worker.phone),
            _buildDetailRow('Daily Wage', '₹${worker.wage}'),
            _buildDetailRow('Join Date', worker.joinDate.split(' ')[0]),
            if (worker.workLocationAddress != null)
              _buildDetailRow('Work Location', worker.workLocationAddress!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWorker(BuildContext context, User worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Worker',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${worker.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWorker(worker);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorker(User worker) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    bool success = await userProvider.deleteUser(worker.id!);
    
    if (success) {
      Fluttertoast.showToast(
        msg: 'Worker deleted successfully',
        backgroundColor: Colors.green,
      );
      _loadData();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to delete worker',
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.grey[800],
              ),
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