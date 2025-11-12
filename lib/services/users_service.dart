import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart'; // Add this import

class UsersService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  Future<int> insertUser(Map<String, dynamic> user) async {
    // Accept either camelCase or snake_case maps
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(user);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    try {
      final res = await supa.from('users').insert(payload).select('id').single();
      return (res['id'] as int);
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final res = await supa.from('users').insert(payload).select('id').single();
      return (res['id'] as int);
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      return await supa.from('users').select().order('id');
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('users').select().order('id');
    }
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    try {
      return await supa.from('users').select().eq('id', id).maybeSingle();
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('users').select().eq('id', id).maybeSingle();
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    try {
      await supa.from('users').update(payload).eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('users').update(payload).eq('id', id);
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await supa.from('users').delete().eq('id', id);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      await supa.from('users').delete().eq('id', id);
    }
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      return await supa.from('users').select().eq('phone', phone).maybeSingle();
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('users').select().eq('phone', phone).maybeSingle();
    }
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      return await supa.from('users').select().eq('email', email).maybeSingle();
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('users').select().eq('email', email).maybeSingle();
    }
  }
}