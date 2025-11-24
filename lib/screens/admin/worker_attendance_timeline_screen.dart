import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user.dart';
import '../../models/attendance_log.dart';
import '../../providers/attendance_log_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/logger.dart';

class WorkerAttendanceTimelineScreen extends StatefulWidget {
  final int workerId;
  final String date;

  const WorkerAttendanceTimelineScreen({
    super.key,
    required this.workerId,
    required this.date,
  });

  @override
  State<WorkerAttendanceTimelineScreen> createState() =>
      _WorkerAttendanceTimelineScreenState();
}

class _WorkerAttendanceTimelineScreenState
    extends State<WorkerAttendanceTimelineScreen> {
  bool _isLoading = true;
  List<AttendanceLog> _timeline = [];
  User? _worker;
  String _totalDuration = '0h 0m';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final attendanceLogProvider =
          Provider.of<AttendanceLogProvider>(context, listen: false);

      // Load worker details
      await userProvider.loadWorkers();
      _worker = userProvider.workers
          .firstWhere((worker) => worker.id == widget.workerId);

      // Load timeline
      _timeline = await attendanceLogProvider
          .getTimeline(widget.workerId, widget.date);

      // Calculate total duration
      _calculateTotalDuration();

      setState(() => _isLoading = false);
    } catch (e) {
      Logger.error('Error loading timeline data: $e', e);
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotalDuration() {
    Duration totalDuration = Duration.zero;
    
    // Group logs by login/logout pairs
    List<AttendanceLog> loginLogs = [];
    List<AttendanceLog> logoutLogs = [];
    
    for (var log in _timeline) {
      if (log.punchType == 'login') {
        loginLogs.add(log);
      } else if (log.punchType == 'logout') {
        logoutLogs.add(log);
      }
    }
    
    // Calculate duration for each pair
    int pairs = loginLogs.length < logoutLogs.length 
        ? loginLogs.length 
        : logoutLogs.length;
        
    for (int i = 0; i < pairs; i++) {
      try {
        final loginTime = DateFormat('HH:mm:ss').parse(loginLogs[i].punchTime);
        final logoutTime = DateFormat('HH:mm:ss').parse(logoutLogs[i].punchTime);
        
        final loginDateTime = DateTime.now().copyWith(
          hour: loginTime.hour,
          minute: loginTime.minute,
          second: loginTime.second,
        );
        
        final logoutDateTime = DateTime.now().copyWith(
          hour: logoutTime.hour,
          minute: logoutTime.minute,
          second: logoutTime.second,
        );
        
        if (logoutDateTime.isAfter(loginDateTime)) {
          totalDuration += logoutDateTime.difference(loginDateTime);
        }
      } catch (e) {
        Logger.error('Error calculating duration: $e', e);
      }
    }
    
    _totalDuration = '${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Timeline',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTimelineContent(),
    );
  }

  Widget _buildTimelineContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker info
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _worker?.name ?? 'Unknown Worker',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${widget.date}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Duration: $_totalDuration',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Timeline
          Text(
            'Timeline',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          
          _timeline.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No attendance records found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _timeline.length,
                    itemBuilder: (context, index) {
                      final log = _timeline[index];
                      final isLogin = log.punchType == 'login';
                      
                      // Calculate duration if this is a logout and there's a previous login
                      String duration = '';
                      if (!isLogin && index > 0) {
                        final prevLog = _timeline[index - 1];
                        if (prevLog.punchType == 'login') {
                          try {
                            final loginTime = DateFormat('HH:mm:ss').parse(prevLog.punchTime);
                            final logoutTime = DateFormat('HH:mm:ss').parse(log.punchTime);
                            
                            final loginDateTime = DateTime.now().copyWith(
                              hour: loginTime.hour,
                              minute: loginTime.minute,
                              second: loginTime.second,
                            );
                            
                            final logoutDateTime = DateTime.now().copyWith(
                              hour: logoutTime.hour,
                              minute: logoutTime.minute,
                              second: logoutTime.second,
                            );
                            
                            if (logoutDateTime.isAfter(loginDateTime)) {
                              final diff = logoutDateTime.difference(loginDateTime);
                              duration = '(${diff.inHours}h ${diff.inMinutes % 60}m)';
                            }
                          } catch (e) {
                            Logger.error('Error calculating duration: $e', e);
                          }
                        }
                      }
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isLogin ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLogin ? Icons.login : Icons.logout,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            isLogin ? 'Login' : 'Logout',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isLogin ? Colors.green : Colors.red,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.punchTime,
                                style: GoogleFonts.poppins(),
                              ),
                              if (duration.isNotEmpty)
                                Text(
                                  duration,
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (log.locationAddress != null)
                                Text(
                                  log.locationAddress!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Text(
                            DateFormat('hh:mm a').format(
                              DateFormat('HH:mm:ss').parse(log.punchTime),
                            ),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}