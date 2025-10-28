import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' if (dart.library.io) 'noop.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import '../models/advance.dart';
import '../models/salary.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;
  static bool _initialized = false;

  Future<Database> get db async {
    if (_db != null) return _db!;
    if (!_initialized) {
      print('Database not initialized, initializing now...');
      await initDB();
    }
    return _db!;
  }

  Future<Database> initDB() async {
    if (_initialized && _db != null) {
      print('Database already initialized');
      return _db!;
    }
    
    try {
      print('Initializing database...');
      String path;
      
      if (kIsWeb) {
        // For web, use a simple path and initialize sqflite
        print('Running on web, initializing sqflite for web');
        // Change default factory on the web
        databaseFactory = databaseFactoryFfiWeb;
        path = 'worker_management.db';
        print('Using path: $path');
      } else {
        // For mobile/desktop, use the documents directory
        var documentsDirectory = await getApplicationDocumentsDirectory();
        print('Documents directory: ${documentsDirectory.path}');
        path = join(documentsDirectory.path, 'worker_management.db');
        print('Database path: $path');
      }
      
      print('Opening database with factory: $databaseFactory');
      _db = await openDatabase(path, version: 1, onCreate: _onCreate);
      _initialized = true;
      print('Database opened successfully with version: ${await _db!.getVersion()}');
      return _db!;
    } catch (e, stackTrace) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _onCreate(Database db, int version) async {
    try {
      print('Creating database tables...');
      // Create users table
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          phone TEXT,
          password TEXT,
          role TEXT,
          wage REAL,
          joinDate TEXT
        )
      ''');
      print('Users table created');

      // Create attendance table
      await db.execute('''
        CREATE TABLE attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          date TEXT,
          inTime TEXT,
          outTime TEXT,
          present INTEGER
        )
      ''');
      print('Attendance table created');

      // Create advance table
      await db.execute('''
        CREATE TABLE advance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          amount REAL,
          date TEXT
        )
      ''');
      print('Advance table created');

      // Create salary table
      await db.execute('''
        CREATE TABLE salary (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          month TEXT,
          totalDays INTEGER,
          totalSalary REAL,
          paid INTEGER
        )
      ''');
      print('Salary table created');

      // Insert default admin user
      print('Inserting default admin user...');
      await db.insert('users', {
        'name': 'Admin',
        'phone': 'admin',
        'password': 'admin123',
        'role': 'admin',
        'wage': 0.0,
        'joinDate': DateTime.now().toString(),
      });
      print('Default admin user inserted successfully');
      
      print('Database created successfully with default admin user');
    } catch (e, stackTrace) {
      print('Error creating database tables: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // User methods
  Future<int> insertUser(User user) async {
    try {
      print('Inserting user: ${user.name}');
      var client = await db;
      int result = await client.insert('users', user.toMap());
      print('User inserted successfully with ID: $result');
      return result;
    } catch (e, stackTrace) {
      print('Error inserting user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<User>> getUsers() async {
    try {
      print('Getting all users...');
      var client = await db;
      var results = await client.query('users');
      print('Found ${results.length} users');
      return results.map((map) => User.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting users: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<User?> getUser(int id) async {
    try {
      print('Getting user by ID: $id');
      var client = await db;
      var results = await client.query('users', where: 'id = ?', whereArgs: [id]);
      if (results.isNotEmpty) {
        print('User found: ${User.fromMap(results.first).name}');
        return User.fromMap(results.first);
      }
      print('User not found');
      return null;
    } catch (e, stackTrace) {
      print('Error getting user by ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<User?> getUserByPhoneAndPassword(String phone, String password) async {
    try {
      print('Authenticating user with phone: $phone and password: $password');
      // Ensure database is initialized
      await initDB();
      var client = await db;
      print('Database client obtained successfully');
      var results = await client.query(
        'users',
        where: 'phone = ? AND password = ?',
        whereArgs: [phone, password],
      );
      print('Found ${results.length} matching users');
      if (results.isNotEmpty) {
        print('Raw user data from database: ${results.first}');
        User user = User.fromMap(results.first);
        print('User authenticated: ${user.name}, role: ${user.role}');
        return user;
      }
      print('User not found or invalid credentials');
      // Let's also check if there are any users in the database
      var allUsers = await client.query('users');
      print('Total users in database: ${allUsers.length}');
      for (var user in allUsers) {
        print('User in database: phone=${user['phone']}, password=${user['password']}, role=${user['role']}');
      }
      return null;
    } catch (e, stackTrace) {
      print('Error authenticating user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateUser(User user) async {
    try {
      print('Updating user: ${user.name}');
      var client = await db;
      return await client.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e, stackTrace) {
      print('Error updating user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteUser(int id) async {
    try {
      print('Deleting user with ID: $id');
      var client = await db;
      return await client.delete('users', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      print('Error deleting user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Attendance methods
  Future<int> insertAttendance(Attendance attendance) async {
    try {
      print('Inserting attendance for worker ID: ${attendance.workerId}');
      var client = await db;
      return await client.insert('attendance', attendance.toMap());
    } catch (e, stackTrace) {
      print('Error inserting attendance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Attendance>> getAttendances() async {
    try {
      print('Getting all attendances...');
      var client = await db;
      var results = await client.query('attendance');
      print('Found ${results.length} attendances');
      return results.map((map) => Attendance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting attendances: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Attendance>> getAttendancesByWorkerId(int workerId) async {
    try {
      print('Getting attendances for worker ID: $workerId');
      var client = await db;
      var results =
          await client.query('attendance', where: 'workerId = ?', whereArgs: [workerId]);
      print('Found ${results.length} attendances for worker ID: $workerId');
      return results.map((map) => Attendance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting attendances by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateAttendance(Attendance attendance) async {
    try {
      print('Updating attendance ID: ${attendance.id}');
      var client = await db;
      return await client.update(
        'attendance',
        attendance.toMap(),
        where: 'id = ?',
        whereArgs: [attendance.id],
      );
    } catch (e, stackTrace) {
      print('Error updating attendance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteAttendance(int id) async {
    try {
      print('Deleting attendance ID: $id');
      var client = await db;
      return await client.delete('attendance', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      print('Error deleting attendance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Advance methods
  Future<int> insertAdvance(Advance advance) async {
    try {
      print('Inserting advance for worker ID: ${advance.workerId}');
      var client = await db;
      return await client.insert('advance', advance.toMap());
    } catch (e, stackTrace) {
      print('Error inserting advance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Advance>> getAdvances() async {
    try {
      print('Getting all advances...');
      var client = await db;
      var results = await client.query('advance');
      print('Found ${results.length} advances');
      return results.map((map) => Advance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting advances: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Advance>> getAdvancesByWorkerId(int workerId) async {
    try {
      print('Getting advances for worker ID: $workerId');
      var client = await db;
      var results =
          await client.query('advance', where: 'workerId = ?', whereArgs: [workerId]);
      print('Found ${results.length} advances for worker ID: $workerId');
      return results.map((map) => Advance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting advances by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<double> getTotalAdvanceByWorkerId(int workerId) async {
    try {
      print('Getting total advance for worker ID: $workerId');
      var client = await db;
      var results = await client.rawQuery(
        'SELECT SUM(amount) as total FROM advance WHERE workerId = ?',
        [workerId],
      );
      if (results.isNotEmpty && results.first['total'] != null) {
        double total = results.first['total'] as double;
        print('Total advance for worker ID $workerId: $total');
        return total;
      }
      print('No advances found for worker ID: $workerId');
      return 0.0;
    } catch (e, stackTrace) {
      print('Error getting total advance by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateAdvance(Advance advance) async {
    try {
      print('Updating advance ID: ${advance.id}');
      var client = await db;
      return await client.update(
        'advance',
        advance.toMap(),
        where: 'id = ?',
        whereArgs: [advance.id],
      );
    } catch (e, stackTrace) {
      print('Error updating advance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteAdvance(int id) async {
    try {
      print('Deleting advance ID: $id');
      var client = await db;
      return await client.delete('advance', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      print('Error deleting advance: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Salary methods
  Future<int> insertSalary(Salary salary) async {
    try {
      print('Inserting salary for worker ID: ${salary.workerId}');
      var client = await db;
      return await client.insert('salary', salary.toMap());
    } catch (e, stackTrace) {
      print('Error inserting salary: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Salary>> getSalaries() async {
    try {
      print('Getting all salaries...');
      var client = await db;
      var results = await client.query('salary');
      print('Found ${results.length} salaries');
      return results.map((map) => Salary.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting salaries: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Salary>> getSalariesByWorkerId(int workerId) async {
    try {
      print('Getting salaries for worker ID: $workerId');
      var client = await db;
      var results =
          await client.query('salary', where: 'workerId = ?', whereArgs: [workerId]);
      print('Found ${results.length} salaries for worker ID: $workerId');
      return results.map((map) => Salary.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting salaries by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(int workerId, String month) async {
    try {
      print('Getting salary for worker ID: $workerId and month: $month');
      var client = await db;
      var results = await client.query(
        'salary',
        where: 'workerId = ? AND month = ?',
        whereArgs: [workerId, month],
      );
      if (results.isNotEmpty) {
        Salary salary = Salary.fromMap(results.first);
        print('Salary found for worker ID $workerId and month $month: ${salary.totalSalary}');
        return salary;
      }
      print('No salary found for worker ID: $workerId and month: $month');
      return null;
    } catch (e, stackTrace) {
      print('Error getting salary by worker ID and month: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateSalary(Salary salary) async {
    try {
      print('Updating salary ID: ${salary.id}');
      var client = await db;
      return await client.update(
        'salary',
        salary.toMap(),
        where: 'id = ?',
        whereArgs: [salary.id],
      );
    } catch (e, stackTrace) {
      print('Error updating salary: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteSalary(int id) async {
    try {
      print('Deleting salary ID: $id');
      var client = await db;
      return await client.delete('salary', where: 'id = ?', whereArgs: [id]);
    } catch (e, stackTrace) {
      print('Error deleting salary: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}