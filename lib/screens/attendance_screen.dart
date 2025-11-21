import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/login_status_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../services/attendance_service.dart';
import '../utils/logger.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isLoading = false;
  final Map<int, bool> _attendanceStatus = {};
  final Map<int, String> _inTime = {};
  final Map<int, String> _outTime = {};
  final Map<int, int?> _attendanceIds = {}; // Track existing attendance record IDs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadWorkers();
      _loadExistingAttendance(); // Load existing attendance for selected date
    });
  }

  Future<void> _loadExistingAttendance() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Add delay protection
    await attendanceProvider.loadAttendances();
    if (!mounted) return; // prevent setState after dispose
    
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
          // Set default values for new attendance records ONLY for NEW records
          _attendanceStatus[worker.id!] = false;
          _inTime[worker.id!] = '09:00:00';
          _outTime[worker.id!] = '17:00:00';
        }
      }
    }
    
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
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      attendanceProvider.invalidateTodayCache();
      await _loadExistingAttendance();
    }
  }

  // Show error message
  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
    );
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
        
        // Add strong form validation (Fix #6)
        if (isPresent) {
          // Validate in_time and out_time for present workers
          if (inTime.isEmpty) {
            _showError("Enter In Time for ${worker.name}!");
            allSaved = false;
            continue;
          }
          
          if (outTime.isEmpty) {
            _showError("Enter Out Time for ${worker.name}!");
            allSaved = false;
            continue;
          }
        }
        
        // Get existing attendance ID if available
        int? attendanceId = _attendanceIds[worker.id!];

        // Create attendance object with correct payload keys (Fix #2)
        final attendance = Attendance(
          id: attendanceId, // Will be null for new records
          workerId: worker.id!,
          date: _selectedDate,
          inTime: isPresent ? inTime : '',
          outTime: isPresent ? outTime : '',
          present: isPresent, // Fix present toggle (Fix #6)
        );

        // Print the final payload before sending to verify types
        final payload = attendance.toMap();
        print('Final Attendance Payload: $payload');

        bool success;
        if (attendance.id == null) {
          success = await attendanceProvider.addAttendance(attendance);
        } else {
          success = await attendanceProvider.updateAttendance(attendance);
        }
        
        // Sync login status with attendance
        if (success) {
          try {
            final attendanceService = AttendanceService();
            await attendanceService.syncLoginStatusWithAttendance(
              workerId: worker.id!,
              date: _selectedDate,
              inTime: isPresent ? inTime : null,
              outTime: isPresent ? outTime : null,
              present: isPresent ? 1 : 0,
            );
          } catch (e) {
            Logger.error('Error syncing login status with attendance: $e', e);
          }
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
      
      // Refresh login status for all workers to ensure dashboard is updated
      final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
      await loginStatusProvider.refreshToday();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to save attendance. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  _updateTime(int workerId, bool isInTime, TimeOfDay selectedTime) {
    String formatted = "${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}:00";
    if (isInTime) {
      setState(() {
        _inTime[workerId] = formatted;
      });
    } else {
      setState(() {
        _outTime[workerId] = formatted;
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final workers = userProvider.workers
        .where((user) => user.role == 'worker')
        .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance',
        onLeadingPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark Attendance',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E88E5), // Royal Blue
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
                  ],
                ),
                // Add a refresh button to get today's summary
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    // Get login status provider
                    final loginStatusProvider = Provider.of<LoginStatusProvider>(context, listen: false);
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    
                    // Get today's login status data
                    final todayLoginStatus = await loginStatusProvider.getTodayLoginStatus();
                    
                    // Get total workers from user provider
                    final totalWorkers = userProvider.workers
                        .where((user) => user.role == 'worker')
                        .length;
                    
                    // Use login status data for accurate statistics
                    final loggedInCount = todayLoginStatus.where((s) => s['is_logged_in'] == true).length;
                    final absentCount = totalWorkers - loggedInCount;
                    
                    final summary = {
                      'total': totalWorkers,
                      'present': loggedInCount,
                      'absent': absentCount > 0 ? absentCount : 0,
                    };
                    
                    Fluttertoast.showToast(
                      msg: 'Total: ${summary['total']}, Present: ${summary['present']}, Absent: ${summary['absent']}',
                      toastLength: Toast.LENGTH_LONG,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Date Selector
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5), // Royal Blue
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
                                activeThumbColor: const Color(0xFF4CAF50), // Green
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            borderRadius:
                                                BorderRadius.circular(5),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            borderRadius:
                                                BorderRadius.circular(5),
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
    );
  }
}