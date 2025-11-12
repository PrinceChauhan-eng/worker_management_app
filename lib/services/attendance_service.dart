import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/map_case.dart';
import 'supabase_client.dart';
import '../utils/logger.dart';
import 'schema_refresher.dart';

class AttendanceService {
  static const String _tableName = 'attendance';
  final SchemaRefresher _schemaRefresher = SchemaRefresher();

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

      await supa.from('attendance').upsert(payload, onConflict: 'worker_id,date');
      Logger.debug("✅ Login marked for worker $workerId at $inTime");
    } catch (e) {
      Logger.debug("❌ Failed to mark login: $e");
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

      await supa.from('attendance').upsert(payload, onConflict: 'worker_id,date');
      Logger.debug("✅ Login marked for worker $workerId at $inTime (retry)");
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
      Logger.debug("✅ Logout marked for worker $workerId at $outTime");
    } catch (e) {
      Logger.debug("❌ Failed to mark logout: $e");
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
      Logger.debug("✅ Logout marked for worker $workerId at $outTime (retry)");
    }
  }

  /// Fetch today's attendance summary
  Future<Map<String, int>> getTodaySummary() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    try {
      final data = await supa.from('attendance').select().eq('date', today);
      
      final total = data.length;
      final present = data.where((a) => a['present'] == true).length;
      final absent = total - present;

      return {
        'total': total,
        'present': present,
        'absent': absent,
      };
    } catch (e) {
      Logger.debug("❌ Failed to get today's summary: $e");
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final data = await supa.from('attendance').select().eq('date', today);
      
      final total = data.length;
      final present = data.where((a) => a['present'] == true).length;
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
      Logger.debug("✅ Absentees marked successfully");
    } catch (e) {
      Logger.debug("⚠️ Failed to auto-mark absentees: $e");
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      await supa.rpc('exec_sql', params: {
        'query': 'select mark_absent_workers();'
      });
      Logger.debug("✅ Absentees marked successfully (retry)");
    }
  }

  Future<int> insert(Map<String, dynamic> data) async {
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    try {
      Logger.debug('AttendanceService.insert - payload: $payload');
      final res = await supa.from('attendance').insert(payload).select('id').single();
      return (res['id'] as int);
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      Logger.debug('AttendanceService.insert - retrying after schema refresh');
      final res = await supa.from('attendance').insert(payload).select('id').single();
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

  /// Insert or update attendance (unique worker_id + date)
  Future<int> upsertAttendance(Map<String, dynamic> attendance) async {
    final payload = MapCase.toSnake(attendance);

    // Only remove ID if it's null for insert operations
    if (payload['id'] == null) {
      payload.remove('id');
    }

    try {
      Logger.debug('AttendanceService.upsertAttendance - payload: $payload');
      final res = await supa
          .from('attendance')
          .upsert(payload, onConflict: 'worker_id,date')
          .select('id')
          .single();

      return res['id'] as int;
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      Logger.debug('AttendanceService.upsertAttendance - retrying after schema refresh');
      final res = await supa
          .from('attendance')
          .upsert(payload, onConflict: 'worker_id,date')
          .select('id')
          .single();

      return res['id'] as int;
    }
  }

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    // Remove id from payload for update operations
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      Logger.debug('AttendanceService.updateById - removing id field from payload');
      payload.remove('id');
    }
    
    try {
      Logger.debug('AttendanceService.updateById - payload: $payload, id: $id');
      await supa.from('attendance').update(payload).eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      Logger.debug('AttendanceService.updateById - retrying after schema refresh');
      await supa.from('attendance').update(payload).eq('id', id);
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
}