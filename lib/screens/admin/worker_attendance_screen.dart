import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/user_provider.dart';
import '../../providers/login_status_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/user.dart';
import '../../models/login_status.dart';
import '../../models/attendance.dart';
import '../../models/notification.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/notifications_service.dart';
import '../../services/attendance_service.dart';
import '../../utils/logger.dart';

class WorkerAttendanceScreen extends StatefulWidget {
  final User? preselectedWorker;

  const WorkerAttendanceScreen({super.key, this.preselectedWorker});

  @override
  State<WorkerAttendanceScreen> createState() => _WorkerAttendanceScreenState();
}

class _WorkerAttendanceScreenState extends State<WorkerAttendanceScreen> {
  User? _selectedWorker;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Set the preselected worker if provided
    if (widget.preselectedWorker != null) {
      _selectedWorker = widget.preselectedWorker;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final workers = userProvider.workers
        .where((u) => u.role == 'worker')
        .toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Worker Attendance',
      ),
      body: Padding(
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
              'Mark workers as present or absent',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            // Worker Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
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
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (User? worker) {
                    setState(() {
                      _selectedWorker = worker;
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date Selection
            if (_selectedWorker != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          DateFormat(
                            'EEEE, MMM dd, yyyy',
                          ).format(_selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text('Change Date', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),

            // Action Buttons
            if (_selectedWorker != null)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAttendance('present'),
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: Text(
                        'Mark Present',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _markAttendance('absent'),
                      icon: const Icon(Icons.cancel, size: 20),
                      label: Text(
                        'Mark Absent',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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

  Future<void> _markAttendance(String status) async {
    if (_selectedWorker == null) return;

    try {
      print('Marking attendance for worker: ${_selectedWorker!.name} (ID: ${_selectedWorker!.id}) as $status');
      final loginStatusProvider = Provider.of<LoginStatusProvider>(
        context,
        listen: false,
      );
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      // Use normalized time method (Fix #7)
      String timeStr = Logger.nowTime();

      // Validate time fields - they should not be empty for present workers
      if (status == 'present') {
        // For present workers, we should have valid time values
        // In this implementation, we're using current time for login
        // For logout time, it can be empty initially and filled later
      }

      // Check if there's already a record for this date in login status
      LoginStatus? existingLoginStatus = await loginStatusProvider
          .getLoginStatusForDate(_selectedWorker!.id!, dateStr);

      // Check if there's already a record for this date in attendance
      await attendanceProvider.loadAttendances();
      List<Attendance> existingAttendanceRecords = attendanceProvider.attendances
          .where((att) => att.workerId == _selectedWorker!.id! && att.date == dateStr)
          .toList();
      
      Attendance? existingAttendance = existingAttendanceRecords.isNotEmpty 
          ? existingAttendanceRecords.first 
          : null;

      LoginStatus loginStatus;
      Attendance attendance;

      if (status == 'present') {
        print('Creating present record for worker');
        // Update existing login status record or create new one
        loginStatus = LoginStatus(
          id: existingLoginStatus?.id, // Keep ID for updates
          workerId: _selectedWorker!.id!,
          date: dateStr,
          loginTime: existingLoginStatus?.loginTime ?? timeStr,
          logoutTime: existingLoginStatus?.logoutTime,
          isLoggedIn: true,
        );
        
        // Update existing attendance record or create new one
        // For present workers, ensure we have valid time values
        String inTimeValue = existingAttendance?.inTime.isNotEmpty == true 
            ? existingAttendance!.inTime 
            : timeStr;
        String outTimeValue = existingAttendance?.outTime.isNotEmpty == true 
            ? existingAttendance!.outTime 
            : ''; // Can be empty initially for present workers
        
        attendance = Attendance(
          id: existingAttendance?.id, // Keep ID for updates
          workerId: _selectedWorker!.id!,
          date: dateStr,
          inTime: inTimeValue,
          outTime: outTimeValue,
          present: true, // Fix present toggle (Fix #6)
        );
      } else {
        print('Creating absent record for worker');
        // For absent, we create a record with empty time values
        // Update existing login status record to absent
        loginStatus = LoginStatus(
          id: existingLoginStatus?.id, // Keep ID for updates
          workerId: _selectedWorker!.id!,
          date: dateStr,
          loginTime: existingLoginStatus?.loginTime ?? '',
          logoutTime: existingLoginStatus?.logoutTime ?? '',
          isLoggedIn: false,
        );
        
        // Update existing attendance record or create new one
        attendance = Attendance(
          id: existingAttendance?.id, // Keep ID for updates
          workerId: _selectedWorker!.id!,
          date: dateStr,
          inTime: '',
          outTime: '',
          present: false, // Fix present toggle (Fix #6)
        );
      }

      print('LoginStatus to save: isLoggedIn=${loginStatus.isLoggedIn}');
      print('Attendance to save: present=${attendance.present}');
      
      // Log the final payload for debugging
      print('Final Attendance Payload: ${attendance.toMap()}');
      print('Final LoginStatus Payload: ${loginStatus.toMap()}');

      // Save to database using the correct method for login status
      await loginStatusProvider.updateLoginStatus(loginStatus);
      
      // Save to database using the correct method for attendance
      bool attendanceSuccess;
      if (attendance.id == null) {
        attendanceSuccess = await attendanceProvider.addAttendance(attendance);
      } else {
        attendanceSuccess = await attendanceProvider.updateAttendance(attendance);
      }
      print('Attendance save success: $attendanceSuccess');

      // Sync login status with attendance
      try {
        final attendanceService = AttendanceService();
        await attendanceService.syncLoginStatusWithAttendance(
          workerId: _selectedWorker!.id!,
          date: dateStr,
          inTime: attendance.inTime.isNotEmpty ? attendance.inTime : null,
          outTime: attendance.outTime.isNotEmpty ? attendance.outTime : null,
          present: attendance.present ? 1 : 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }

      // Send notification to worker about attendance update
      await _sendAttendanceNotification(_selectedWorker!, status, dateStr);

      // Show success message
      Fluttertoast.showToast(
        msg:
            'Marked as ${status.toUpperCase()} for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
        backgroundColor: status == 'present' ? Colors.green : Colors.red,
      );

      // Refresh the UI
      setState(() {});
      
      // Refresh login status to ensure dashboard is updated
      loginStatusProvider.refreshToday();
    } catch (e) {
      Logger.error('Error marking attendance: $e', e);
      Fluttertoast.showToast(
        msg: 'Failed to save attendance. Please try again later.',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _sendAttendanceNotification(
    User worker,
    String status,
    String date,
  ) async {
    try {
      final notificationService = NotificationsService();

      // Create notification for the worker
      final notification = NotificationModel(
        title: 'Attendance Updated',
        message:
            'Your attendance for $date has been marked as ${status.toUpperCase()} by admin',
        type: 'attendance',
        userId: worker.id!,
        userRole: worker.role,
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
        relatedId: date, // Store the date as related ID
      );

      await notificationService.insert(notification.toMap());

      Logger.info('Attendance notification sent to worker ID: ${worker.id}');
    } catch (e) {
      Logger.error('Error sending attendance notification: $e', e);
    }
  }
}