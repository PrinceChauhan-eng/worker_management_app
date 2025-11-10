import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../models/user.dart';
import '../models/login_status.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/login_status_provider.dart';
import '../providers/base_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class EnhancedAttendanceScreen extends StatefulWidget {
  const EnhancedAttendanceScreen({super.key});

  @override
  State<EnhancedAttendanceScreen> createState() => _EnhancedAttendanceScreenState();
}

class _EnhancedAttendanceScreenState extends State<EnhancedAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isLoading = false;
  final Map<int, bool> _attendanceStatus = {};
  final Map<int, String> _inTime = {};
  final Map<int, String> _outTime = {};
  final Map<int, int?> _attendanceIds = {}; // Track existing attendance record IDs
  String _searchQuery = '';
  List<Attendance> _filteredRecords = [];
  final bool _showRecords = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadWorkers();
      _loadExistingAttendance();
      _loadAttendanceRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingAttendance() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Load attendances for the selected date
    await attendanceProvider.loadAttendances();
    
    // Clear existing maps
    _attendanceStatus.clear();
    _inTime.clear();
    _outTime.clear();
    _attendanceIds.clear();
    
    // Populate with existing attendance data for the selected date
    for (var worker in userProvider.workers) {
      if (worker.role == 'worker') {
        final existingAttendance = attendanceProvider.attendances
            .where((att) => att.workerId == worker.id && att.date == _selectedDate)
            .toList();
        
        if (existingAttendance.isNotEmpty) {
          final att = existingAttendance.first;
          _attendanceIds[worker.id!] = att.id;
          _attendanceStatus[worker.id!] = att.present;
          if (att.inTime.isNotEmpty) _inTime[worker.id!] = att.inTime;
          if (att.outTime.isNotEmpty) _outTime[worker.id!] = att.outTime;
        } else {
          // Set default values for new attendance records
          _attendanceStatus[worker.id!] = false;
          _inTime[worker.id!] = '09:00';
          _outTime[worker.id!] = '17:00';
        }
      }
    }
    
    setState(() {});
  }

  Future<void> _loadAttendanceRecords() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.loadAttendances();
    _filteredRecords = List.from(attendanceProvider.attendances);
    setState(() {});
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      // Load existing attendance for the newly selected date
      await _loadExistingAttendance();
    }
  }

  _saveAttendance() async {
    setState(() {
      _isLoading = true;
    });

    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    bool allSaved = true;

    for (var worker in userProvider.workers) {
      if (worker.role == 'worker') {
        // Check if we have attendance data for this worker
        bool isPresent = _attendanceStatus[worker.id!] ?? false;
        String inTime = _inTime[worker.id!] ?? '09:00';
        String outTime = _outTime[worker.id!] ?? '17:00';
        
        // Get existing attendance ID if available
        int? attendanceId = _attendanceIds[worker.id!];

        // Create or update attendance object
        final attendance = Attendance(
          id: attendanceId, // Will be null for new records
          workerId: worker.id!,
          date: _selectedDate,
          inTime: isPresent ? inTime : '',
          outTime: isPresent ? outTime : '',
          present: isPresent,
        );

        bool success;
        if (attendanceId != null) {
          // Update existing attendance record
          success = await attendanceProvider.updateAttendance(attendance);
        } else {
          // Insert new record for both present and absent workers
          success = await attendanceProvider.addAttendance(attendance);
        }
        
        if (!success) {
          allSaved = false;
        }
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (allSaved) {
      Fluttertoast.showToast(
        msg: 'Attendance saved for $_selectedDate',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      // Reload attendance data to reflect changes
      await _loadExistingAttendance();
      await _loadAttendanceRecords();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to save attendance. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  _updateTime(int workerId, bool isInTime, TimeOfDay selectedTime) {
    String timeString = '${selectedTime.hour}:${selectedTime.minute}';
    if (isInTime) {
      setState(() {
        _inTime[workerId] = timeString;
      });
    } else {
      setState(() {
        _outTime[workerId] = timeString;
      });
    }
  }

  _selectTime(BuildContext context, int workerId, bool isInTime) async {
    TimeOfDay initialTime = isInTime
        ? const TimeOfDay(hour: 9, minute: 0)
        : const TimeOfDay(hour: 17, minute: 0);

    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: initialTime);

    if (picked != null) {
      _updateTime(workerId, isInTime, picked);
    }
  }

  void _filterRecords() {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    if (_searchQuery.isEmpty) {
      _filteredRecords = List.from(attendanceProvider.attendances);
    } else {
      _filteredRecords = attendanceProvider.attendances.where((attendance) {
        // Filter by date or worker name
        return attendance.date.contains(_searchQuery) ||
            _getWorkerName(attendance.workerId).toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  String _getWorkerName(int workerId) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final worker = userProvider.workers.firstWhere((user) => user.id == workerId);
      return worker.name;
    } catch (e) {
      return 'Unknown Worker';
    }
  }

  Widget _buildSessionsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worker Sessions',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'View and manage current worker sessions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<LoginStatusProvider>(
              builder: (context, loginStatusProvider, _) {
                return FutureBuilder<List<LoginStatus>>(
                  future: loginStatusProvider.getCurrentlyLoggedInWorkers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }

                    final loggedInWorkers = snapshot.data ?? [];

                    if (loggedInWorkers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No workers currently logged in',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Workers will appear here when they log in',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: loggedInWorkers.length,
                      itemBuilder: (context, index) {
                        final loginStatus = loggedInWorkers[index];
                        return _buildSessionItem(context, loginStatus);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, LoginStatus loginStatus) {
    return FutureBuilder<User?>(
      future: Provider.of<UserProvider>(context, listen: false).getUser(loginStatus.workerId),
      builder: (context, snapshot) {
        final worker = snapshot.data;
        final workerName = worker?.name ?? 'Unknown Worker';
        final loginTime = (loginStatus.loginTime?.isNotEmpty ?? false)
            ? DateFormat('hh:mm a').format(DateFormat('HH:mm:ss').parse(loginStatus.loginTime!))
            : 'Unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4CAF50),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
            ),
            title: Text(
              workerName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Logged in at $loginTime',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Session ID: ${loginStatus.id}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                // Mark worker as logged out
                _markWorkerAsLoggedOut(context, loginStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                minimumSize: const Size(80, 30),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
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
        Fluttertoast.showToast(msg: 'Worker not found');
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
      Fluttertoast.showToast(msg: '${worker.name} has been logged out');

      // Refresh the tab
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error logging out worker: $e');
    }
  }

  int _getPresentCount(List<Attendance> records) {
    return records.where((att) => att.present).length;
  }

  int _getAbsentCount(List<Attendance> records) {
    return records.where((att) => !att.present).length;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final workers = userProvider.workers
        .where((user) => user.role == 'worker')
        .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance Management',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF1E88E5),
              labelColor: const Color(0xFF1E88E5),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Mark Attendance'),
                Tab(text: 'Records'),
                Tab(text: 'Sessions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Mark Attendance Tab
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark Attendance',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Select date and mark attendance for workers',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Date Selector
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _selectedDate,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Workers List
                      Expanded(
                        child: ListView.builder(
                          itemCount: workers.length,
                          itemBuilder: (context, index) {
                            final worker = workers[index];
                            bool isPresent = _attendanceStatus[worker.id!] ?? false;
                            String inTimeString = _inTime[worker.id!] ?? '09:00';
                            String outTimeString = _outTime[worker.id!] ?? '17:00';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFF1E88E5),
                                          child: Text(
                                            worker.name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                worker.name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Text(
                                                worker.phone,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Present/Absent Switch
                                        Switch(
                                          value: isPresent,
                                          onChanged: (value) {
                                            setState(() {
                                              _attendanceStatus[worker.id!] = value;
                                            });
                                          },
                                          activeThumbColor: const Color(0xFF4CAF50),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Time Pickers (only if present)
                                    if (isPresent)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'In Time',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _selectTime(
                                                      context, worker.id!, true),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey[300]!),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          inTimeString,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.access_time,
                                                          size: 18,
                                                          color: Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Out Time',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _selectTime(
                                                      context, worker.id!, false),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey[300]!),
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          outTimeString,
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.access_time,
                                                          size: 18,
                                                          color: Colors.grey,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      CustomButton(
                        text: 'Save Attendance',
                        onPressed: _saveAttendance,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
                // Records Tab
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Records',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'View and manage attendance records',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: const Color(0xFF4CAF50),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_getPresentCount(attendanceProvider.attendances)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Present',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Card(
                              color: const Color(0xFFF44336),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_getAbsentCount(attendanceProvider.attendances)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Absent',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Card(
                              color: const Color(0xFF2196F3),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${attendanceProvider.attendances.length}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Total',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _filterRecords();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by date or worker name...',
                            hintStyle: GoogleFonts.poppins(),
                            prefixIcon: const Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Records List
                      Expanded(
                        child: attendanceProvider.state == ViewState.busy
                            ? const Center(child: CircularProgressIndicator())
                            : attendanceProvider.attendances.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.assignment,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No attendance records found',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Mark attendance to see records here',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: attendanceProvider.attendances.length,
                                    itemBuilder: (context, index) {
                                      final attendance = attendanceProvider.attendances[index];
                                      final workerName = _getWorkerName(attendance.workerId);
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: attendance.present
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFF44336),
                                            child: Icon(
                                              attendance.present
                                                  ? Icons.check
                                                  : Icons.close,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(
                                            workerName,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                attendance.date,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (attendance.present)
                                                Text(
                                                  '${attendance.inTime} - ${attendance.outTime}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          trailing: Text(
                                            attendance.present ? 'Present' : 'Absent',
                                            style: GoogleFonts.poppins(
                                              color: attendance.present
                                                  ? const Color(0xFF4CAF50)
                                                  : const Color(0xFFF44336),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                // Sessions Tab
                _buildSessionsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}