import '../utils/map_case.dart';
import 'supabase_client.dart';

class NotificationsService {
  Future<int> insert(Map<String, dynamic> n) async {
    final payload = MapCase.toSnake(n);
    final res = await supa.from('notifications').insert(payload).select('id').single();
    return (res['id'] as int);
  }

  Future<List<Map<String, dynamic>>> all() async =>
      await supa.from('notifications').select().order('created_at', ascending: false);

  Future<List<Map<String, dynamic>>> byUser(int userId, String userRole) async =>
      await supa.from('notifications').select()
        .eq('user_id', userId)
        .eq('user_role', userRole)
        .order('created_at', ascending: false);

  Future<List<Map<String, dynamic>>> unreadByUser(int userId, String userRole) async =>
      await supa.from('notifications').select()
        .eq('user_id', userId)
        .eq('user_role', userRole)
        .eq('is_read', false);

  Future<int> unreadCount(int userId, String userRole) async =>
      (await unreadByUser(userId, userRole)).length;

  Future<void> markRead(int id) async =>
      await supa.from('notifications').update({'is_read': true}).eq('id', id);

  Future<void> markAllRead(int userId, String userRole) async =>
      await supa.from('notifications').update({'is_read': true})
        .eq('user_id', userId)
        .eq('user_role', userRole);

  Future<void> delete(int id) async =>
      await supa.from('notifications').delete().eq('id', id);

  Future<void> deleteAll() async =>
      await supa.from('notifications').delete();
}