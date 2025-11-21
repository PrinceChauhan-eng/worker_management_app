import '../utils/map_case.dart';
import 'supabase_client.dart';
import '../utils/logger.dart';
import 'schema_refresher.dart'; // Add this import

class SalaryService {
  static const String _tableName = 'salary';
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this

  Future<int> insert(Map<String, dynamic> data) async {
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    try {
      Logger.info('SalaryService.insert - payload: $payload');
      final res = await supa.from('salary').insert(payload).select('id').single();
      return (res['id'] as int);
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      Logger.info('SalaryService.insert - retrying after schema refresh');
      final res = await supa.from('salary').insert(payload).select('id').single();
      return (res['id'] as int);
    }
  }

  Future<List<Map<String, dynamic>>> all() async {
    try {
      return await supa.from('salary').select().order('id');
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('salary').select().order('id');
    }
  }

  Future<List<Map<String, dynamic>>> paid() async {
    try {
      return await supa.from('salary').select().eq('paid', true);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('salary').select().eq('paid', true);
    }
  }

  Future<List<Map<String, dynamic>>> paidByMonth(String monthPrefix) async {
    try {
      return await supa.from('salary').select().eq('paid', true).ilike('month', '$monthPrefix%');
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('salary').select().eq('paid', true).ilike('month', '$monthPrefix%');
    }
  }

  Future<List<Map<String, dynamic>>> paidByWorkerAndMonth(int workerId, String monthPrefix) async {
    try {
      return await supa.from('salary').select()
        .eq('worker_id', workerId)
        .eq('paid', true)
        .ilike('month', '$monthPrefix%');
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('salary').select()
        .eq('worker_id', workerId)
        .eq('paid', true)
        .ilike('month', '$monthPrefix%');
    }
  }

  Future<List<Map<String, dynamic>>> byWorker(int workerId) async {
    try {
      return await supa.from('salary').select().eq('worker_id', workerId).order('id');
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('salary').select().eq('worker_id', workerId).order('id');
    }
  }

  Future<Map<String, dynamic>?> byWorkerAndMonth(int workerId, String month) async {
    try {
      return await supa.from('salary').select().eq('worker_id', workerId).eq('month', month).maybeSingle();
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('salary').select().eq('worker_id', workerId).eq('month', month).maybeSingle();
    }
  }

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    // Remove id from payload for update operations
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      Logger.info('SalaryService.updateById - removing id field from payload');
      payload.remove('id');
    }
    
    try {
      Logger.info('SalaryService.updateById - payload: $payload, id: $id');
      await supa.from('salary').update(payload).eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      Logger.info('SalaryService.updateById - retrying after schema refresh');
      await supa.from('salary').update(payload).eq('id', id);
    }
  }

  Future<void> deleteById(int id) async {
    try {
      await supa.from('salary').delete().eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('salary').delete().eq('id', id);
    }
  }
}