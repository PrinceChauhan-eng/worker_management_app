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
import '../models/login_status.dart';

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
      print('=== INITIALIZING DATABASE ===');
      print('Current state - Initialized: $_initialized, DB exists: ${_db != null}');
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
      _db = await openDatabase(
        path, 
        version: 3, // Updated version for all schema changes
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
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
    print('=== DATABASE CREATED (NEW DATABASE) ===');
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

      // Create login_status table
      await db.execute('''
        CREATE TABLE login_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          date TEXT,
          loginTime TEXT,
          logoutTime TEXT,
          loginLatitude REAL,
          loginLongitude REAL,
          loginAddress TEXT,
          logoutLatitude REAL,
          logoutLongitude REAL,
          logoutAddress TEXT,
          isLoggedIn INTEGER DEFAULT 0,
          loginDistance REAL,
          logoutDistance REAL
        )
      ''');
      print('Login status table created');

      // Create login history table
      await db.execute('''
        CREATE TABLE login_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          user_name TEXT,
          user_role TEXT,
          login_time INTEGER,
          ip_address TEXT,
          user_agent TEXT,
          success INTEGER,
          failure_reason TEXT
        )
      ''');
      print('Login history table created');

      // Insert default admin user with the correct phone number from project memory
      print('Inserting default admin user...');
      await db.insert('users', {
        'name': 'Admin',
        'phone': '8104246218',  // Updated to match project memory
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

  // Database upgrade method
  void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    try {
      if (oldVersion < 2) {
        // Add new columns to users table for profile features
        try {
          await db.execute('ALTER TABLE users ADD COLUMN profilePhoto TEXT');
          print('Added profilePhoto column to users table');
        } catch (e) {
          print('profilePhoto column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN idProof TEXT');
          print('Added idProof column to users table');
        } catch (e) {
          print('idProof column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
          print('Added address column to users table');
        } catch (e) {
          print('address column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
          print('Added email column to users table');
        } catch (e) {
          print('email column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN emailVerified INTEGER DEFAULT 0');
          print('Added emailVerified column to users table');
        } catch (e) {
          print('emailVerified column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN emailVerificationCode TEXT');
          print('Added emailVerificationCode column to users table');
        } catch (e) {
          print('emailVerificationCode column may already exist: $e');
        }
        
        // Add location fields to users table
        try {
          await db.execute('ALTER TABLE users ADD COLUMN workLocationLatitude REAL');
          print('Added workLocationLatitude column to users table');
        } catch (e) {
          print('workLocationLatitude column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN workLocationLongitude REAL');
          print('Added workLocationLongitude column to users table');
        } catch (e) {
          print('workLocationLongitude column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN workLocationAddress TEXT');
          print('Added workLocationAddress column to users table');
        } catch (e) {
          print('workLocationAddress column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN locationRadius REAL DEFAULT 100.0');
          print('Added locationRadius column to users table');
        } catch (e) {
          print('locationRadius column may already exist: $e');
        }
      }
      
      if (oldVersion < 3) {
        // Add new fields to advance table
        try {
          await db.execute('ALTER TABLE advance ADD COLUMN purpose TEXT');
          print('Added purpose column to advance table');
        } catch (e) {
          print('purpose column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE advance ADD COLUMN note TEXT');
          print('Added note column to advance table');
        } catch (e) {
          print('note column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE advance ADD COLUMN status TEXT DEFAULT "pending"');
          print('Added status column to advance table');
        } catch (e) {
          print('status column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE advance ADD COLUMN deductedFromSalaryId INTEGER');
          print('Added deductedFromSalaryId column to advance table');
        } catch (e) {
          print('deductedFromSalaryId column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE advance ADD COLUMN approvedBy INTEGER');
          print('Added approvedBy column to advance table');
        } catch (e) {
          print('approvedBy column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE advance ADD COLUMN approvedDate TEXT');
          print('Added approvedDate column to advance table');
        } catch (e) {
          print('approvedDate column may already exist: $e');
        }
        
        // Add new fields to salary table
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN year TEXT');
          print('Added year column to salary table');
        } catch (e) {
          print('year column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN presentDays INTEGER');
          print('Added presentDays column to salary table');
        } catch (e) {
          print('presentDays column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN absentDays INTEGER');
          print('Added absentDays column to salary table');
        } catch (e) {
          print('absentDays column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN grossSalary REAL');
          print('Added grossSalary column to salary table');
        } catch (e) {
          print('grossSalary column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN totalAdvance REAL');
          print('Added totalAdvance column to salary table');
        } catch (e) {
          print('totalAdvance column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN netSalary REAL');
          print('Added netSalary column to salary table');
        } catch (e) {
          print('netSalary column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN paidDate TEXT');
          print('Added paidDate column to salary table');
        } catch (e) {
          print('paidDate column may already exist: $e');
        }
      }
      
      print('Database upgrade completed successfully');
    } catch (e, stackTrace) {
      print('Error upgrading database: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Database open callback to verify and add missing columns
  void _onOpen(Database db) async {
    print('Database opened successfully');
    
    try {
      // Verify tables exist
      var tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      print('Existing tables: ${tables.map((t) => t['name']).toList()}');
      
      // Ensure default admin user exists
      try {
        var adminUsers = await db.query('users', where: 'phone = ?', whereArgs: ['8104246218']);
        if (adminUsers.isEmpty) {
          print('No default admin user found, creating one...');
          await db.insert('users', {
            'name': 'Admin',
            'phone': '8104246218',
            'password': 'admin123',
            'role': 'admin',
            'wage': 0.0,
            'joinDate': DateTime.now().toString(),
          });
          print('Default admin user created successfully');
        } else {
          print('Default admin user already exists');
        }
      } catch (e) {
        print('Error checking/creating default admin user: $e');
      }
      
      // Verify and add missing columns to users table if needed
      try {
        var userColumns = await db.rawQuery("PRAGMA table_info(users)");
        var columnNames = userColumns.map((c) => c['name'] as String).toList();
        print('Users table columns: $columnNames');
        
        // Check and add missing columns
        if (!columnNames.contains('profilePhoto')) {
          await db.execute('ALTER TABLE users ADD COLUMN profilePhoto TEXT');
          print('Added profilePhoto column to users table');
        }
        if (!columnNames.contains('idProof')) {
          await db.execute('ALTER TABLE users ADD COLUMN idProof TEXT');
          print('Added idProof column to users table');
        }
        if (!columnNames.contains('address')) {
          await db.execute('ALTER TABLE users ADD COLUMN address TEXT');
          print('Added address column to users table');
        }
        if (!columnNames.contains('email')) {
          await db.execute('ALTER TABLE users ADD COLUMN email TEXT');
          print('Added email column to users table');
        }
        if (!columnNames.contains('emailVerified')) {
          await db.execute('ALTER TABLE users ADD COLUMN emailVerified INTEGER DEFAULT 0');
          print('Added emailVerified column to users table');
        }
        if (!columnNames.contains('emailVerificationCode')) {
          await db.execute('ALTER TABLE users ADD COLUMN emailVerificationCode TEXT');
          print('Added emailVerificationCode column to users table');
        }
        if (!columnNames.contains('workLocationLatitude')) {
          await db.execute('ALTER TABLE users ADD COLUMN workLocationLatitude REAL');
          print('Added workLocationLatitude column to users table');
        }
        if (!columnNames.contains('workLocationLongitude')) {
          await db.execute('ALTER TABLE users ADD COLUMN workLocationLongitude REAL');
          print('Added workLocationLongitude column to users table');
        }
        if (!columnNames.contains('workLocationAddress')) {
          await db.execute('ALTER TABLE users ADD COLUMN workLocationAddress TEXT');
          print('Added workLocationAddress column to users table');
        }
        if (!columnNames.contains('locationRadius')) {
          await db.execute('ALTER TABLE users ADD COLUMN locationRadius REAL DEFAULT 100.0');
          print('Added locationRadius column to users table');
        }
      } catch (e) {
        print('Error checking/adding columns to users table: $e');
      }
      
      // Verify and add missing columns to advance table if needed
      try {
        var advanceColumns = await db.rawQuery("PRAGMA table_info(advance)");
        var columnNames = advanceColumns.map((c) => c['name'] as String).toList();
        print('Advance table columns: $columnNames');
        
        // Check and add missing columns
        if (!columnNames.contains('purpose')) {
          await db.execute('ALTER TABLE advance ADD COLUMN purpose TEXT');
          print('Added purpose column to advance table');
        }
        if (!columnNames.contains('note')) {
          await db.execute('ALTER TABLE advance ADD COLUMN note TEXT');
          print('Added note column to advance table');
        }
        if (!columnNames.contains('status')) {
          await db.execute('ALTER TABLE advance ADD COLUMN status TEXT DEFAULT "pending"');
          print('Added status column to advance table');
        }
        if (!columnNames.contains('deductedFromSalaryId')) {
          await db.execute('ALTER TABLE advance ADD COLUMN deductedFromSalaryId INTEGER');
          print('Added deductedFromSalaryId column to advance table');
        }
        if (!columnNames.contains('approvedBy')) {
          await db.execute('ALTER TABLE advance ADD COLUMN approvedBy INTEGER');
          print('Added approvedBy column to advance table');
        }
        if (!columnNames.contains('approvedDate')) {
          await db.execute('ALTER TABLE advance ADD COLUMN approvedDate TEXT');
          print('Added approvedDate column to advance table');
        }
      } catch (e) {
        print('Error checking/adding columns to advance table: $e');
      }
      
      // Verify and add missing columns to salary table if needed
      try {
        var salaryColumns = await db.rawQuery("PRAGMA table_info(salary)");
        var columnNames = salaryColumns.map((c) => c['name'] as String).toList();
        print('Salary table columns: $columnNames');
        
        // Check and add missing columns
        if (!columnNames.contains('year')) {
          await db.execute('ALTER TABLE salary ADD COLUMN year TEXT');
          print('Added year column to salary table');
        }
        if (!columnNames.contains('presentDays')) {
          await db.execute('ALTER TABLE salary ADD COLUMN presentDays INTEGER');
          print('Added presentDays column to salary table');
        }
        if (!columnNames.contains('absentDays')) {
          await db.execute('ALTER TABLE salary ADD COLUMN absentDays INTEGER');
          print('Added absentDays column to salary table');
        }
        if (!columnNames.contains('grossSalary')) {
          await db.execute('ALTER TABLE salary ADD COLUMN grossSalary REAL');
          print('Added grossSalary column to salary table');
        }
        if (!columnNames.contains('totalAdvance')) {
          await db.execute('ALTER TABLE salary ADD COLUMN totalAdvance REAL');
          print('Added totalAdvance column to salary table');
        }
        if (!columnNames.contains('netSalary')) {
          await db.execute('ALTER TABLE salary ADD COLUMN netSalary REAL');
          print('Added netSalary column to salary table');
        }
        if (!columnNames.contains('paidDate')) {
          await db.execute('ALTER TABLE salary ADD COLUMN paidDate TEXT');
          print('Added paidDate column to salary table');
        }
      } catch (e) {
        print('Error checking/adding columns to salary table: $e');
      }
      
      // Debug: Check what users exist in the database
      try {
        var allUsers = await db.query('users');
        print('All users in database after initialization: ${allUsers.length}');
        for (var user in allUsers) {
          print('User in DB: ID=${user['id']}, Name=${user['name']}, Phone=${user['phone']}, Role=${user['role']}');
        }
      } catch (e) {
        print('Error checking users in database: $e');
      }
    } catch (e) {
      print('Error in onOpen callback: $e');
    }
  }

  // User methods
  Future<int> insertUser(User user) async {
    try {
      print('Inserting user: ${user.name}');
      var client = await db;
      int result = await client.insert('users', user.toMap());
      print('User inserted successfully with ID: $result');
      
      // Verify the insert
      var insertedUser = await client.query('users', where: 'id = ?', whereArgs: [result]);
      print('Verification - User data in DB: $insertedUser');
      
      // Verify all users in database
      var allUsers = await client.query('users');
      print('All users after insert: ${allUsers.length}');
      for (var u in allUsers) {
        print('User in DB: ID=${u['id']}, Name=${u['name']}, Phone=${u['phone']}, Role=${u['role']}');
      }
      
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

  // LoginStatus methods
  Future<int> insertLoginStatus(LoginStatus loginStatus) async {
    try {
      print('Inserting login status for worker ID: ${loginStatus.workerId}');
      var client = await db;
      return await client.insert('login_status', loginStatus.toMap());
    } catch (e, stackTrace) {
      print('Error inserting login status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<LoginStatus>> getLoginStatuses() async {
    try {
      print('Getting all login statuses...');
      var client = await db;
      var results = await client.query('login_status');
      print('Found ${results.length} login statuses');
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting login statuses: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<LoginStatus>> getLoginStatusesByWorkerId(int workerId) async {
    try {
      print('Getting login statuses for worker ID: $workerId');
      var client = await db;
      var results = await client.query('login_status', where: 'workerId = ?', whereArgs: [workerId]);
      print('Found ${results.length} login statuses for worker ID: $workerId');
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting login statuses by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<LoginStatus?> getTodayLoginStatus(int workerId, String date) async {
    try {
      print('Getting today login status for worker ID: $workerId, date: $date');
      var client = await db;
      var results = await client.query(
        'login_status',
        where: 'workerId = ? AND date = ?',
        whereArgs: [workerId, date],
      );
      if (results.isNotEmpty) {
        print('Login status found for worker ID $workerId and date $date');
        return LoginStatus.fromMap(results.first);
      }
      print('No login status found for worker ID: $workerId and date: $date');
      return null;
    } catch (e, stackTrace) {
      print('Error getting today login status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> updateLoginStatus(LoginStatus loginStatus) async {
    try {
      print('Updating login status ID: ${loginStatus.id}');
      var client = await db;
      return await client.update(
        'login_status',
        loginStatus.toMap(),
        where: 'id = ?',
        whereArgs: [loginStatus.id],
      );
    } catch (e, stackTrace) {
      print('Error updating login status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    try {
      print('Getting currently logged in workers...');
      var client = await db;
      var results = await client.query('login_status', where: 'isLoggedIn = 1');
      print('Found ${results.length} currently logged in workers');
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting currently logged in workers: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Login history methods
  Future<int> insertLoginHistory(Map<String, dynamic> loginHistory) async {
    try {
      print('Inserting login history record');
      var client = await db;
      return await client.insert('login_history', loginHistory);
    } catch (e, stackTrace) {
      print('Error inserting login history: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
