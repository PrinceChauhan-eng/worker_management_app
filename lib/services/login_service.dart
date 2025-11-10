import '../utils/map_case.dart';
import 'supabase_client.dart';

class LoginService {
  /// Insert or update login_status enforcing uniqueness on (worker_id, date)
  Future<int> upsertStatus(Map<String, dynamic> status) async {
    final payload = MapCase.toSnake(status);
    final res = await supa
        .from('login_status')
        .upsert(payload, onConflict: 'worker_id,date')
        .select('id')
        .single();
    return (res['id'] as int);
  }

  Future<List<Map<String, dynamic>>> statuses() async =>
      await supa.from('login_status').select().order('date', ascending: false);

  Future<List<Map<String, dynamic>>> statusesByWorker(int workerId) async =>
      await supa.from('login_status').select().eq('worker_id', workerId).order('date', ascending: false);

  Future<Map<String, dynamic>?> todayForWorker(int workerId, String yyyyMmDd) async =>
      await supa.from('login_status').select().eq('worker_id', workerId).eq('date', yyyyMmDd).maybeSingle();

  Future<List<Map<String, dynamic>>> currentlyLoggedIn() async =>
      await supa.from('login_status').select().eq('is_logged_in', true);

  Future<int> insertHistory(Map<String, dynamic> hist) async {
    final payload = MapCase.toSnake(hist);
    final res = await supa.from('login_history').insert(payload).select('id').single();
    return (res['id'] as int);
  }
}