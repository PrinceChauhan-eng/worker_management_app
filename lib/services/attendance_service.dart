import '../utils/map_case.dart';
import 'supabase_client.dart';
import '../utils/logger.dart';
import 'schema_refresher.dart';
import 'notifications_service.dart';
import '../models/notification.dart' as notif;
import '../models/attendance_log.dart';
import '../services/users_service.dart';
import '../services/attendance_log_service.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static const String _tableName = 'attendance';
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  final NotificationsService _notificationsService = NotificationsService();
  final UsersService _usersService = UsersService();
  final AttendanceLogService _attendanceLogService = AttendanceLogService();
  
  /// Send notification to worker about attendance update
  Future<void> _sendAttendanceNotification({
    required int workerId,
    required String date,
    required bool present,
    String? inTime,
    String? outTime,
  }) async {
    try {
      // Get worker details
      final workerData = await _usersService.getUser(workerId);
      if (workerData == null) return;
      
      // Format date for display
      final formattedDate = DateFormat('dd MMM').format(DateTime.parse(date));
      
      // Create notification message
      String title = 'Attendance Updated';
      String message;
      
      if (present) {
        if (inTime != null && outTime != null) {
          message = 'Your attendance on $formattedDate updated: PRESENT $inTime – $outTime';
        } else if (inTime != null) {
          message = 'Your attendance on $formattedDate updated: PRESENT Login at $inTime';
        } else if (outTime != null) {
          message = 'Your attendance on $formattedDate updated: PRESENT Logout at $outTime';
        } else {
          message = 'Your attendance on $formattedDate updated: PRESENT';
        }
      } else {
        message = 'Your attendance on $formattedDate updated: ABSENT';
      }
      
      // Create notification object
      final notification = notif.NotificationModel(
        title: title,
        message: message,
        type: 'attendance',
        userId: workerId,
        userRole: 'worker',
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      // Insert notification
      await _notificationsService.insert(notification.toMap());
      Logger.info('Attendance notification sent to worker $workerId for date $date');
    } catch (e) {
      Logger.error('Error sending attendance notification: $e', e);
    }
  }

  /// Mark attendance when worker logs in
  Future<void> markLogin({
    required int workerId,
    required String inTime,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final payload = {
        'worker_id': workerId,
        'date': today,
        'in_time': inTime,
        'present': true,
      };

      // Add location data if provided
      if (address != null) payload['login_address'] = address;
      if (latitude != null) payload['login_latitude'] = latitude;
      if (longitude != null) payload['login_longitude'] = longitude;

      await supa.from('attendance').update(payload).eq('worker_id', workerId).eq('date', today);
      Logger.info("✅ Login marked for worker $workerId at $inTime");
      
      // Create attendance log for login
      try {
        final log = AttendanceLog(
          workerId: workerId,
          date: today,
          punchTime: inTime,
          punchType: 'login',
          locationLatitude: latitude,
          locationLongitude: longitude,
          locationAddress: address,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _attendanceLogService.addLog(log);
        Logger.info("✅ Login log created for worker $workerId at $inTime");
      } catch (e) {
        Logger.error('Error creating login log: $e', e);
      }
      
      // Send notification to worker
      try {
        await _sendAttendanceNotification(
          workerId: workerId,
          date: today,
          present: true,
          inTime: inTime,
        );
      } catch (e) {
        Logger.error('Error sending login notification: $e', e);
      }
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: workerId,
          date: today,
          inTime: inTime,
          outTime: null,
          present: 1,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
    } catch (e) {
      Logger.info("❌ Failed to mark login: $e");
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final payload = {
        'worker_id': workerId,
        'date': today,
        'in_time': inTime,
        'present': true,
      };

      // Add location data if provided
      if (address != null) payload['login_address'] = address;
      if (latitude != null) payload['login_latitude'] = latitude;
      if (longitude != null) payload['login_longitude'] = longitude;

      await supa.from('attendance').update(payload).eq('worker_id', workerId).eq('date', today);
      Logger.info("✅ Login marked for worker $workerId at $inTime (retry)");
      
      // Create attendance log for login (retry)
      try {
        final log = AttendanceLog(
          workerId: workerId,
          date: today,
          punchTime: inTime,
          punchType: 'login',
          locationLatitude: latitude,
          locationLongitude: longitude,
          locationAddress: address,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _attendanceLogService.addLog(log);
        Logger.info("✅ Login log created for worker $workerId at $inTime (retry)");
      } catch (e) {
        Logger.error('Error creating login log (retry): $e', e);
      }
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: workerId,
          date: today,
          inTime: inTime,
          outTime: null,
          present: 1,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
    }
  }

  /// Mark attendance when worker logs out
  Future<void> markLogout({
    required int workerId,
    required String outTime,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final payload = {
        'worker_id': workerId,
        'date': today,
        'out_time': outTime,
      };

      // Add location data if provided
      if (address != null) payload['logout_address'] = address;
      if (latitude != null) payload['logout_latitude'] = latitude;
      if (longitude != null) payload['logout_longitude'] = longitude;

      await supa.from('attendance').update(payload).eq('worker_id', workerId).eq('date', today);
      Logger.info("✅ Logout marked for worker $workerId at $outTime");
      
      // Create attendance log for logout
      try {
        final log = AttendanceLog(
          workerId: workerId,
          date: today,
          punchTime: outTime,
          punchType: 'logout',
          locationLatitude: latitude,
          locationLongitude: longitude,
          locationAddress: address,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _attendanceLogService.addLog(log);
        Logger.info("✅ Logout log created for worker $workerId at $outTime");
      } catch (e) {
        Logger.error('Error creating logout log: $e', e);
      }
      
      // Send notification to worker
      try {
        await _sendAttendanceNotification(
          workerId: workerId,
          date: today,
          present: true,
          outTime: outTime,
        );
      } catch (e) {
        Logger.error('Error sending logout notification: $e', e);
      }
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: workerId,
          date: today,
          inTime: null,
          outTime: outTime,
          present: 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
    } catch (e) {
      Logger.info("❌ Failed to mark logout: $e");
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final payload = {
        'worker_id': workerId,
        'date': today,
        'out_time': outTime,
      };

      // Add location data if provided
      if (address != null) payload['logout_address'] = address;
      if (latitude != null) payload['logout_latitude'] = latitude;
      if (longitude != null) payload['logout_longitude'] = longitude;

      await supa.from('attendance').update(payload).eq('worker_id', workerId).eq('date', today);
      Logger.info("✅ Logout marked for worker $workerId at $outTime (retry)");
      
      // Create attendance log for logout (retry)
      try {
        final log = AttendanceLog(
          workerId: workerId,
          date: today,
          punchTime: outTime,
          punchType: 'logout',
          locationLatitude: latitude,
          locationLongitude: longitude,
          locationAddress: address,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _attendanceLogService.addLog(log);
        Logger.info("✅ Logout log created for worker $workerId at $outTime (retry)");
      } catch (e) {
        Logger.error('Error creating logout log (retry): $e', e);
      }
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: workerId,
          date: today,
          inTime: null,
          outTime: outTime,
          present: 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
    }
  }

  /// Fetch today's attendance summary
  Future<Map<String, int>> getTodaySummary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    try {
      // Get today's login status data instead of attendance data
      final data = await supa.from('login_status').select().eq('date', today);
      
      final total = data.length;
      final present = data.where((a) => a['is_logged_in'] == true).length;
      final absent = total - present;

      return {
        'total': total,
        'present': present,
        'absent': absent,
      };
    } catch (e) {
      Logger.info("❌ Failed to get today's summary: $e");
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final data = await supa.from('login_status').select().eq('date', today);
      
      final total = data.length;
      final present = data.where((a) => a['is_logged_in'] == true).length;
      final absent = total - present;

      return {
        'total': total,
        'present': present,
        'absent': absent,
      };
    }
  }

  /// Auto mark absentees (can be triggered on app start)
  Future<void> markAbsentees() async {
    try {
      await supa.rpc('exec_sql', params: {
        'query': 'select mark_absent_workers();'
      });
      Logger.info("✅ Absentees marked successfully");
    } catch (e) {
      Logger.info("⚠️ Failed to auto-mark absentees: $e");
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      await supa.rpc('exec_sql', params: {
        'query': 'select mark_absent_workers();'
      });
      Logger.info("✅ Absentees marked successfully (retry)");
    }
  }

  Future<int> insert(Map<String, dynamic> data) async {
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    try {
      Logger.info('AttendanceService.insert - payload: $payload');
      final res = await supa.from('attendance').insert(payload).select('id').single();
      
      // Extract workerId and date for sync function
      final workerId = payload['worker_id'] as int;
      final date = payload['date'] as String;
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: workerId,
          date: date,
          inTime: payload['in_time'] as String?,
          outTime: payload['out_time'] as String?,
          present: (payload['present'] as bool?) == true ? 1 : 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
      
      return (res['id'] as int);
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      Logger.info('AttendanceService.insert - retrying after schema refresh');
      final res = await supa.from('attendance').insert(payload).select('id').single();
      
      // Extract workerId and date for sync function
      final workerId = payload['worker_id'] as int;
      final date = payload['date'] as String;
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: workerId,
          date: date,
          inTime: payload['in_time'] as String?,
          outTime: payload['out_time'] as String?,
          present: (payload['present'] as bool?) == true ? 1 : 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
      
      return (res['id'] as int);
    }
  }

  Future<List<Map<String, dynamic>>> all() async {
    try {
      return await supa.from('attendance').select().order('id');
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('attendance').select().order('id');
    }
  }

  Future<List<Map<String, dynamic>>> byWorker(int workerId) async {
    try {
      return await supa.from('attendance').select().eq('worker_id', workerId).order('date');
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('attendance').select().eq('worker_id', workerId).order('date');
    }
  }

  Future<List<Map<String, dynamic>>> byWorkerAndDate(int workerId, String yyyyMmDd) async {
    try {
      return await supa.from('attendance').select().eq('worker_id', workerId).eq('date', yyyyMmDd);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('attendance').select().eq('worker_id', workerId).eq('date', yyyyMmDd);
    }
  }

  /// Get attendance records with pagination
  Future<List<Map<String, dynamic>>> getAttendancePaged({
    required String date,
    required int limit,
    required int offset,
  }) async {
    final res = await supa
        .from('attendance')
        .select()
        .eq('date', date)
        .order('in_time', ascending: true)
        .range(offset, offset + limit - 1);
    return res;
  }

  /// Insert or update attendance
  Future<int> upsertAttendance(Map<String, dynamic> attendance) async {
    final payload = MapCase.toSnake(attendance);
    
    // Remove ID for GENERATED ALWAYS identity columns
    payload.remove('id');
    
    final workerId = payload['worker_id'] as int;
    final date = payload['date'] as String;

    try {
      // First check if a record already exists for this worker_id and date
      final existingRecord = await supa
          .from('attendance')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        final id = existingRecord['id'] as int;
        Logger.info('AttendanceService.upsertAttendance - updating existing record with id: $id, payload: $payload');
        await supa.from('attendance').update(payload).eq('id', id);
        
        // Send notification to worker
        try {
          await _sendAttendanceNotification(
            workerId: workerId,
            date: date,
            present: (payload['present'] as bool?) == true,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
          );
        } catch (e) {
          Logger.error('Error sending attendance notification: $e', e);
        }
        
        // Sync login status with attendance
        try {
          await syncLoginStatusWithAttendance(
            workerId: workerId,
            date: date,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
            present: (payload['present'] as bool?) == true ? 1 : 0,
          );
        } catch (e) {
          Logger.error('Error syncing login status with attendance: $e', e);
        }
        
        return id;
      } else {
        // Insert new record
        Logger.info('AttendanceService.upsertAttendance - inserting new record with payload: $payload');
        final res = await supa.from('attendance').insert(payload).select('id').single();
        
        // Send notification to worker
        try {
          await _sendAttendanceNotification(
            workerId: workerId,
            date: date,
            present: (payload['present'] as bool?) == true,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
          );
        } catch (e) {
          Logger.error('Error sending attendance notification: $e', e);
        }
        
        // Sync login status with attendance
        try {
          await syncLoginStatusWithAttendance(
            workerId: workerId,
            date: date,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
            present: (payload['present'] as bool?) == true ? 1 : 0,
          );
        } catch (e) {
          Logger.error('Error syncing login status with attendance: $e', e);
        }
        
        return res['id'] as int;
      }
    } catch (e, st) {
      // Log the full error and stacktrace so we can see why supabase rejected the payload
      Logger.error('AttendanceService.upsertAttendance error: $e\n$st', e);
      // Attempt schema refresh if it's a schema/cache type error
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));

      // Retry the same logic
      Logger.info('AttendanceService.upsertAttendance - retrying after schema refresh - payload: $payload');
      
      // First check if a record already exists for this worker_id and date
      final existingRecord = await supa
          .from('attendance')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        final id = existingRecord['id'] as int;
        Logger.info('AttendanceService.upsertAttendance - retrying update existing record with id: $id, payload: $payload');
        await supa.from('attendance').update(payload).eq('id', id);
        
        // Send notification to worker
        try {
          await _sendAttendanceNotification(
            workerId: workerId,
            date: date,
            present: (payload['present'] as bool?) == true,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
          );
        } catch (e) {
          Logger.error('Error sending attendance notification: $e', e);
        }
        
        // Sync login status with attendance
        try {
          await syncLoginStatusWithAttendance(
            workerId: workerId,
            date: date,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
            present: (payload['present'] as bool?) == true ? 1 : 0,
          );
        } catch (e) {
          Logger.error('Error syncing login status with attendance: $e', e);
        }
        
        return id;
      } else {
        // Insert new record
        Logger.info('AttendanceService.upsertAttendance - retrying insert new record with payload: $payload');
        final res = await supa.from('attendance').insert(payload).select('id').single();
        
        // Send notification to worker
        try {
          await _sendAttendanceNotification(
            workerId: workerId,
            date: date,
            present: (payload['present'] as bool?) == true,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
          );
        } catch (e) {
          Logger.error('Error sending attendance notification: $e', e);
        }
        
        // Sync login status with attendance
        try {
          await syncLoginStatusWithAttendance(
            workerId: workerId,
            date: date,
            inTime: payload['in_time'] as String?,
            outTime: payload['out_time'] as String?,
            present: (payload['present'] as bool?) == true ? 1 : 0,
          );
        } catch (e) {
          Logger.error('Error syncing login status with attendance: $e', e);
        }
        
        return res['id'] as int;
      }
    }
  }

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    // Remove id from payload for update operations
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      Logger.info('AttendanceService.updateById - removing id field from payload');
      payload.remove('id');
    }
    
    try {
      Logger.info('AttendanceService.updateById - payload: $payload, id: $id');
      await supa.from('attendance').update(payload).eq('id', id);
      
      // Send notification to worker
      try {
        await _sendAttendanceNotification(
          workerId: payload['worker_id'] as int,
          date: payload['date'] as String,
          present: (payload['present'] as bool?) == true,
          inTime: payload['in_time'] as String?,
          outTime: payload['out_time'] as String?,
        );
      } catch (e) {
        Logger.error('Error sending attendance notification: $e', e);
      }
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: payload['worker_id'] as int,
          date: payload['date'] as String,
          inTime: payload['in_time'] as String?,
          outTime: payload['out_time'] as String?,
          present: (payload['present'] as bool?) == true ? 1 : 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      Logger.info('AttendanceService.updateById - retrying after schema refresh');
      await supa.from('attendance').update(payload).eq('id', id);
      
      // Send notification to worker
      try {
        await _sendAttendanceNotification(
          workerId: payload['worker_id'] as int,
          date: payload['date'] as String,
          present: (payload['present'] as bool?) == true,
          inTime: payload['in_time'] as String?,
          outTime: payload['out_time'] as String?,
        );
      } catch (e) {
        Logger.error('Error sending attendance notification: $e', e);
      }
      
      // Sync login status with attendance
      try {
        await syncLoginStatusWithAttendance(
          workerId: payload['worker_id'] as int,
          date: payload['date'] as String,
          inTime: payload['in_time'] as String?,
          outTime: payload['out_time'] as String?,
          present: (payload['present'] as bool?) == true ? 1 : 0,
        );
      } catch (e) {
        Logger.error('Error syncing login status with attendance: $e', e);
      }
    }
  }

  Future<void> deleteById(int id) async {
    try {
      await supa.from('attendance').delete().eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('attendance').delete().eq('id', id);
    }
  }

  /// Sync login status with attendance records
  /// This ensures that when admin marks attendance, the login status is also updated accordingly
  Future<void> syncLoginStatusWithAttendance({
    required int workerId,
    required String date,
    required String? inTime,
    required String? outTime,
    required int present,
  }) async {
    try {
      // 1. Check if login_status exists
      final existing = await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (present == 1) {
        // Admin marked present → LOGIN worker
        if (existing == null) {
          await supa.from('login_status').insert({
            'worker_id': workerId,
            'date': date,
            'login_time': inTime,
            'is_logged_in': true,
          });
        } else {
          await supa
              .from('login_status')
              .update({
                'login_time': inTime,
                'is_logged_in': true,
              })
              .eq('id', existing['id']);
        }
      } else {
        // Admin marked absent → LOGOUT worker
        if (existing == null) {
          await supa.from('login_status').insert({
            'worker_id': workerId,
            'date': date,
            'logout_time': outTime,
            'is_logged_in': false,
          });
        } else {
          await supa
              .from('login_status')
              .update({
                'logout_time': outTime,
                'is_logged_in': false,
              })
              .eq('id', existing['id']);
        }
      }
      Logger.info('Successfully synced login status with attendance for worker $workerId on $date');
    } catch (e) {
      Logger.error('Error syncing login status with attendance: $e', e);
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      // 1. Check if login_status exists
      final existing = await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (present == 1) {
        // Admin marked present → LOGIN worker
        if (existing == null) {
          await supa.from('login_status').insert({
            'worker_id': workerId,
            'date': date,
            'login_time': inTime,
            'is_logged_in': true,
          });
        } else {
          await supa
              .from('login_status')
              .update({
                'login_time': inTime,
                'is_logged_in': true,
              })
              .eq('id', existing['id']);
        }
      } else {
        // Admin marked absent → LOGOUT worker
        if (existing == null) {
          await supa.from('login_status').insert({
            'worker_id': workerId,
            'date': date,
            'logout_time': outTime,
            'is_logged_in': false,
          });
        } else {
          await supa
              .from('login_status')
              .update({
                'logout_time': outTime,
                'is_logged_in': false,
              })
              .eq('id', existing['id']);
        }
      }
      Logger.info('Successfully retried syncing login status with attendance for worker $workerId on $date');
    }
  }
}