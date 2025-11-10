# Supabase Migration Guide

## Overview

This guide explains how to migrate from the existing DatabaseHelper to the new Supabase services. The new services provide better cloud integration, real-time capabilities, and authentication features.

## New Service Files

The following service files have been created:

1. `lib/services/supabase_client.dart` - Supabase client initialization
2. `lib/services/auth_service.dart` - Authentication services
3. `lib/services/users_service.dart` - User management
4. `lib/services/attendance_service.dart` - Attendance tracking
5. `lib/services/advance_service.dart` - Advance requests
6. `lib/services/salary_service.dart` - Salary processing
7. `lib/services/login_service.dart` - Login status management
8. `lib/services/notifications_service.dart` - Notification handling
9. `lib/utils/map_case.dart` - Utility for converting camelCase to snake_case

## Migration Steps

### 1. Update Provider Files

Replace DatabaseHelper usage in provider files with the new Supabase services.

**Before (DatabaseHelper):**
```dart
import '../services/database_helper.dart';

class UserProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Future<void> loadWorkers() async {
    _workers = await _dbHelper.getUsers();
  }
}
```

**After (Supabase Services):**
```dart
import '../services/users_service.dart';

class UserProvider extends BaseProvider {
  final UsersService _usersService = UsersService();
  
  Future<void> loadWorkers() async {
    final usersData = await _usersService.getUsers();
    _workers = usersData.map((data) => User.fromMap(data)).toList();
  }
}
```

### 2. Update Data Operations

Replace direct database calls with service calls.

**Before (DatabaseHelper):**
```dart
await _dbHelper.insertUser(user);
```

**After (Supabase Services):**
```dart
await _usersService.insertUser(user.toMap());
```

### 3. Update Authentication

Replace local authentication with Supabase Auth.

**Before (DatabaseHelper):**
```dart
_currentUser = await _dbHelper.getUserByPhoneAndPassword(phone, password);
```

**After (AuthService):**
```dart
import '../services/auth_service.dart';

final _authService = AuthService();
final response = await _authService.signInWithEmail(email: email, password: password);
if (response.user != null) {
  // Load user data from users_service
  final usersService = UsersService();
  final userData = await usersService.getUserByPhone(phone);
  _currentUser = User.fromMap(userData!);
}
```

## Service Usage Examples

### UsersService
```dart
final usersService = UsersService();

// Insert user
final userId = await usersService.insertUser({
  'name': 'John Doe',
  'phone': '1234567890',
  'role': 'worker',
  'wage': 500.0,
});

// Get all users
final users = await usersService.getUsers();

// Get user by ID
final user = await usersService.getUser(1);

// Update user
await usersService.updateUser(1, {
  'name': 'John Smith',
  'wage': 550.0,
});

// Delete user
await usersService.deleteUser(1);
```

### AttendanceService
```dart
final attendanceService = AttendanceService();

// Insert attendance
final attendanceId = await attendanceService.insert({
  'worker_id': 1,
  'date': '2023-12-01',
  'in_time': '09:00:00',
  'out_time': '17:00:00',
  'present': true,
});

// Get attendance by worker
final attendanceRecords = await attendanceService.byWorker(1);

// Update attendance
await attendanceService.updateById(1, {
  'out_time': '18:00:00',
});
```

### AuthService
```dart
final authService = AuthService();

// Sign up
await authService.signUpWithEmail(email: 'user@example.com', password: 'password');

// Sign in
final response = await authService.signInWithEmail(email: 'user@example.com', password: 'password');

// Sign out
await authService.signOut();

// Get current user
final currentUser = authService.currentUser;
```

## Case Conversion

The new services automatically handle camelCase to snake_case conversion using the MapCase utility:

```dart
// Either format works:
await usersService.insertUser({
  'name': 'John Doe',        // snake_case
  'phoneNumber': '1234567890' // camelCase (automatically converted)
});

// Or:
await usersService.insertUser({
  'name': 'John Doe',        // snake_case
  'phone_number': '1234567890' // snake_case
});
```

## Benefits of Migration

1. **Cloud Integration**: Data is automatically synced to Supabase
2. **Real-time Updates**: Listen for database changes
3. **Authentication**: Built-in user authentication
4. **Scalability**: Cloud-based database can handle more users
5. **Offline Support**: Local database as fallback
6. **Security**: Row-level security policies in Supabase

## Important Notes

1. **Database Schema**: Ensure your Supabase tables match the expected schema with snake_case column names
2. **Authentication**: Configure Supabase Auth with proper redirect URLs
3. **Environment Variables**: Update your Supabase URL and anon key in main.dart
4. **Testing**: Test all functionality after migration to ensure compatibility

## Next Steps

1. Update provider files to use new services
2. Test authentication flow with Supabase Auth
3. Verify all data operations work correctly
4. Remove old DatabaseHelper references
5. Update documentation and README files