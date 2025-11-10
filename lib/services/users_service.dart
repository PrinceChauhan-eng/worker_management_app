import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/base_service.dart';
import '../models/user.dart' as app_user;
import '../utils/map_case.dart';
import 'supabase_client.dart';

class UsersService {
  Future<int> insertUser(Map<String, dynamic> user) async {
    // Accept either camelCase or snake_case maps
    final payload = MapCase.toSnake(user);
    final res = await supa.from('users').insert(payload).select('id').single();
    return (res['id'] as int);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return await supa.from('users').select().order('id');
  }

  Future<Map<String, dynamic>?> getUser(int id) async {
    return await supa.from('users').select().eq('id', id).maybeSingle();
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final payload = MapCase.toSnake(data);
    await supa.from('users').update(payload).eq('id', id);
  }

  Future<void> deleteUser(int id) async {
    await supa.from('users').delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    return await supa.from('users').select().eq('phone', phone).maybeSingle();
  }
}