import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart'; // Add this import

class LoginService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  /// Insert or update login_status
  Future<int> upsertStatus(Map<String, dynamic> status) async {
    final payload = MapCase.toSnake(status);
    
    // For GENERATED ALWAYS identity columns, always remove ID
    payload.remove('id');
    
    final workerId = payload['worker_id'] as int;
    final date = payload['date'] as String;

    try {
      // First check if a record already exists for this worker_id and date
      final existingRecord = await supa
          .from('login_status')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        final id = existingRecord['id'] as int;
        await supa.from('login_status').update(payload).eq('id', id);
        return id;
      } else {
        // Insert new record
        final res = await supa
            .from('login_status')
            .insert(payload)
            .select('id')
            .single();
        return res['id'] as int;
      }
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the same logic
      // First check if a record already exists for this worker_id and date
      final existingRecord = await supa
          .from('login_status')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', date)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        final id = existingRecord['id'] as int;
        await supa.from('login_status').update(payload).eq('id', id);
        return id;
      } else {
        // Insert new record
        final res = await supa
            .from('login_status')
            .insert(payload)
            .select('id')
            .single();
        return res['id'] as int;
      }
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

  /// Get today's login status
  Future<List<Map<String, dynamic>>> getTodayLoginStatus() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      return await supa.from('login_status').select().eq('date', today);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      final today = DateTime.now().toIso8601String().substring(0, 10);
      return await supa.from('login_status').select().eq('date', today);
    }
  }

  /// Insert login history
  Future<int> insertHistory(Map<String, dynamic> hist) async {
    final payload = MapCase.toSnake(hist);
    // For GENERATED ALWAYS identity columns, only remove ID if it's null/empty
    // Keep ID for updates, remove for inserts
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