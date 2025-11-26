import 'package:flutter/material.dart';
import '../utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityProvider extends ChangeNotifier {
  List<Map<String, dynamic>> timeline = [];

  Future<void> loadTimeline(int adminId) async {
    try {
      final response = await Supabase.instance.client
          .from('activity_logs')
          .select()
          .eq('user_id', adminId)
          .order('created_at', ascending: false);

      timeline = response;
      notifyListeners();
    } catch (e) {
      Logger.error("Timeline load error", e);
    }
  }

  Future<void> addLog(int userId, String type, String message) async {
    try {
      await Supabase.instance.client.from('activity_logs').insert({
        'user_id': userId,
        'type': type,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error("Timeline insert error", e);
    }
  }
}