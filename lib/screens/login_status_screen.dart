import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/login_status_provider.dart';
import '../models/user.dart';
import '../models/login_status.dart';
import '../widgets/custom_app_bar.dart';
import 'edit_attendance_screen.dart';

class LoginStatusScreen extends StatefulWidget {
  const LoginStatusScreen({super.key});

  @override
  State<LoginStatusScreen> createState() => _LoginStatusScreenState();
}

class _LoginStatusScreenState extends State<LoginStatusScreen> {
  User? _selectedWorker;
  List<LoginStatus> _loginStatuses = [];
  bool _isLoading = false;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadWorkers();

    if (_selectedWorker != null) {
      await _loadLoginStatuses();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadLoginStatuses() async {
    if (_selectedWorker == null) return;

    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
    await loginStatusProvider.loadLoginStatusesByWorkerId(_selectedWorker!.id!);
    
    setState(() {
      _loginStatuses = loginStatusProvider.loginStatuses
          .where((ls) => ls.date.startsWith(_selectedMonth))
          .toList();
    });
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    
    if (picked != null) {
      setState(() {
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
      await _loadLoginStatuses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workers = userProvider.workers.where((u) => u.role == 'worker').toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Login Status',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Login Status',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'View login/logout times and locations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),

            // Worker Selection with enhanced design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<User>(
                  isExpanded: true,
                  hint: Text(
                    'Select Worker',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  value: _selectedWorker,
                  items: workers.map((worker) {
                    return DropdownMenuItem<User>(
                      value: worker,
                      child: Text(
                        worker.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (User? worker) {
                    setState(() {
                      _selectedWorker = worker;
                    });
                    _loadLoginStatuses();
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Month Selection with enhanced design
            if (_selectedWorker != null)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01')),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today, 
                            color: Color(0xFF1E88E5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _selectMonth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_calendar, 
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),

            // Login Status List
            if (_selectedWorker == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Select a worker to view login status',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_loginStatuses.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No login records for selected month',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _loginStatuses.length,
                  itemBuilder: (context, index) {
                    return _buildLoginStatusCard(_loginStatuses[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginStatusCard(LoginStatus status) {
    final bool hasLoggedOut = status.logoutTime != null;
    final String dateStr = DateFormat('EEE, MMM dd').format(DateTime.parse(status.date));

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
      child: Column(
        children: [
          // Date Header
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: hasLoggedOut ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: hasLoggedOut ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                const SizedBox(width: 10),
                Text(
                  dateStr,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hasLoggedOut ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                if (hasLoggedOut)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${status.workingHours.toStringAsFixed(1)} hrs',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'In Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Login/Logout Details
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // Login Info
                _buildTimeRow(
                  icon: Icons.login,
                  label: 'Login',
                  time: status.loginTime ?? '--:--',
                  // Removed address and distance since we're removing location features
                  color: Colors.green,
                ),
                if (hasLoggedOut) ...[
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),
                  // Logout Info
                  _buildTimeRow(
                    icon: Icons.logout,
                    label: 'Logout',
                    time: status.logoutTime ?? '--:--',
                    // Removed address and distance since we're removing location features
                    color: Colors.red,
                  ),
                ],
                const SizedBox(height: 15),
                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditAttendanceScreen(
                            loginStatus: status,
                            workerName: _selectedWorker!.name,
                          ),
                        ),
                      );
                      
                      // If attendance was updated, refresh the list
                      if (result == true) {
                        await _loadLoginStatuses();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      'Edit Attendance',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required String time,
    // Removed address and distance parameters since we're removing location features
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            // Removed distance display since we're removing location features
          ],
        ),
        // Removed address display since we're removing location features
      ],
    );
  }
}