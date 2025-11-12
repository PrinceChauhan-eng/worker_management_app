import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart'; // Add this import

class LoginService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  /// Insert or update login_status (unique worker_id + date)
  Future<int> upsertStatus(Map<String, dynamic> status) async {
    final payload = MapCase.toSnake(status);

    // Only remove ID if it's null for insert operations
    if (payload['id'] == null) {
      payload.remove('id');
    }

    try {
      final res = await supa
          .from('login_status')
          .upsert(payload, onConflict: 'worker_id,date')
          .select('id')
          .single();

      return res['id'] as int;
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final res = await supa
          .from('login_status')
          .upsert(payload, onConflict: 'worker_id,date')
          .select('id')
          .single();

      return res['id'] as int;
    }
  }

  /// Get all login status
  Future<List<Map<String, dynamic>>> statuses() async {
    try {
      return await supa.from('login_status').select().order('date', ascending: false);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('login_status').select().order('date', ascending: false);
    }
  }

  /// Worker-specific logs
  Future<List<Map<String, dynamic>>> statusesByWorker(int workerId) async {
    try {
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .order('date', ascending: false);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .order('date', ascending: false);
    }
  }

  /// Check today's login status
  Future<Map<String, dynamic>?> todayForWorker(int workerId, String yyyyMmDd) async {
    try {
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .eq('date', yyyyMmDd)
          .maybeSingle();
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .eq('date', yyyyMmDd)
          .maybeSingle();
    }
  }

  /// All currently logged-in workers
  Future<List<Map<String, dynamic>>> currentlyLoggedIn() async {
    try {
      return await supa.from('login_status').select().eq('is_logged_in', true);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('login_status').select().eq('is_logged_in', true);
    }
  }

  /// Insert login history
  Future<int> insertHistory(Map<String, dynamic> hist) async {
    final payload = MapCase.toSnake(hist);
    // Only remove ID if it's null for insert operations
    if (payload['id'] == null) {
      payload.remove('id');
    }

    try {
      final res = await supa
          .from('login_history')
          .insert(payload)
          .select('id')
          .single();

      return res['id'] as int;
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final res = await supa
          .from('login_history')
          .insert(payload)
          .select('id')
          .single();

      return res['id'] as int;
    }
  }
}