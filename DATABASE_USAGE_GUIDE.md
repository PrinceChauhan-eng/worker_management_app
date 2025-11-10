# Database Usage Guide

## Safe Database Access Pattern

To use the database safely throughout the application, always use the singleton instance pattern:

```dart
// Get the database instance
final db = await DatabaseHelper.instance.database;

// Use the database
// Example: Query data
final results = await db.query('users');

// Example: Insert data
await db.insert('users', {'name': 'John Doe', 'role': 'worker'});

// Example: Update data
await db.update('users', {'name': 'Jane Doe'}, where: 'id = ?', whereArgs: [1]);

// Example: Delete data
await db.delete('users', where: 'id = ?', whereArgs: [1]);
```

## Key Benefits

1. **Singleton Pattern**: Ensures only one instance of DatabaseHelper exists
2. **Safe Initialization**: Database is properly initialized before use
3. **Error Recovery**: Automatic recovery from database corruption
4. **Cross-Platform**: Works on both web and desktop platforms

## Usage Examples

### In Providers
```dart
class UserProvider {
  final _dbHelper = DatabaseHelper.instance;
  
  Future<List<User>> getUsers() async {
    final db = await _dbHelper.database;
    final results = await db.query('users');
    return results.map((map) => User.fromMap(map)).toList();
  }
}
```

### In Screens
```dart
class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  Future<void> addUser(String name) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('users', {'name': name, 'role': 'worker'});
      // Refresh UI
      setState(() {});
    } catch (e) {
      // Handle error
      print('Error adding user: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // UI implementation
  }
}
```

## Error Handling

The database helper includes automatic error recovery:

```dart
try {
  final db = await DatabaseHelper.instance.database;
  // Database operations
} catch (e) {
  // Handle database errors
  print('Database error: $e');
}
```

If the database file becomes corrupted, the system will automatically:
1. Detect the corruption
2. Delete the corrupted database file
3. Create a new, clean database
4. Continue operation with the new database

## Best Practices

1. **Always use `DatabaseHelper.instance`** instead of `DatabaseHelper()`
2. **Await the database property** before performing operations
3. **Handle exceptions** appropriately
4. **Don't store the database reference** for long periods
5. **Use the database reference immediately** after obtaining it

## Database Schema Information

The application uses the following tables:
- `users`: User information (workers and admins)
- `attendance`: Worker attendance records
- `advance`: Advance payment requests
- `salary`: Salary records
- `login_status`: Login/logout tracking
- `login_history`: Login attempt history
- `notifications`: User notifications

All database operations are handled through the DatabaseHelper class methods.