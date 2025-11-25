import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/attendance_log.dart';
import '../services/attendance_service.dart';
import '../services/attendance_log_service.dart';
import '../services/users_service.dart';
import '../utils/logger.dart';

class CsvExporter {
  final AttendanceService _attendanceService = AttendanceService();
  final AttendanceLogService _attendanceLogService = AttendanceLogService();
  final UsersService _usersService = UsersService();

  /// Export attendance data to CSV for a given month
  Future<String> exportAttendanceToCSV(String month) async {
    try {
      Logger.info('Exporting attendance data to CSV for month: $month');
      
      // Get all workers
      final workersData = await _usersService.getWorkersForCurrentAdmin();
      final workers = workersData.map((data) => User.fromMap(data)).toList();
      
      // Prepare CSV content
      final buffer = StringBuffer();
      
      // Add CSV header
      buffer.writeln('Worker ID,Name,Phone,Date,Present,In Time,Out Time,Hours Worked,Location');
      
      // Get days in month for iteration
      final year = int.parse(month.split('-')[0]);
      final monthNum = int.parse(month.split('-')[1]);
      final totalDays = DateTime(year, monthNum + 1, 0).day;
      
      // Process each worker
      for (var worker in workers) {
        // Process each day of the month
        for (int day = 1; day <= totalDays; day++) {
          final dateStr = '$month-${day.toString().padLeft(2, '0')}';
          
          // Get attendance data for this worker and date
          final attendanceData = await _attendanceService.byWorkerAndDate(worker.id!, dateStr);
          
          if (attendanceData.isNotEmpty) {
            final attendance = Attendance.fromMap(attendanceData.first);
            
            // Calculate hours worked using attendance logs
            final hoursWorked = await _calculateHoursForDay(worker.id!, dateStr);
            
            // Get location data from attendance logs
            final location = await _getLocationForDay(worker.id!, dateStr);
            
            // Write row to CSV
            buffer.write('${worker.id},');
            buffer.write('"${worker.name}",');
            buffer.write('"${worker.phone}",');
            buffer.write('$dateStr,');
            buffer.write('${attendance.present ? "Yes" : "No"},');
            buffer.write('${attendance.inTime ?? ""},');
            buffer.write('${attendance.outTime ?? ""},');
            buffer.write('$hoursWorked,');
            buffer.write('"$location"');
            buffer.writeln();
          } else {
            // No attendance record for this day
            buffer.write('${worker.id},');
            buffer.write('"${worker.name}",');
            buffer.write('"${worker.phone}",');
            buffer.write('$dateStr,');
            buffer.write('No,,,,""');
            buffer.writeln();
          }
        }
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/attendance_$month.csv';
      final file = File(filePath);
      await file.writeAsString(buffer.toString());
      
      Logger.info('Attendance CSV exported successfully to: $filePath');
      return filePath;
    } catch (e) {
      Logger.error('Error exporting attendance to CSV: $e', e);
      rethrow;
    }
  }
  
  /// Calculate hours worked for a specific day using attendance logs
  Future<double> _calculateHoursForDay(int workerId, String date) async {
    try {
      // Get attendance logs for the day
      final logsData = await _attendanceLogService.getLogsByWorkerAndDate(workerId, date);
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
          final loginTime = DateTime.parse('$date ${loginLogs[i].punchTime}');
          final logoutTime = DateTime.parse('$date ${logoutLogs[i].punchTime}');
          
          if (logoutTime.isAfter(loginTime)) {
            final diff = logoutTime.difference(loginTime);
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
  
  /// Get location information for a specific day
  Future<String> _getLocationForDay(int workerId, String date) async {
    try {
      // Get attendance logs for the day
      final logsData = await _attendanceLogService.getLogsByWorkerAndDate(workerId, date);
      final logs = logsData.map((data) => AttendanceLog.fromMap(data)).toList();
      
      if (logs.isEmpty) {
        return '';
      }
      
      // Collect location information from logs
      final locations = <String>[];
      for (var log in logs) {
        if (log.locationAddress != null && log.locationAddress!.isNotEmpty) {
          locations.add('${log.punchType}: ${log.locationAddress}');
        } else if (log.locationLatitude != null && log.locationLongitude != null) {
          locations.add('${log.punchType}: (${log.locationLatitude}, ${log.locationLongitude})');
        }
      }
      
      return locations.join('; ');
    } catch (e) {
      Logger.error('Error getting location for day: $e', e);
      return '';
    }
  }
}