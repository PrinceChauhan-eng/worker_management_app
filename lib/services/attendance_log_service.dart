import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance_log.dart';

class AttendanceLogService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all logs for a worker on a specific date
  Future<List<Map<String, dynamic>>> getLogsByWorkerAndDate(int workerId, String date) async {
    try {
      final response = await _supabase
          .from('attendance_logs')
          .select()
          .eq('worker_id', workerId)
          .eq('date', date)
          .order('punch_time');
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get timeline for a worker on a specific date
  Future<List<AttendanceLog>> getTimeline(int workerId, String date) async {
    try {
      final data = await getLogsByWorkerAndDate(workerId, date);
      return data.map((log) => AttendanceLog.fromMap(log)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Add a new log entry
  Future<int> addLog(AttendanceLog log) async {
    try {
      final response = await _supabase
          .from('attendance_logs')
          .insert(log.toMap())
          .select('id')
          .single();
      
      return response['id'];
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing log entry
  Future<void> updateLog(AttendanceLog log) async {
    try {
      if (log.id == null) {
        throw Exception('Cannot update log without ID');
      }
      
      await _supabase
          .from('attendance_logs')
          .update(log.toMap())
          .eq('id', log.id!);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a log entry
  Future<void> deleteLog(int id) async {
    try {
      await _supabase
          .from('attendance_logs')
          .delete()
          .eq('id', id);
    } catch (e) {
      rethrow;
    }
  }
}