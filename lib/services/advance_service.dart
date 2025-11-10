import '../utils/map_case.dart';
import 'supabase_client.dart';

class AdvanceService {
  Future<int> insert(Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    final res = await supa.from('advance').insert(payload).select('id').single();
    return (res['id'] as int);
  }

  Future<List<Map<String, dynamic>>> all() async =>
      await supa.from('advance').select().order('id');

  Future<List<Map<String, dynamic>>> byWorker(int workerId) async =>
      await supa.from('advance').select().eq('worker_id', workerId).order('date');

  Future<List<Map<String, dynamic>>> byWorkerAndMonth(int workerId, String monthPrefix) async =>
      await supa.from('advance').select()
        .eq('worker_id', workerId)
        .ilike('date', '$monthPrefix%'); // if you stored date as text previously

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    await supa.from('advance').update(payload).eq('id', id);
  }

  Future<void> deleteById(int id) async {
    await supa.from('advance').delete().eq('id', id);
  }
}