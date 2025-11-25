import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

import '../../providers/user_provider.dart';
import '../../providers/login_status_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/attendance.dart';
import '../../utils/logger.dart';
import '../../services/session_manager.dart';
import '../../services/route_guard.dart';
import '../../services/location_service.dart';
import '../../widgets/enhanced_attendance_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/live_clock.dart'; // Import the LiveClock widget
import '../login_screen.dart';

// Import screens for quick actions
import '../my_attendance_screen.dart';
import '../my_salary_screen.dart';
import '../my_advance_screen.dart';
import '../my_salary_slips_screen.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key, this.openAttendanceDetails = false});

  final bool openAttendanceDetails;

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isProcessing = false; // For button tap lock
  Map<String, dynamic>? todayLoginStatus;
  Map<String, dynamic>? todayAttendance;
  List<Map<String, dynamic>> monthAttendances = [];
  DateTime? _lastUpdated;
  RealtimeChannel? _attendanceChannel;
  RealtimeChannel? _loginStatusChannel;

  // Add new state variables for Phase E
  bool _isLoggedIn = false;
  String _inTime = "";
  String _outTime = "";
  
  // Add timer variables for Phase E3
  Duration _workDuration = Duration.zero;
  Timer? _workTimer;

  final String _today =
      DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
  final String _month =
      DateFormat('yyyy-MM').format(DateTime.now().toLocal());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Subscribe to real-time updates
      _subscribeToRealtimeUpdates();
      
      // If deep link requested, scroll to attendance section
      if (widget.openAttendanceDetails) {
        Future.delayed(const Duration(milliseconds: 400), () {
          // Scroll to attendance section would be implemented here
        });
      }
    });
  }

  void _subscribeToRealtimeUpdates() {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    // Subscribe to attendance updates
    _attendanceChannel = Supabase.instance.client
        .channel('attendance_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          callback: (payload) async {
            // When attendance for this worker updates → reload dashboard
            if (payload.newRecord['worker_id'] == user.id) {
              _loadData();
            }
          },
        )
        .subscribe();

    // Subscribe to login status updates
    _loginStatusChannel = Supabase.instance.client
        .channel('login_status_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'login_status',
          callback: (payload) async {
            // When login status for this worker updates → reload dashboard
            if (payload.newRecord['worker_id'] == user.id) {
              _loadData();
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Unsubscribe from real-time updates
    _attendanceChannel?.unsubscribe();
    _loginStatusChannel?.unsubscribe();
    // Stop work timer when screen is closed (Phase E3)
    _stopWorkTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When user returns to app, refresh dashboard
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final loginProv = Provider.of<LoginStatusProvider>(context, listen: false);
    final attProv = Provider.of<AttendanceProvider>(context, listen: false);
    final notificationProv = Provider.of<NotificationProvider>(context, listen: false);

    if (userProv.currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    final workerId = userProv.currentUser!.id!;

    // 1️⃣ Load today's login status
    final todayLogin =
        await loginProv.getLoginStatusForDate(workerId, _today);

    // 2️⃣ Load attendance list for this worker
    await attProv.loadAttendancesByWorkerId(workerId);
    final all = attProv.attendances;

    // 3️⃣ Extract today's attendance
    final todayAtt = all.firstWhere(
      (a) => a.workerId == workerId && a.date == _today,
      orElse: () => Attendance(id: null, workerId: workerId, date: _today, inTime: '', outTime: '', present: false),
    );

    // 4️⃣ Monthly attendance
    final monthAtt =
        all.where((a) => a.workerId == workerId && a.date.startsWith(_month)).toList();

    // 5️⃣ Set attendance state for Phase E
    _isLoggedIn = todayAtt.present && todayAtt.outTime.isEmpty;
    _inTime = todayAtt.inTime;
    _outTime = todayAtt.outTime;
    
    // 6️⃣ Start or stop work timer based on login state (Phase E3)
    if (_isLoggedIn && _inTime.isNotEmpty) {
      _startWorkTimer();
    } else {
      _stopWorkTimer();
    }

    if (!mounted) return;
    setState(() {
      todayLoginStatus = todayLogin?.toMap();
      todayAttendance = todayAtt.toMap();
      monthAttendances = monthAtt.map((a) => a.toMap()).toList();
      _isLoading = false;
      _lastUpdated = DateTime.now().toLocal();
    });
    
    // Refresh notification count
    if (mounted) {
      notificationProv.loadIfNeeded(workerId, 'worker');
    }
  }

  // Timer methods for Phase E3
  void _startWorkTimer() {
    _stopWorkTimer();
    
    // Check if user is logged in and has valid login time
    if (_isLoggedIn && _inTime.isNotEmpty) {
      try {
        final now = DateTime.now().toLocal();
        // Parse the login time correctly
        final loginDateTime = DateFormat("HH:mm:ss").parse(_inTime);
        // Create a DateTime object for today with the login time
        final loginDateTimeToday = DateTime(
          now.year,
          now.month,
          now.day,
          loginDateTime.hour,
          loginDateTime.minute,
          loginDateTime.second,
        ).toLocal();

        _workDuration = now.difference(loginDateTimeToday);
        _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _workDuration = DateTime.now().toLocal().difference(loginDateTimeToday);
          });
        });
      } catch (e) {
        Logger.error('Error calculating work duration: $e', e);
        // Stop timer if there's an error
        _stopWorkTimer();
      }
    } else {
      _stopWorkTimer();
    }
  }

  void _stopWorkTimer() {
    _workTimer?.cancel();
  }

  Future<void> _handleLogin(int workerId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final loginStatusProvider =
          Provider.of<LoginStatusProvider>(context, listen: false);
      final locationService = LocationService();

      final String todayDate =
          DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      final String nowTime = Logger.nowTime(); // "HH:mm:ss"

      // Capture location data
      String? locationAddress;
      double? locationLatitude;
      double? locationLongitude;
      
      try {
        final locationData = await locationService.getCurrentLocationWithAddress();
        if (locationData != null) {
          locationAddress = locationData.address;
          locationLatitude = locationData.latitude;
          locationLongitude = locationData.longitude;
        }
      } catch (e) {
        Logger.error('Error getting location data: $e', e);
        // Continue without location data if there's an error
      }

      // find or create today's attendance
      Attendance? att = attendanceProvider.attendances.firstWhere(
        (a) => a.workerId == workerId && a.date == todayDate,
        orElse: () => Attendance(
          workerId: workerId,
          date: todayDate,
          inTime: '',
          outTime: '',
          present: false,
        ),
      );

      // Guard: if there's an open session (in but no out), prevent double login
      final bool hasInTime = att.inTime.isNotEmpty;
      final bool hasOutTime = att.outTime.isNotEmpty;

      if (hasInTime && !hasOutTime) {
        Fluttertoast.showToast(
          msg: "You are already logged in.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      // If already completed one cycle today (in+out set), allow re-login:
      if (hasInTime && hasOutTime) {
        att = Attendance(
          id: att.id,
          workerId: att.workerId,
          date: att.date,
          inTime: nowTime,
          outTime: '',
          present: true,
        );
      } else if (!hasInTime) {
        // first login today
        att = Attendance(
          id: att.id,
          workerId: att.workerId,
          date: att.date,
          inTime: nowTime,
          outTime: att.outTime,
          present: true,
        );
      }

      bool success;
      if (att.id == null) {
        success = await attendanceProvider.addAttendance(att);
      } else {
        success = await attendanceProvider.updateAttendance(att);
      }

      // Also mark login in the attendance service with location data
      if (success) {
        try {
          await attendanceProvider.markLogin(
            workerId: workerId,
            inTime: nowTime,
            address: locationAddress,
            latitude: locationLatitude,
            longitude: locationLongitude,
          );
        } catch (e) {
          Logger.error('Error marking login with location: $e', e);
          // Continue even if location marking fails
        }
      }

      if (success) {
        await loginStatusProvider.refreshToday(); // keep worker dashboard in sync

        Fluttertoast.showToast(
          msg: "Login marked at $nowTime${locationAddress != null ? ' at $locationAddress' : ''}",
          backgroundColor: Colors.green,
        );
        setState(() {}); // refresh card
      } else {
        Fluttertoast.showToast(
          msg: "Failed to save login. Try again.",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  Future<void> _handleLogout(int workerId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final loginStatusProvider =
          Provider.of<LoginStatusProvider>(context, listen: false);

      final String todayDate =
          DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      final String nowTime = Logger.nowTime(); // "HH:mm:ss"

      Attendance? att = attendanceProvider.attendances.firstWhere(
        (a) => a.workerId == workerId && a.date == todayDate,
        orElse: () => Attendance(
          workerId: workerId,
          date: todayDate,
          inTime: '',
          outTime: '',
          present: false,
        ),
      );

      if (att.inTime.isEmpty) {
        Fluttertoast.showToast(
          msg: "You must login before logging out.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      if (att.outTime.isNotEmpty) {
        Fluttertoast.showToast(
          msg: "You have already logged out.",
          backgroundColor: Colors.orange,
        );
        return;
      }

      // Optional: guard against logout too soon (<1 min after login)
      try {
        final inDt = DateFormat('HH:mm:ss').parse(att.inTime);
        final outDt = DateFormat('HH:mm:ss').parse(nowTime);

        if (outDt.isBefore(inDt)) {
          Fluttertoast.showToast(
            msg: "Logout time can't be before login time.",
            backgroundColor: Colors.red,
          );
          return;
        }

        final diff = outDt.difference(inDt);
        if (diff.inMinutes < 1) {
          Fluttertoast.showToast(
            msg: "You just logged in. Wait at least 1 minute.",
            backgroundColor: Colors.orange,
          );
          return;
        }
      } catch (_) {
        // ignore parsing errors; just proceed to save
      }

      att = Attendance(
        id: att.id,
        workerId: att.workerId,
        date: att.date,
        inTime: att.inTime,
        outTime: nowTime,
        present: true,
      );

      final success = await attendanceProvider.updateAttendance(att);

      // Also mark logout in the attendance service with location data
      if (success) {
        try {
          // Capture location data for logout
          String? logoutAddress;
          double? logoutLatitude;
          double? logoutLongitude;
          
          try {
            final locationService = LocationService();
            final locationData = await locationService.getCurrentLocationWithAddress();
            if (locationData != null) {
              logoutAddress = locationData.address;
              logoutLatitude = locationData.latitude;
              logoutLongitude = locationData.longitude;
            }
          } catch (e) {
            Logger.error('Error getting logout location data: $e', e);
            // Continue without location data if there's an error
          }
          
          await attendanceProvider.markLogout(
            workerId: workerId,
            outTime: nowTime,
            address: logoutAddress,
            latitude: logoutLatitude,
            longitude: logoutLongitude,
          );
        } catch (e) {
          Logger.error('Error marking logout with location: $e', e);
          // Continue even if location marking fails
        }
      }

      if (success) {
        await loginStatusProvider.refreshToday();

        Fluttertoast.showToast(
          msg: "Logout marked at $nowTime",
          backgroundColor: Colors.orange,
        );
        setState(() {}); // refresh UI
      } else {
        Fluttertoast.showToast(
          msg: "Failed to save logout. Try again.",
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  String _getBadgeText(String status) {
    if (status == "Present") return "Present";
    if (status == "Logged Out") return "Logged Out";
    return "Absent";
  }

  Color _getBadgeColor(String status) {
    if (status == "Present") return Colors.green;
    if (status == "Logged Out") return Colors.orange;
    return Colors.red;
  }

  Future<void> _handleAppLogout() async {
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
        ],
      ),
    );

    if (confirm == true) {
      final sessionManager = SessionManager();
      await sessionManager.logout(false); // Logout current tab only

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final notificationProv = Provider.of<NotificationProvider>(context);
    
    // Enhanced route guard
    if (user?.role != "worker") {
      // Redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RouteGuard.redirectToLogin(context);
      });
      return const SizedBox(); // block access
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${user?.name ?? 'Worker'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            const LiveClock(), // Add the live clock
            if (_lastUpdated != null) ...[
              const SizedBox(height: 4),
              Text(
                "Last updated: ${DateFormat('hh:mm a').format(_lastUpdated!)}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // Filled icon
            onPressed: _handleAppLogout,
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
            child: Stack(
              children: [
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.notifications, size: 26), // Filled icon
                ),
                if (notificationProv.unreadCount > 0)
                  Positioned(
                    right: 10,
                    top: 12,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        notificationProv.unreadCount.toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 16),
                  _buildSkeletonCard(),
                  const SizedBox(height: 16),
                  _buildSkeletonCard(),
                  const SizedBox(height: 16),
                  _buildSkeletonListItems(),
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: _buildTodayStatusCard(),
                    ),
                    const SizedBox(height: 20),
                    // Add work duration display (Phase E3)
                    if (_isLoggedIn)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(.12),
                            borderRadius: BorderRadius.circular(16), // Updated to consistent radius
                          ),
                          child: Text(
                            "⏳ Working since "
                            "${_workDuration.inHours.toString().padLeft(2,'0')}h : "
                            "${(_workDuration.inMinutes % 60).toString().padLeft(2,'0')}m : "
                            "${(_workDuration.inSeconds % 60).toString().padLeft(2,'0')}s",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildMonthlySummary(),
                    const SizedBox(height: 20),
                    _buildRecentAttendance(), // Updated with colored attendance tags
                    const SizedBox(height: 20),
                    Text("Quick Actions",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildQuickActions(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    final user = Provider.of<UserProvider>(context).currentUser;
    final attProv = Provider.of<AttendanceProvider>(context);
    final loginStatusProv = Provider.of<LoginStatusProvider>(context);
    String status = "Not Marked";
    Color color = Colors.grey;

    // Extract today's attendance record
    Attendance? todayAttendanceRecord = attProv.attendances
        .firstWhere(
          (att) => att.workerId == user!.id && att.date == _today,
          orElse: () => Attendance(
            id: null,
            workerId: user!.id!,
            date: _today,
            inTime: '',
            outTime: '',
            present: false,
          ),
        );

    // Show In Time & Out Time
    String inTime = todayAttendanceRecord.inTime.isNotEmpty
        ? todayAttendanceRecord.inTime
        : "--";
        
    String outTime = todayAttendanceRecord.outTime.isNotEmpty
        ? todayAttendanceRecord.outTime
        : "--";

    // Determine status based on attendance and login status
    if (todayAttendanceRecord.present == true) {
      if (todayAttendanceRecord.outTime.isEmpty) {
        status = "Present";
        color = Colors.green;
      } else {
        status = "Logged Out";
        color = Colors.orange;
      }
    } else {
      status = "Absent";
      color = Colors.red;
    }

    // Button logic based on attendance state
    bool hasInTime = todayAttendanceRecord.inTime.isNotEmpty;
    bool hasOutTime = todayAttendanceRecord.outTime.isNotEmpty;

    String buttonText;
    if (!hasInTime) {
      buttonText = "Login";
    } else if (hasInTime && !hasOutTime) {
      buttonText = "Logout";
    } else {
      buttonText = "Login"; // logged out but same day → allow re-login
    }

    return EnhancedAttendanceCard(
      key: ValueKey("${todayLoginStatus?["is_logged_in"] ?? "null"}-${todayAttendanceRecord.present ?? "null"}"),
      title: "Today's Attendance",
      status: status,
      inTime: inTime,
      outTime: outTime,
      onButtonPressed: _isProcessing ? null : (buttonText == "Login" ? () => _handleLogin(user!.id!) : () => _handleLogout(user!.id!)),
      buttonText: buttonText,
      isLoading: _isProcessing,
      statusColor: color,
      badgeText: _getBadgeText(status),
      badgeColor: _getBadgeColor(status),
    );
  }

  Widget _timeBox(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 3),
          Text(value,
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary() {
    int present = monthAttendances.where((a) => a["present"] == true).length;
    int total = monthAttendances.length;
    int absent = total - present;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Updated to consistent radius
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem("Present", present, Colors.green),
            _summaryItem("Absent", absent, Colors.red),
            _summaryItem("Total Days", total, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text("$value",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildRecentAttendance() {
    final recent = monthAttendances.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Attendance",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...recent.map((att) {
          bool present = att["present"] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(18), // Increased padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16), // Updated to consistent radius
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08), // Updated shadow
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  present ? Icons.check_circle : Icons.cancel, // Filled icon
                  color: present ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        att["date"],
                        style: GoogleFonts.poppins(
                          fontSize: 16, // Increased font size
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Add colored attendance tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: present ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), // Green or red background
                          borderRadius: BorderRadius.circular(8), // Updated to consistent radius
                        ),
                        child: Text(
                          present ? "Present" : "Absent",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: present ? const Color(0xFF4CAF50) : const Color(0xFFF44336), // Green or red text
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final items = [
      ("My Attendance", Icons.calendar_month, const MyAttendanceScreen()), // Filled icon
      ("My Salary", Icons.payments, const MySalaryScreen()), // Filled icon
      ("Advances", Icons.account_balance_wallet, const MyAdvanceScreen()), // Filled icon
      ("Slips", Icons.receipt_long, const MySalarySlipsScreen()), // Filled icon
      ("Notifications", Icons.notifications, const NotificationsScreen()), // Filled icon
      ("Profile", Icons.person, const ProfileScreen()), // Filled icon
    ];

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: .95,
      children: items.map((item) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item.$3),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1E88E5),
                radius: 28,
                child: Icon(item.$2, color: Colors.white), // Filled icon
              ),
              const SizedBox(height: 6),
              Text(item.$1,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeletonCard() {
    return const ShimmerCard(height: 180);
  }

  Widget _buildSkeletonListItems() {
    return const ShimmerList(itemCount: 3, itemHeight: 70);
  }
}