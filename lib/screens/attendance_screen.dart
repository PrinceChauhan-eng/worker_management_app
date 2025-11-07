import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../providers/user_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadWorkers();
    });
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  _saveAttendance() async {
    setState(() {
      _isLoading = true;
    });

    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    bool allSaved = true;

    for (var worker in userProvider.workers) {
      if (worker.role == 'worker') {
        // Check if we have attendance data for this worker
        bool isPresent = _attendanceStatus[worker.id!] ?? false;
        String inTime = _inTime[worker.id!] ?? '09:00';
        String outTime = _outTime[worker.id!] ?? '17:00';

        // Create attendance object
        final attendance = Attendance(
          workerId: worker.id!,
          date: _selectedDate,
          inTime: isPresent ? inTime : '',
          outTime: isPresent ? outTime : '',
          present: isPresent,
        );

        // Save attendance
        bool success = await attendanceProvider.addAttendance(attendance);
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
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