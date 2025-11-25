import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/attendance_log.dart';
import '../models/advance.dart';
import '../models/notification.dart' as notif;
import '../services/attendance_service.dart';
import '../services/attendance_log_service.dart';
import '../services/advance_service.dart';
import '../services/notifications_service.dart';
import '../utils/logger.dart';

class SalaryCalculationService {
  final AttendanceService _attendanceService = AttendanceService();
  final AttendanceLogService _attendanceLogService = AttendanceLogService();
  final AdvanceService _advanceService = AdvanceService();
  final NotificationsService _notificationsService = NotificationsService();
  
  /// Send notification to worker about salary generation
  Future<void> _sendSalaryNotification({
    required int workerId,
    required String month,
    required double netSalary,
  }) async {
    try {
      // Format month for display
      final formattedMonth = DateFormat('MMM yyyy').format(
        DateTime(int.parse(month.split('-')[0]), int.parse(month.split('-')[1]))
      );
      
      // Format salary with currency
      final formattedSalary = '₹${netSalary.toStringAsFixed(0)}';
      
      // Create notification message
      final title = 'Salary Generated';
      final message = 'Your salary for $formattedMonth has been generated: $formattedSalary';
      
      // Create notification object
      final notification = notif.NotificationModel(
        title: title,
        message: message,
        type: 'salary',
        userId: workerId,
        userRole: 'worker',
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      // Insert notification
      await _notificationsService.insert(notification.toMap());
      Logger.info('Salary notification sent to worker $workerId for month $month');
    } catch (e) {
      Logger.error('Error sending salary notification: $e', e);
    }
  }

  /// Calculate salary based on attendance hours with the specified rules:
  /// - ≥ 7 hours: Full day wage
  /// - 4–7 hours: Half day 50%
  /// - < 4 hours: 0 (Absent)
  /// - > 9 hours: Overtime bonus
  Future<SalaryCalculationResult> calculateMonthlySalary({
    required User worker,
    required String month, // Format: "yyyy-MM"
  }) async {
    try {
      Logger.info('Calculating salary for worker ${worker.id} for month $month');
      
      // Get all attendance records for the worker in the specified month
      // We need to query each day individually since AttendanceService doesn't have a byWorkerAndMonth method
      final year = int.parse(month.split('-')[0]);
      final monthNum = int.parse(month.split('-')[1]);
      final totalDays = DateTime(year, monthNum + 1, 0).day;
      
      List<Attendance> attendances = [];
      for (int day = 1; day <= totalDays; day++) {
        final dateStr = '$month-${day.toString().padLeft(2, '0')}';
        final attendanceData = await _attendanceService.byWorkerAndDate(worker.id!, dateStr);
        final dailyAttendances = attendanceData.map((data) => Attendance.fromMap(data)).toList();
        attendances.addAll(dailyAttendances);
      }
      
      Logger.info('Found ${attendances.length} attendance records');
      
      int presentDays = 0;
      int halfDays = 0;
      int absentDays = 0;
      double totalHoursWorked = 0.0;
      double overtimeHours = 0.0;
      
      // Process each attendance record to calculate hours
      for (var attendance in attendances) {
        if (!attendance.present) {
          absentDays++;
          continue;
        }
        
        // For each present day, calculate hours worked
        final hoursWorked = await _calculateHoursForDay(
          workerId: worker.id!, 
          date: attendance.date
        );
        
        totalHoursWorked += hoursWorked;
        
        // Apply salary rules based on hours worked
        if (hoursWorked >= 7.0) {
          presentDays++;
          // Check for overtime
          if (hoursWorked > 9.0) {
            overtimeHours += (hoursWorked - 9.0);
          }
        } else if (hoursWorked >= 4.0) {
          halfDays++;
        } else {
          absentDays++;
        }
      }
      
      // Get days in month for total days calculation
      // (already calculated above)
      
      // Calculate gross salary
      final fullDayWage = worker.wage;
      final halfDayWage = fullDayWage * 0.5;
      final overtimeWage = fullDayWage * 0.2; // 20% bonus per overtime hour
      
      final presentSalary = presentDays * fullDayWage;
      final halfDaySalary = halfDays * halfDayWage;
      final overtimeSalary = overtimeHours * overtimeWage;
      
      final grossSalary = presentSalary + halfDaySalary + overtimeSalary;
      
      // Get advances for the month
      final advancesData = await _advanceService.byWorkerAndMonth(
        worker.id!, 
        month
      );
      
      final advances = advancesData.map((data) => Advance.fromMap(data)).toList();
      final totalAdvance = advances.fold<double>(
        0.0, 
        (sum, adv) => sum + (adv.status == 'approved' ? adv.amount : 0.0)
      );
      
      // Calculate net salary
      final netSalary = grossSalary - totalAdvance;
      
      Logger.info('Salary calculation complete:');
      Logger.info('  Present days: $presentDays');
      Logger.info('  Half days: $halfDays');
      Logger.info('  Absent days: $absentDays');
      Logger.info('  Total hours: $totalHoursWorked');
      Logger.info('  Overtime hours: $overtimeHours');
      Logger.info('  Gross salary: $grossSalary');
      Logger.info('  Total advance: $totalAdvance');
      Logger.info('  Net salary: $netSalary');
      
      // Send notification to worker about salary generation
      try {
        await _sendSalaryNotification(
          workerId: worker.id!,
          month: month,
          netSalary: netSalary,
        );
      } catch (e) {
        Logger.error('Error sending salary notification: $e', e);
      }
      
      return SalaryCalculationResult(
        workerId: worker.id!,
        month: month,
        totalDays: totalDays,
        presentDays: presentDays,
        halfDays: halfDays,
        absentDays: absentDays,
        totalHoursWorked: totalHoursWorked,
        overtimeHours: overtimeHours,
        grossSalary: grossSalary,
        totalAdvance: totalAdvance,
        netSalary: netSalary,
        advances: advances,
      );
    } catch (e) {
      Logger.error('Error calculating monthly salary: $e', e);
      rethrow;
    }
  }
  
  /// Calculate hours worked for a specific day using attendance logs
  Future<double> _calculateHoursForDay({
    required int workerId,
    required String date,
  }) async {
    try {
      // Get attendance logs for the day
      final logsData = await _attendanceLogService.getLogsByWorkerAndDate(
        workerId, 
        date
      );
      
      final logs = logsData.map((data) => AttendanceLog.fromMap(data)).toList();
      
      if (logs.isEmpty) {
        return 0.0;
      }
      
      double totalHours = 0.0;
      
      // Group logs by login/logout pairs
      List<AttendanceLog> loginLogs = [];
      List<AttendanceLog> logoutLogs = [];
      
      for (var log in logs) {
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
            final diff = logoutDateTime.difference(loginDateTime);
            totalHours += diff.inMinutes / 60.0;
          }
        } catch (e) {
          Logger.error('Error calculating duration for log pair: $e', e);
        }
      }
      
      return totalHours;
    } catch (e) {
      Logger.error('Error calculating hours for day: $e', e);
      return 0.0;
    }
  }
}

class SalaryCalculationResult {
  final int workerId;
  final String month;
  final int totalDays;
  final int presentDays;
  final int halfDays;
  final int absentDays;
  final double totalHoursWorked;
  final double overtimeHours;
  final double grossSalary;
  final double totalAdvance;
  final double netSalary;
  final List<Advance> advances;

  SalaryCalculationResult({
    required this.workerId,
    required this.month,
    required this.totalDays,
    required this.presentDays,
    required this.halfDays,
    required this.absentDays,
    required this.totalHoursWorked,
    required this.overtimeHours,
    required this.grossSalary,
    required this.totalAdvance,
    required this.netSalary,
    required this.advances,
  });
}