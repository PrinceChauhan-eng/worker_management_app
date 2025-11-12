import '../utils/map_case.dart';
import 'supabase_client.dart';
import '../utils/logger.dart';
import 'schema_refresher.dart'; // Add this import

class AdvanceService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  Future<int> insert(Map<String, dynamic> data) async {
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    try {
      Logger.debug('AdvanceService.insert - payload: $payload');
      final res = await supa.from('advance').insert(payload).select('id').single();
      return (res['id'] as int);
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      Logger.debug('AdvanceService.insert - retrying after schema refresh');
      final res = await supa.from('advance').insert(payload).select('id').single();
      return (res['id'] as int);
    }
  }

  Future<List<Map<String, dynamic>>> all() async {
    try {
      return await supa.from('advance').select().order('id');
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('advance').select().order('id');
    }
  }

  Future<List<Map<String, dynamic>>> byWorker(int workerId) async {
    try {
      return await supa.from('advance').select().eq('worker_id', workerId).order('date');
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('advance').select().eq('worker_id', workerId).order('date');
    }
  }

  Future<List<Map<String, dynamic>>> byWorkerAndMonth(int workerId, String monthPrefix) async {
    try {
      return await supa.from('advance').select()
        .eq('worker_id', workerId)
        .ilike('date', '$monthPrefix%'); // if you stored date as text previously
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('advance').select()
        .eq('worker_id', workerId)
        .ilike('date', '$monthPrefix%'); // if you stored date as text previously
    }
  }

  Future<void> updateById(int id, Map<String, dynamic> data) async {
    // Remove id from payload for update operations
    final payload = MapCase.toSnake(data);
    if (payload.containsKey('id')) {
      Logger.debug('AdvanceService.updateById - removing id field from payload');
      payload.remove('id');
    }
    
    try {
      Logger.debug('AdvanceService.updateById - payload: $payload, id: $id');
      await supa.from('advance').update(payload).eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      Logger.debug('AdvanceService.updateById - retrying after schema refresh');
      await supa.from('advance').update(payload).eq('id', id);
    }
  }

  Future<void> deleteById(int id) async {
    try {
      await supa.from('advance').delete().eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('advance').delete().eq('id', id);
    }
  }
}