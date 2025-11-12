import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class AdminUserMappingService {
  final SupabaseClient supa = Supabase.instance.client;

  /// Create a mapping between an admin and a user
  Future<void> createMapping(String adminId, int userId) async {
    try {
      await supa.from('admin_user_mapping').insert({
        'admin_id': adminId,
        'user_id': userId,
      });
      Logger.info('✅ Admin-user mapping created: admin $adminId -> user $userId');
    } catch (e) {
      Logger.error('Failed to create admin-user mapping: $e', e);
      rethrow;
    }
  }

  /// Get all mappings for the current admin
  Future<List<Map<String, dynamic>>> getMappings() async {
    try {
      final response = await supa.from('admin_user_mapping').select();
      Logger.info('✅ Retrieved ${response.length} admin-user mappings');
      return response;
    } catch (e) {
      Logger.error('Failed to retrieve admin-user mappings: $e', e);
      rethrow;
    }
  }

  /// Get mappings for a specific admin
  Future<List<Map<String, dynamic>>> getMappingsForAdmin(String adminId) async {
    try {
      final response = await supa
          .from('admin_user_mapping')
          .select()
          .eq('admin_id', adminId);
      Logger.info('✅ Retrieved ${response.length} mappings for admin $adminId');
      return response;
    } catch (e) {
      Logger.error('Failed to retrieve mappings for admin $adminId: $e', e);
      rethrow;
    }
  }

  /// Get mappings for a specific user
  Future<List<Map<String, dynamic>>> getMappingsForUser(int userId) async {
    try {
      final response = await supa
          .from('admin_user_mapping')
          .select()
          .eq('user_id', userId);
      Logger.info('✅ Retrieved ${response.length} mappings for user $userId');
      return response;
    } catch (e) {
      Logger.error('Failed to retrieve mappings for user $userId: $e', e);
      rethrow;
    }
  }

  /// Delete a specific mapping
  Future<void> deleteMapping(int mappingId) async {
    try {
      await supa.from('admin_user_mapping').delete().eq('id', mappingId);
      Logger.info('✅ Admin-user mapping deleted: $mappingId');
    } catch (e) {
      Logger.error('Failed to delete admin-user mapping $mappingId: $e', e);
      rethrow;
    }
  }

  /// Delete mapping between specific admin and user
  Future<void> deleteMappingByAdminAndUser(String adminId, int userId) async {
    try {
      await supa
          .from('admin_user_mapping')
          .delete()
          .eq('admin_id', adminId)
          .eq('user_id', userId);
      Logger.info('✅ Admin-user mapping deleted: admin $adminId -> user $userId');
    } catch (e) {
      Logger.error('Failed to delete mapping between admin $adminId and user $userId: $e', e);
      rethrow;
    }
  }

  /// Check if an admin has access to a user
  Future<bool> isAdminMappedToUser(String adminId, int userId) async {
    try {
      final response = await supa
          .from('admin_user_mapping')
          .select('id')
          .eq('admin_id', adminId)
          .eq('user_id', userId)
          .limit(1);
      
      final hasAccess = response.isNotEmpty;
      Logger.info('Admin $adminId ${hasAccess ? "has" : "does not have"} access to user $userId');
      return hasAccess;
    } catch (e) {
      Logger.error('Failed to check admin-user mapping: $e', e);
      return false;
    }
  }

  /// Get all users mapped to an admin
  Future<List<Map<String, dynamic>>> getUsersForAdmin(String adminId) async {
    try {
      final response = await supa
          .from('users')
          .select()
          .eq('created_by', adminId);
      
      Logger.info('✅ Retrieved ${response.length} users for admin $adminId');
      return response;
    } catch (e) {
      Logger.error('Failed to retrieve users for admin $adminId: $e', e);
      rethrow;
    }
  }

  /// Automatically map admin to user when creating a user
  Future<void> autoMapAdminToUser(String adminId, int userId) async {
    try {
      // Check if mapping already exists
      final exists = await isAdminMappedToUser(adminId, userId);
      if (!exists) {
        await createMapping(adminId, userId);
      }
    } catch (e) {
      Logger.error('Failed to auto-map admin $adminId to user $userId: $e', e);
      rethrow;
    }
  }
}