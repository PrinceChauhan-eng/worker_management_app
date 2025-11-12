import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart'; // Add this import

class NotificationsService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  Future<int> insert(Map<String, dynamic> n) async {
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(n);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    try {
      final res = await supa.from('notifications').insert(payload).select('id').single();
      return (res['id'] as int);
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final res = await supa.from('notifications').insert(payload).select('id').single();
      return (res['id'] as int);
    }
  }

  Future<List<Map<String, dynamic>>> all() async {
    try {
      return await supa.from('notifications').select().order('created_at', ascending: false);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('notifications').select().order('created_at', ascending: false);
    }
  }

  Future<List<Map<String, dynamic>>> byUser(int userId, String userRole) async {
    try {
      return await supa.from('notifications').select()
        .eq('user_id', userId)
        .eq('user_role', userRole)
        .order('created_at', ascending: false);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('notifications').select()
        .eq('user_id', userId)
        .eq('user_role', userRole)
        .order('created_at', ascending: false);
    }
  }

  Future<List<Map<String, dynamic>>> unreadByUser(int userId, String userRole) async {
    try {
      return await supa.from('notifications').select()
        .eq('user_id', userId)
        .eq('user_role', userRole)
        .eq('is_read', false);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('notifications').select()
        .eq('user_id', userId)
        .eq('user_role', userRole)
        .eq('is_read', false);
    }
  }

  Future<int> unreadCount(int userId, String userRole) async {
    try {
      return (await unreadByUser(userId, userRole)).length;
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return (await unreadByUser(userId, userRole)).length;
    }
  }

  Future<void> markRead(int id) async {
    try {
      await supa.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('notifications').update({'is_read': true}).eq('id', id);
    }
  }

  Future<void> markAllRead(int userId, String userRole) async {
    try {
      await supa.from('notifications').update({'is_read': true})
        .eq('user_id', userId)
        .eq('user_role', userRole);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('notifications').update({'is_read': true})
        .eq('user_id', userId)
        .eq('user_role', userRole);
    }
  }

  Future<void> delete(int id) async {
    try {
      await supa.from('notifications').delete().eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('notifications').delete().eq('id', id);
    }
  }

  Future<void> deleteAll() async {
    try {
      await supa.from('notifications').delete();
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('notifications').delete();
    }
  }
}