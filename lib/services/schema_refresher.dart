import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class SchemaRefresher {
  final SupabaseClient supa = Supabase.instance.client;

  /// Detects and repairs Supabase cache issue automatically
  Future<void> tryFixSchemaError(Object error) async {
    final message = error.toString();

    // Detect known cache issue
    if (message.contains("schema cache") || 
        message.contains("PGRST204") || 
        message.contains("column") && message.contains("in the schema cache")) {
      Logger.info("⚠️ Schema cache seems outdated, triggering reload...");

      try {
        await supa.rpc('exec_sql', params: {
          'query': "NOTIFY pgrst, 'reload schema';"
        });
        Logger.info("✅ Supabase schema cache reload triggered successfully!");
      } catch (e) {
        Logger.error("❌ Failed to refresh schema: $e", e);
      }
    }
  }
  
  /// Extended error detection for more comprehensive schema issues
  Future<void> tryFixExtendedSchemaError(Object error) async {
    final message = error.toString().toLowerCase();
    
    // Extended detection for various schema-related errors
    if (message.contains("schema cache") || 
        message.contains("pgrst204") || 
        message.contains("column") && message.contains("in the schema cache") ||
        message.contains("could not find") ||
        message.contains("does not exist") ||
        message.contains("missing") && message.contains("column")) {
      
      Logger.info("⚠️ Potential schema issue detected, triggering cache reload...");
      
      try {
        await supa.rpc('exec_sql', params: {
          'query': "NOTIFY pgrst, 'reload schema';"
        });
        Logger.info("✅ Supabase schema cache reload triggered successfully!");
      } catch (e) {
        Logger.error("❌ Failed to refresh schema: $e", e);
      }
    }
  }
}