import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/base_service.dart';
import '../models/attendance.dart' as app_attendance;
import '../utils/map_case.dart';
import 'supabase_client.dart';

class AttendanceService {
  static const String _tableName = 'attendance';

  Future<int> insert(Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    final res = await supa.from('attendance').insert(payload).select('id').single();
    return (res['id'] as int);
  }

  Future<List<Map<String, dynamic>>> all() async =>
      await supa.from('attendance').select().order('id');

  Future<List<Map<String, dynamic>>> byWorker(int workerId) async =>
      await supa.from('attendance').select().eq('worker_id', workerId).order('date');

  Future<List<Map<String, dynamic>>> byWorkerAndDate(int workerId, String yyyyMmDd) async =>
      await supa.from('attendance').select().eq('worker_id', workerId).eq('date', yyyyMmDd);

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    await supa.from('attendance').update(payload).eq('id', id);
  }

  Future<void> deleteById(int id) async {
    await supa.from('attendance').delete().eq('id', id);
  }
}
