import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/base_service.dart';
import '../models/salary.dart' as app_salary;
import '../utils/map_case.dart';
import 'supabase_client.dart';

class SalaryService {
  static const String _tableName = 'salary';

  Future<int> insert(Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    final res = await supa.from('salary').insert(payload).select('id').single();
    return (res['id'] as int);
  }

  Future<List<Map<String, dynamic>>> all() async =>
      await supa.from('salary').select().order('id');

  Future<List<Map<String, dynamic>>> paid() async =>
      await supa.from('salary').select().eq('paid', true);

  Future<List<Map<String, dynamic>>> paidByMonth(String monthPrefix) async =>
      await supa.from('salary').select().eq('paid', true).ilike('month', '$monthPrefix%');

  Future<List<Map<String, dynamic>>> paidByWorkerAndMonth(int workerId, String monthPrefix) async =>
      await supa.from('salary').select()
        .eq('worker_id', workerId)
        .eq('paid', true)
        .ilike('month', '$monthPrefix%');

  Future<List<Map<String, dynamic>>> byWorker(int workerId) async =>
      await supa.from('salary').select().eq('worker_id', workerId).order('id');

  Future<Map<String, dynamic>?> byWorkerAndMonth(int workerId, String month) async =>
      await supa.from('salary').select().eq('worker_id', workerId).eq('month', month).maybeSingle();

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    await supa.from('salary').update(payload).eq('id', id);
  }

  Future<void> deleteById(int id) async {
    await supa.from('salary').delete().eq('id', id);
  }
}