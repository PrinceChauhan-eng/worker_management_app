import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
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
    
    // Remove the automatic created_by setting since we're not using Supabase Auth
    // The created_by field should be set by the calling code if needed
    
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
    // For GENERATED ALWAYS identity columns, never pass an ID value
    // Remove ID for update operations
    if (payload.containsKey('id')) {
      payload.remove('id');
    }
    
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

  /// Get all workers - no RLS or current admin filtering since we're not using Supabase Auth
  Future<List<Map<String, dynamic>>> getWorkers() async {
    try {
      // Simply return all users with role 'worker'
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
      
      final response = await supa
          .from('users')
          .select()
          .eq('role', 'worker')
          .order('id');
      
      return response;
    }
  }

  /// Check if a user exists - no RLS checking since we're not using Supabase Auth
  Future<bool> doesUserExist(int userId) async {
    try {
      // Simply check if we can retrieve the user
      final user = await supa
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      return user != null;
    } catch (e) {
      // If there's an error, assume the user doesn't exist
      return false;
    }
  }

  /// Upload profile photo using Dio multipart request
  static Future<String?> uploadProfilePhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        "user_id": userId,
        "photo": await MultipartFile.fromFile(filePath),
      });

      // Note: This is a placeholder URL. In a real implementation, you would
      // need to implement an endpoint that handles the file upload and returns
      // the URL of the uploaded image. For now, we'll simulate a successful upload.
      
      // For demonstration purposes, we'll return a placeholder URL
      // In a real implementation, you would make an actual HTTP request:
      // final response = await dio.post("/user/upload-photo", data: formData);
      // return response.data["url"];
      
      // Simulate successful upload and return a placeholder URL
      // In a real app, this would be the actual URL returned from your backend
      return "https://via.placeholder.com/150";
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  /// Mobile Upload (Dio)
  static Future<String?> uploadAdminPhotoMobile({
    required String userId,
    required String filePath,
  }) async {
    try {
      // Note: This is a placeholder implementation. In a real app, you would:
      // 1. Make an actual HTTP request to your backend
      // 2. Upload the file
      // 3. Return the actual URL from your backend
      
      // For demonstration purposes, we'll simulate a successful upload
      // and return a placeholder URL with a unique identifier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return "https://via.placeholder.com/150?userId=$userId&timestamp=$timestamp";
    } catch (e) {
      print("Upload mobile error: $e");
      return null;
    }
  }

  /// Web Upload (Dio)
  static Future<String?> uploadAdminPhotoWeb({
    required String userId,
    required Uint8List bytes,
  }) async {
    try {
      // Note: This is a placeholder implementation. In a real app, you would:
      // 1. Make an actual HTTP request to your backend
      // 2. Upload the file bytes
      // 3. Return the actual URL from your backend
      
      // For demonstration purposes, we'll simulate a successful upload
      // and return a placeholder URL with a unique identifier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return "https://via.placeholder.com/150?userId=$userId&timestamp=$timestamp";
    } catch (e) {
      print("Upload web error: $e");
      return null;
    }
  }
}