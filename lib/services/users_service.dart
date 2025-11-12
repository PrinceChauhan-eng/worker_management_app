import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart'; // Add this import
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  Future<int> insertUser(Map<String, dynamic> user) async {
    // Accept either camelCase or snake_case maps
    // Remove id from payload for insert operations to let Supabase auto-generate it
    final payload = MapCase.toSnake(user);
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
    // Automatically set created_by to current admin if not already set
    if (!payload.containsKey('created_by') || payload['created_by'] == null) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        payload['created_by'] = currentUser.id;
      }
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

  /// Get all workers for the current admin
  Future<List<Map<String, dynamic>>> getWorkersForCurrentAdmin() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      // Due to RLS policies, this will only return workers mapped to the current admin
      final response = await supa
          .from('users')
          .select()
          .eq('role', 'worker')
          .order('id');
      
      return response;
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      final response = await supa
          .from('users')
          .select()
          .eq('role', 'worker')
          .order('id');
      
      return response;
    }
  }

  /// Check if current admin has access to a specific user
  Future<bool> doesCurrentAdminHaveAccessToUser(int userId) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      // Due to RLS policies, if we can retrieve the user, the admin has access
      final user = await supa
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return user != null;
    } catch (e) {
      // If there's an error (like permission denied), the admin doesn't have access
      return false;
    }
  }
}