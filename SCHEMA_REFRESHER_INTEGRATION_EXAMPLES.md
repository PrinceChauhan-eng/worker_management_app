# Schema Refresher Integration Examples

## Overview
This document provides practical examples of how to integrate the SchemaRefresher service into your existing Supabase operations to automatically handle schema cache errors.

## Basic Integration Pattern

### Simple Error Handling
```dart
import 'schema_refresher.dart';

final schemaFixer = SchemaRefresher();

try {
  // Example: inserting login record
  await supa.from('login_status').insert({
    'worker_id': workerId,
    'date': DateTime.now().toIso8601String().substring(0, 10),
    'login_time': DateTime.now().toIso8601String(),
    'login_latitude': location['latitude'],
    'login_longitude': location['longitude'],
    'login_address': location['address'],
  });
} catch (e) {
  await schemaFixer.tryFixSchemaError(e);
}
```

### With Automatic Retry
```dart
import 'schema_refresher.dart';

final schemaFixer = SchemaRefresher();

try {
  await supa.from('login_status').insert(payload);
} catch (e) {
  await schemaFixer.tryFixSchemaError(e);
  await Future.delayed(const Duration(seconds: 2));
  await supa.from('login_status').insert(payload);
}
```

## Service Class Integration

### LoginService Integration
```dart
import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart';

class LoginService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher();

  /// Insert or update login_status (unique worker_id + date)
  Future<int> upsertStatus(Map<String, dynamic> status) async {
    final payload = MapCase.toSnake(status);

    // Only remove ID if it's null for insert operations
    if (payload['id'] == null) {
      payload.remove('id');
    }

    try {
      final res = await supa
          .from('login_status')
          .upsert(payload, onConflict: 'worker_id,date')
          .select('id')
          .single();

      return res['id'] as int;
    } catch (e) {
      // Try to fix schema errors and retry
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry the operation
      final res = await supa
          .from('login_status')
          .upsert(payload, onConflict: 'worker_id,date')
          .select('id')
          .single();

      return res['id'] as int;
    }
  }

  /// Get all login status
  Future<List<Map<String, dynamic>>> statuses() async {
    try {
      return await supa.from('login_status').select().order('date', ascending: false);
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('login_status').select().order('date', ascending: false);
    }
  }

  /// Worker-specific logs
  Future<List<Map<String, dynamic>>> statusesByWorker(int workerId) async {
    try {
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .order('date', ascending: false);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .order('date', ascending: false);
    }
  }

  /// Check today's login status
  Future<Map<String, dynamic>?> todayForWorker(int workerId, String yyyyMmDd) async {
    try {
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .eq('date', yyyyMmDd)
          .maybeSingle();
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa
          .from('login_status')
          .select()
          .eq('worker_id', workerId)
          .eq('date', yyyyMmDd)
          .maybeSingle();
    }
  }

  /// All currently logged-in workers
  Future<List<Map<String, dynamic>>> currentlyLoggedIn() async {
    try {
      return await supa.from('login_status').select().eq('is_logged_in', true);
    } catch (e) {
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      return await supa.from('login_status').select().eq('is_logged_in', true);
    }
  }
}
```

### UsersService Integration
```dart
import '../utils/map_case.dart';
import 'supabase_client.dart';
import 'schema_refresher.dart';

class UsersService {
  final SchemaRefresher _schemaRefresher = SchemaRefresher();

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
```

## Provider Integration

### LoginStatusProvider Integration
```dart
import 'package:intl/intl.dart';
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/login_service.dart';
import '../services/users_service.dart';
import '../services/location_service.dart';
import '../services/schema_refresher.dart';
import '../utils/logger.dart';
import 'base_provider.dart';

class LoginStatusProvider extends BaseProvider {
  final LoginService _loginService = LoginService();
  final UsersService _usersService = UsersService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  List<LoginStatus> _loginStatuses = [];
  LoginStatus? _todayLoginStatus;
  bool _isLoggedIn = false;

  List<LoginStatus> get loginStatuses => _loginStatuses;
  LoginStatus? get todayLoginStatus => _todayLoginStatus;
  bool get isLoggedIn => _isLoggedIn;

  // Load all login statuses with schema error handling
  Future<void> loadLoginStatuses() async {
    setState(ViewState.busy);
    try {
      final statusesData = await _loginService.statuses();
      _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses: $e', e);
      
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final statusesData = await _loginService.statuses();
        _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
      }
    }
  }

  // Check today's login status for a worker with schema error handling
  Future<void> checkTodayLoginStatus(int workerId) async {
    setState(ViewState.busy);
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final statusData = await _loginService.todayForWorker(workerId, today);
      _todayLoginStatus = statusData != null ? LoginStatus.fromMap(statusData) : null;
      _isLoggedIn = _todayLoginStatus?.isLoggedIn ?? false;
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error checking today login status: $e', e);
      
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final statusData = await _loginService.todayForWorker(workerId, today);
        _todayLoginStatus = statusData != null ? LoginStatus.fromMap(statusData) : null;
        _isLoggedIn = _todayLoginStatus?.isLoggedIn ?? false;
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
      }
    }
  }
}
```

## Best Practices

### 1. Use Appropriate Error Detection Methods
- Use `tryFixSchemaError()` for basic schema cache errors
- Use `tryFixExtendedSchemaError()` for comprehensive error detection

### 2. Implement Proper Retry Logic
- Add a small delay (1-2 seconds) after schema refresh before retrying
- Limit retry attempts to prevent infinite loops
- Log retry attempts for debugging

### 3. Handle Different Operation Types
- For read operations (select), simple retry is usually sufficient
- For write operations (insert, update, delete), ensure idempotency or handle duplicates

### 4. Error Logging
- Log original errors for debugging
- Log schema refresh attempts
- Log retry attempts and results

## Advanced Integration with Retry Wrapper

```dart
import 'schema_refresher.dart';
import 'dart:async';

class SupabaseOperationWrapper {
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  /// Wrapper for Supabase operations with automatic schema error handling
  Future<T> executeWithSchemaProtection<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      // Check if it's a schema error
      final message = e.toString().toLowerCase();
      if (message.contains("schema cache") || 
          message.contains("pgrst204") || 
          message.contains("column") && message.contains("in the schema cache")) {
        
        Logger.info("Schema error detected, attempting to fix...");
        
        // Try to fix the schema error
        await _schemaRefresher.tryFixExtendedSchemaError(e);
        
        // Wait a moment for the schema to refresh
        await Future.delayed(const Duration(seconds: 2));
        
        // Retry the operation
        Logger.info("Retrying operation after schema refresh...");
        return await operation();
      }
      
      // If it's not a schema error, rethrow
      rethrow;
    }
  }
}

// Usage example:
final operationWrapper = SupabaseOperationWrapper();

// Wrap any Supabase operation
final result = await operationWrapper.executeWithSchemaProtection(() async {
  return await supa.from('login_status').select().eq('worker_id', workerId);
});
```

## Conclusion

The SchemaRefresher integration makes your Flutter Worker Management app self-healing by automatically detecting and fixing Supabase schema cache errors. By implementing these patterns in your service classes and providers, you ensure that your app can recover from schema cache issues without manual intervention.