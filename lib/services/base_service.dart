import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseService {
  final SupabaseClient supabase = Supabase.instance.client;
  
  // Abstract methods that subclasses must implement
  Future<int> insert(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getAll();
  Future<Map<String, dynamic>?> getById(int id);
  Future<int> update(int id, Map<String, dynamic> data);
  Future<int> delete(int id);
}