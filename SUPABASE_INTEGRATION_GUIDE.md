# Supabase Integration Guide

## Overview

This guide explains how to use the new Supabase integration in the Worker Management App. The integration provides hybrid cloud-local data storage with automatic synchronization between Supabase and the local SQLite database.

## Services Available

The following services have been implemented to work with both Supabase and local SQLite:

1. **UsersService** - For user management
2. **AttendanceService** - For attendance tracking
3. **SalaryService** - For salary processing

## Accessing Supabase Client

To access the Supabase client directly in your code, use:

```dart
final supabase = Supabase.instance.client;
```

This is the standard pattern for accessing the Supabase client throughout the application.

## Usage Examples

### 1. Inserting Data

```dart
// Insert a new user
final usersService = UsersService();
final userData = {
  'name': 'John Doe',
  'phone': '1234567890',
  'role': 'worker',
  'wage': 500.0,
};
await usersService.insert(userData);

// Or using the typed method
final user = User(
  name: 'John Doe',
  phone: '1234567890',
  role: 'worker',
  wage: 500.0,
);
await usersService.insertUser(user);

// Insert attendance record
final attendanceService = AttendanceService();
final attendanceData = {
  'workerId': 1,
  'date': '2023-12-01',
  'inTime': '09:00:00',
  'outTime': '17:00:00',
  'present': 1,
};
await attendanceService.insert(attendanceData);

// Insert salary record
final salaryService = SalaryService();
final salaryData = {
  'workerId': 1,
  'month': '2023-12',
  'year': '2023',
  'totalDays': 31,
  'presentDays': 25,
  'absentDays': 6,
  'grossSalary': 12500.0,
  'totalAdvance': 2000.0,
  'netSalary': 10500.0,
  'paid': 1,
  'paidDate': '2023-12-01',
};
await salaryService.insert(salaryData);
```

### 2. Retrieving Data

```dart
// Get all users
final usersService = UsersService();
final users = await usersService.getAll();

// Get user by ID
final user = await usersService.getById(1);

// Get all attendance records
final attendanceService = AttendanceService();
final attendanceRecords = await attendanceService.getAll();

// Get salary by ID
final salaryService = SalaryService();
final salary = await salaryService.getById(1);
```

### 3. Updating Data

```dart
// Update a user
final usersService = UsersService();
final updatedUserData = {
  'name': 'John Smith',
  'phone': '1234567890',
  'role': 'worker',
  'wage': 550.0,
};
await usersService.update(1, updatedUserData);

// Update attendance
final attendanceService = AttendanceService();
final updatedAttendanceData = {
  'outTime': '18:00:00',
  'present': 1,
};
await attendanceService.update(1, updatedAttendanceData);
```

### 4. Deleting Data

```dart
// Delete a user
final usersService = UsersService();
await usersService.delete(1);

// Delete attendance record
final attendanceService = AttendanceService();
await attendanceService.delete(1);

// Delete salary record
final salaryService = SalaryService();
await salaryService.delete(1);
```

## Direct Supabase Client Usage

You can also use the Supabase client directly for more complex operations:

```dart
final supabase = Supabase.instance.client;

// Query with filters
final response = await supabase
    .from('users')
    .select()
    .eq('role', 'worker');

// Real-time subscriptions
final channel = supabase
    .channel('user_changes')
    .on(
      RealtimeListenTypes.postgresChanges,
      ChannelFilter(
        event: 'INSERT',
        schema: 'public',
        table: 'users',
      ),
      (payload, [ref]) {
        print('New user added: ${payload.new}');
      },
    )
    .subscribe();

// Authentication
final authResponse = await supabase.auth.signInWithPassword(
  email: 'user@example.com',
  password: 'password',
);
```

## Error Handling and Fallbacks

All services implement automatic fallback mechanisms:

1. **Primary**: Try Supabase first
2. **Fallback**: Use local SQLite database if Supabase fails
3. **Synchronization**: Data is stored in both locations when possible

This ensures the app works even when there's no internet connection.

## Best Practices

1. **Always use the service classes** for data operations instead of direct database access
2. **Handle exceptions** appropriately in your UI
3. **Check connectivity** before operations if needed
4. **Use typed methods** (like `insertUser`) when working with model objects
5. **Access Supabase client** using `Supabase.instance.client` pattern

## Example Implementation in a Screen

```dart
class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _usersService = UsersService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Future<void> _addUser() async {
    try {
      final user = User(
        name: _nameController.text,
        phone: _phoneController.text,
        role: 'worker',
        wage: 500.0,
      );
      
      await _usersService.insertUser(user);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User added successfully')),
      );
      
      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding user: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add User')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addUser,
              child: Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Configuration

The Supabase integration is already configured in `main.dart`:

```dart
await Supabase.initialize(
  url: 'https://qhjkngudpxrzldacxlpx.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoamtuZ3VkcHhyemxkYWN4bHB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NTk2NjAsImV4cCI6MjA3ODMzNTY2MH0.GlY_-LZSR7nxx1wllMGnJuDu4oxw629LMBm_2XaOufg',
);
```

## Security Notes

- The anonKey provided allows read and write access to the database
- For production applications, implement proper authentication and row-level security in Supabase
- Sensitive data should be encrypted before storage