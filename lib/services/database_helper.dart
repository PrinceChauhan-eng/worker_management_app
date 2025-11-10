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
import '../models/notification.dart';
import '../utils/password_utils.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  // Increment database version to 6 to add pdfUrl column to salary table
  final int _version = 6;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // Public method to ensure database is initialized
  Future<void> initDB() async {
    await db;
  }

  Future<Database> _initDB() async {
    if (_db != null) {
      print('Database already initialized');
      return _db!;
    }

    try {
      print('=== INITIALIZING DATABASE ===');
      String path;

      if (kIsWeb) {
        // For web, use a simple path and initialize sqflite
        print('Running on web, initializing sqflite for web');
        // Change default factory on the web
        databaseFactory = databaseFactoryFfiWeb; // Enable web support
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
        version: _version, // Updated version for all schema changes
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
      print(
        'Database opened successfully with version: ${await _db!.getVersion()}',
      );
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
          joinDate TEXT,
          workLocationLatitude REAL,
          workLocationLongitude REAL,
          workLocationAddress TEXT,
          locationRadius REAL DEFAULT 100.0,
          profilePhoto TEXT,
          idProof TEXT,
          address TEXT,
          email TEXT,
          emailVerified INTEGER DEFAULT 0,
          emailVerificationCode TEXT,
          designation TEXT
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

      // Create advance table with all required columns
      await db.execute('''
        CREATE TABLE advance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          amount REAL,
          date TEXT,
          purpose TEXT,
          note TEXT,
          status TEXT DEFAULT 'pending',
          deductedFromSalaryId INTEGER,
          approvedBy INTEGER,
          approvedDate TEXT
        )
      ''');
      print('Advance table created');

      // Create salary table with all required columns
      await db.execute('''
        CREATE TABLE salary (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          month TEXT,
          year TEXT,
          totalDays INTEGER,
          presentDays INTEGER,
          absentDays INTEGER,
          grossSalary REAL,
          totalAdvance REAL,
          netSalary REAL,
          totalSalary REAL,
          paid INTEGER,
          paidDate TEXT,
          pdfUrl TEXT
        )
      ''');
      print('Salary table created');

      // Add unique index to prevent duplicate salary records for the same worker and month
      await db.execute('''
        CREATE UNIQUE INDEX idx_worker_month ON salary(workerId, month)
      ''');
      print('Unique index created on salary table');

      // Create login_status table
      await db.execute('''
        CREATE TABLE login_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workerId INTEGER,
          date TEXT,
          loginTime TEXT,
          logoutTime TEXT,
          isLoggedIn INTEGER DEFAULT 0
        )
      ''');
      print('Login status table created');

      // Add unique index to prevent duplicate login status records for the same worker on the same date
      await db.execute('''
        CREATE UNIQUE INDEX idx_worker_date ON login_status(workerId, date)
      ''');
      print('Unique index created on login_status table');

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

      // Create notifications table
      await db.execute('''
        CREATE TABLE notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          message TEXT,
          type TEXT,
          userId INTEGER,
          userRole TEXT,
          isRead INTEGER DEFAULT 0,
          createdAt TEXT,
          relatedId TEXT
        )
      ''');
      print('Notifications table created');

      // Insert default admin user with the correct phone number from project memory
      print('Inserting default admin user...');
      await db.insert('users', {
        'name': 'Admin',
        'phone': '8104246218', // Updated to match project memory
        'password': PasswordUtils.hashPassword(
          'admin123',
        ), // Hash password before storing
        'role': 'admin',
        'wage': 0.0,
        'joinDate': DateTime.now().toString(),
        'designation': 'System Administrator', // Add designation for admin
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
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    try {
      print('Current database version: $oldVersion, target version: $newVersion');
      
      if (oldVersion < 2) {
        print('Upgrading to version 2: Adding profile features to users table');
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
          await db.execute(
            'ALTER TABLE users ADD COLUMN emailVerified INTEGER DEFAULT 0',
          );
          print('Added emailVerified column to users table');
        } catch (e) {
          print('emailVerified column may already exist: $e');
        }
        
        try {
          await db.execute(
            'ALTER TABLE users ADD COLUMN emailVerificationCode TEXT',
          );
          print('Added emailVerificationCode column to users table');
        } catch (e) {
          print('emailVerificationCode column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE users ADD COLUMN designation TEXT');
          print('Added designation column to users table');
        } catch (e) {
          print('designation column may already exist: $e');
        }
      }
      
      if (oldVersion < 3) {
        print('Upgrading to version 3: Adding advance request features');
        // Add columns to advance table
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
          await db.execute(
            'ALTER TABLE advance ADD COLUMN status TEXT DEFAULT "pending"',
          );
          print('Added status column to advance table');
        } catch (e) {
          print('status column may already exist: $e');
        }
        
        try {
          await db.execute(
            'ALTER TABLE advance ADD COLUMN deductedFromSalaryId INTEGER',
          );
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
      }
      
      if (oldVersion < 4) {
        print('Upgrading to version 4: Adding salary features');
        // Add columns to salary table
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
      
      // Add pdfUrl column to salary table (new in version 5)
      if (oldVersion < 5) {
        print('Upgrading to version 5: Adding PDF features');
        try {
          await db.execute('ALTER TABLE salary ADD COLUMN pdfUrl TEXT');
          print('Added pdfUrl column to salary table');
        } catch (e) {
          print('pdfUrl column may already exist: $e');
        }
      }
      
      // Add unique constraint to salary table (new in version 6)
      if (oldVersion < 6) {
        print('Upgrading to version 6: Adding unique constraints');
        try {
          // First, remove any existing duplicate salary records to avoid constraint violation
          print('Cleaning up duplicate salary records...');
          await db.rawQuery('''
            DELETE FROM salary 
            WHERE rowid NOT IN (
              SELECT MIN(rowid) 
              FROM salary 
              GROUP BY workerId, month
            )
          ''');
          print('Duplicate salary records removed');
          
          // Add unique index to prevent duplicate salary records for the same worker and month
          await db.execute('''
            CREATE UNIQUE INDEX IF NOT EXISTS idx_worker_month ON salary(workerId, month)
          ''');
          print('Unique index created on salary table');
        } catch (e) {
          print('Error adding unique constraint to salary table: $e');
        }
      }
      
      print('Database upgrade completed successfully');
    } catch (e, stackTrace) {
      print('Error upgrading database: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Database open callback to verify and add missing columns
  void _onOpen(Database db) async {
    print('Database opened, checking default admin user...');
    
    try {
      // Check if default admin user exists
      var adminUsers = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: ['8104246218'],
      );
      
      if (adminUsers.isEmpty) {
        print('No default admin user found, creating one...');
        await db.insert('users', {
          'name': 'Admin',
          'phone': '8104246218',
          'password': PasswordUtils.hashPassword(
            'admin123',
          ), // Hash password before storing
          'role': 'admin',
          'wage': 0.0,
          'joinDate': DateTime.now().toString(),
          'designation': 'System Administrator', // Add designation for admin
        });
        print('Default admin user created successfully');
      } else {
        print('Default admin user already exists');
      }
      
      // Debug: Check what users exist in the database
      try {
        var allUsers = await db.query('users');
        print('All users in database after initialization: ${allUsers.length}');
        for (var user in allUsers) {
          print(
            'User in DB: ID=${user['id']}, Name=${user['name']}, Phone=${user['phone']}, Role=${user['role']}',
          );
        }
      } catch (e) {
        print('Error checking users in database: $e');
      }
    } catch (e) {
      print('Error checking/creating default admin user: $e');
    }
  }

  Future<void> createTestWorkerIfNotExists() async {
    try {
      print('Checking if test worker exists...');
      var client = await db;
      
      // Check if our test worker exists
      var results = await client.query(
        'users',
        where: 'phone = ? AND role = ?',
        whereArgs: ['9876543210', 'worker'],
      );
      
      if (results.isEmpty) {
        print('Test worker not found, creating one...');
        
        // Create test worker
        final worker = User(
          name: 'John Doe',
          phone: '9876543210',
          password: PasswordUtils.hashPassword('worker123'), // Hash the password
          role: 'worker',
          wage: 500.0,
          joinDate: DateTime.now().toString(),
          designation: 'General Worker',
          address: '123 Main Street',
          email: 'johndoe@example.com',
        );
        
        await insertUser(worker);
        print('Test worker created successfully');
      } else {
        print('Test worker already exists');
        // Print the existing worker for debugging
        if (results.isNotEmpty) {
          var user = User.fromMap(results.first);
          print('Existing worker: ${user.name}, Wage: ${user.wage}');
        }
      }
    } catch (e, stackTrace) {
      print('Error creating test worker: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // User methods
  Future<int> insertUser(User user) async {
    try {
      print('Inserting user: ${user.name}');
      var client = await db;

      // Hash password before storing (if not already hashed)
      var userMap = user.toMap();
      if (!PasswordUtils.isHashed(userMap['password'] as String)) {
        userMap['password'] = PasswordUtils.hashPassword(
          userMap['password'] as String,
        );
      }

      int result = await client.insert('users', userMap);
      print('User inserted successfully with ID: $result');

      // Verify the insert (without password)
      var insertedUser = await client.query(
        'users',
        where: 'id = ?',
        whereArgs: [result],
      );
      print(
        'Verification - User data in DB: ID=${insertedUser.first['id']}, Name=${insertedUser.first['name']}, Phone=${insertedUser.first['phone']}, Role=${insertedUser.first['role']}',
      );

      // Verify all users in database (without passwords)
      var allUsers = await client.query('users');
      print('All users after insert: ${allUsers.length}');
      for (var u in allUsers) {
        print(
          'User in DB: ID=${u['id']}, Name=${u['name']}, Phone=${u['phone']}, Role=${u['role']}',
        );
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
      
      // Print all users for debugging
      for (var user in results) {
        print('User: ID=${user['id']}, Name=${user['name']}, Phone=${user['phone']}, Role=${user['role']}');
      }
      
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
      var results = await client.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
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
      print('Authenticating user with phone: $phone');
      // Ensure database is initialized
      await _initDB();
      var client = await db;
      print('Database client obtained successfully');

      // Get user by phone first
      var results = await client.query(
        'users',
        where: 'phone = ?',
        whereArgs: [phone],
      );

      if (results.isEmpty) {
        print('User not found with phone: $phone');
        return null;
      }

      var userData = results.first;
      var storedPassword = userData['password'] as String;

      // Check if stored password is hashed or plain text (for migration)
      bool passwordMatches;
      if (PasswordUtils.isHashed(storedPassword)) {
        // Compare hashed passwords
        passwordMatches = PasswordUtils.verifyPassword(
          password,
          storedPassword,
        );
      } else {
        // Legacy: plain text password (for existing databases)
        // Hash the input and compare, or do plain text comparison for migration
        // Then update the password to hashed version
        passwordMatches = password == storedPassword;
        if (passwordMatches) {
          // Migrate to hashed password
          print(
            'Migrating password to hashed format for user: ${userData['name']}',
          );
          await client.update(
            'users',
            {'password': PasswordUtils.hashPassword(password)},
            where: 'id = ?',
            whereArgs: [userData['id']],
          );
        }
      }

      if (passwordMatches) {
        User user = User.fromMap(userData);
        print('User authenticated: ${user.name}, role: ${user.role}');
        return user;
      }

      print('Invalid password for user: $phone');
      return null;
    } catch (e, stackTrace) {
      print('=== DATABASE AUTHENTICATION ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('====================================');
      
      // Re-throw the error so the calling function can handle it appropriately
      rethrow;
    }
  }

  Future<int> updateUser(User user) async {
    try {
      print('Updating user: ${user.name}');
      var client = await db;

      // Hash password before updating (if not already hashed)
      var userMap = user.toMap();
      if (userMap['password'] != null &&
          !PasswordUtils.isHashed(userMap['password'] as String)) {
        userMap['password'] = PasswordUtils.hashPassword(
          userMap['password'] as String,
        );
      }

      return await client.update(
        'users',
        userMap,
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
      var results = await client.query(
        'attendance',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );
      print('Found ${results.length} attendances for worker ID: $workerId');
      return results.map((map) => Attendance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting attendances by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Attendance>> getAttendancesByWorkerIdAndDate(
    int workerId,
    String date,
  ) async {
    try {
      print('Getting attendances for worker ID: $workerId and date: $date');
      var client = await db;
      var results = await client.query(
        'attendance',
        where: 'workerId = ? AND date = ?',
        whereArgs: [workerId, date],
      );
      print(
        'Found ${results.length} attendances for worker ID: $workerId and date: $date',
      );
      return results.map((map) => Attendance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting attendances by worker ID and date: $e');
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
      return await client.delete(
        'attendance',
        where: 'id = ?',
        whereArgs: [id],
      );
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
      print('Advance object: ${advance.toMap()}');
      var client = await db;
      return await client.insert('advance', advance.toMap());
    } catch (e, stackTrace) {
      print('Error inserting advance: $e');
      print('Stack trace: $stackTrace');
      
      // Log the specific error details
      if (e.toString().contains('no such column')) {
        print('This might be a database schema issue - missing columns in advance table');
      } else if (e.toString().contains('constraint')) {
        print('This is a database constraint error');
      }
      
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
      var results = await client.query(
        'advance',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );
      print('Found ${results.length} advances for worker ID: $workerId');
      return results.map((map) => Advance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting advances by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Advance>> getAdvancesByWorkerIdAndMonth(
    int workerId,
    String month,
  ) async {
    try {
      print('Getting advances for worker ID: $workerId and month: $month');
      var client = await db;
      var results = await client.query(
        'advance',
        where: 'workerId = ? AND date LIKE ?',
        whereArgs: [workerId, '$month%'],
      );
      print(
        'Found ${results.length} advances for worker ID: $workerId and month: $month',
      );
      return results.map((map) => Advance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting advances by worker ID and month: $e');
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

  // Reset all data method
  Future<void> resetAllData() async {
    try {
      print('Resetting all data...');
      var client = await db;
      
      // Delete all records from all tables
      await client.delete('users');
      await client.delete('attendance');
      await client.delete('advance');
      await client.delete('salary');
      await client.delete('login_status');
      await client.delete('login_history');
      await client.delete('notifications');
      
      // Insert default admin user
      await client.insert('users', {
        'name': 'Admin',
        'phone': '8104246218',
        'password': PasswordUtils.hashPassword(
          'admin123',
        ), // Hash password before storing
        'role': 'admin',
        'wage': 0.0,
        'joinDate': DateTime.now().toString(),
        'designation': 'System Administrator',
      });
      
      print('All data reset successfully');
    } catch (e, stackTrace) {
      print('Error resetting all data: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  // Force database upgrade method
  Future<void> forceUpgrade() async {
    try {
      print('Forcing database upgrade...');
      var client = await db;
      
      // Get current database version
      int currentVersion = await client.getVersion();
      print('Current database version: $currentVersion');
      
      // Force upgrade to latest version
      if (currentVersion < _version) {
        print('Upgrading database to version $_version');
        await _onUpgrade(client, currentVersion, _version);
        await client.setVersion(_version);
        print('Database upgraded to version $_version');
      } else {
        print('Database is already at the latest version');
      }
    } catch (e, stackTrace) {
      print('Error forcing database upgrade: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Salary methods
  Future<int> insertSalary(Salary salary) async {
    try {
      print('=== INSERTING SALARY ===');
      print('Salary object: ${salary.toMap()}');
      
      // Validate required fields
      if (salary.workerId <= 0) {
        throw Exception('Worker ID is required and must be positive, got: ${salary.workerId}');
      }
      
      if (salary.month.isEmpty) {
        throw Exception('Month is required and cannot be empty');
      }
      
      print('Worker ID: ${salary.workerId}');
      print('Month: ${salary.month}');
      print('Year: ${salary.year}');
      print('Total Days: ${salary.totalDays}');
      print('Present Days: ${salary.presentDays}');
      print('Absent Days: ${salary.absentDays}');
      print('Gross Salary: ${salary.grossSalary}');
      print('Total Advance: ${salary.totalAdvance}');
      print('Net Salary: ${salary.netSalary}');
      print('Paid: ${salary.paid}');
      print('Paid Date: ${salary.paidDate}');
      print('PDF URL: ${salary.pdfUrl}');
      
      var client = await db;
      print('Database client obtained successfully');
      
      final result = await client.insert('salary', salary.toMap());
      print('Salary inserted successfully with ID: $result');
      return result;
    } catch (e, stackTrace) {
      print('!!! ERROR INSERTING SALARY !!!');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      
      // Log the specific error details
      if (e.toString().contains('UNIQUE constraint failed')) {
        print('This might be a duplicate salary entry');
      } else if (e.toString().contains('NOT NULL constraint failed')) {
        print('This might be a missing required field');
      } else if (e.toString().contains('no such column')) {
        print('This might be a missing database column');
      } else if (e.toString().contains('constraint')) {
        print('This is a database constraint error');
      }
      
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

  Future<List<Salary>> getPaidSalaries() async {
    try {
      print('Getting paid salaries...');
      var client = await db;
      var results = await client.query(
        'salary',
        where: 'paid = ?',
        whereArgs: [1],
      );
      print('Found ${results.length} paid salaries');
      return results.map((map) => Salary.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting paid salaries: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Salary>> getPaidSalariesByMonth(String month) async {
    try {
      print('Getting paid salaries for month: $month');
      var client = await db;
      var results = await client.query(
        'salary',
        where: 'paid = ? AND month LIKE ?',
        whereArgs: [1, '$month%'],
      );
      print('Found ${results.length} paid salaries for month: $month');
      return results.map((map) => Salary.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting paid salaries by month: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Salary>> getPaidSalariesByWorkerIdAndMonth(int workerId, String month) async {
    try {
      print('Getting paid salaries for worker ID: $workerId and month: $month');
      var client = await db;
      var results = await client.query(
        'salary',
        where: 'workerId = ? AND paid = ? AND month LIKE ?',
        whereArgs: [workerId, 1, '$month%'],
      );
      print('Found ${results.length} paid salaries for worker ID: $workerId and month: $month');
      return results.map((map) => Salary.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting paid salaries by worker ID and month: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Salary>> getSalariesByWorkerId(int workerId) async {
    try {
      print('Getting salaries for worker ID: $workerId');
      var client = await db;
      var results = await client.query(
        'salary',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );
      print('Found ${results.length} salaries for worker ID: $workerId');
      return results.map((map) => Salary.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting salaries by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(
    int workerId,
    String month,
  ) async {
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
        print(
          'Salary found for worker ID $workerId and month $month: ${salary.totalSalary}',
        );
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
      print(
        'Inserting or updating login status for worker ID: ${loginStatus.workerId} on date: ${loginStatus.date}',
      );
      var client = await db;

      // First, check if a record already exists for this worker and date
      var existingRecords = await client.query(
        'login_status',
        where: 'workerId = ? AND date = ?',
        whereArgs: [loginStatus.workerId, loginStatus.date],
      );

      if (existingRecords.isNotEmpty) {
        // Update existing record
        print(
          'Updating existing login status record with ID: ${existingRecords.first['id']}',
        );
        return await client.update(
          'login_status',
          loginStatus.toMap(),
          where: 'id = ?',
          whereArgs: [existingRecords.first['id']],
        );
      } else {
        // Insert new record
        print('Inserting new login status record');
        return await client.insert('login_status', loginStatus.toMap());
      }
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
      var results = await client.query(
        'login_status',
        where: 'workerId = ?',
        whereArgs: [workerId],
      );
      print('Found ${results.length} login statuses for worker ID: $workerId');
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting login statuses by worker ID: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<LoginStatus>> getLoginStatusesByWorkerIdAndDate(
    int workerId,
    String date,
  ) async {
    try {
      print('Getting login statuses for worker ID: $workerId and date: $date');
      var client = await db;
      var results = await client.query(
        'login_status',
        where: 'workerId = ? AND date = ?',
        whereArgs: [workerId, date],
      );
      print(
        'Found ${results.length} login statuses for worker ID: $workerId and date: $date',
      );
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting login statuses by worker ID and date: $e');
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

  Future<int> deleteLoginStatus(int id) async {
    try {
      print('Deleting login status ID: $id');
      var client = await db;
      return await client.delete(
        'login_status',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      print('Error deleting login status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // LoginHistory methods
  Future<int> insertLoginHistory(Map<String, dynamic> loginHistory) async {
    try {
      print('Inserting login history');
      var client = await db;
      return await client.insert('login_history', loginHistory);
    } catch (e, stackTrace) {
      print('Error inserting login history: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getLoginHistory() async {
    try {
      print('Getting login history...');
      var client = await db;
      var results = await client.query('login_history');
      print('Found ${results.length} login history records');
      return results;
    } catch (e, stackTrace) {
      print('Error getting login history: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteLoginHistory(int id) async {
    try {
      print('Deleting login history ID: $id');
      var client = await db;
      return await client.delete(
        'login_history',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      print('Error deleting login history: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Notification methods
  Future<int> insertNotification(NotificationModel notification) async {
    try {
      print('Inserting notification: ${notification.title}');
      var client = await db;
      return await client.insert('notifications', notification.toMap());
    } catch (e, stackTrace) {
      print('Error inserting notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      print('Getting all notifications...');
      var client = await db;
      var results = await client.query('notifications');
      print('Found ${results.length} notifications');
      return results.map((map) => NotificationModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting notifications: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotificationsByUserIdAndRole(
    int userId,
    String userRole,
  ) async {
    try {
      print('Getting notifications for user ID: $userId and role: $userRole');
      var client = await db;
      var results = await client.query(
        'notifications',
        where: 'userId = ? AND userRole = ?',
        whereArgs: [userId, userRole],
      );
      print(
        'Found ${results.length} notifications for user ID: $userId and role: $userRole',
      );
      return results.map((map) => NotificationModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting notifications by user ID and role: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> markNotificationAsRead(int id) async {
    try {
      print('Marking notification ID: $id as read');
      var client = await db;
      return await client.update(
        'notifications',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      print('Error marking notification as read: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteNotification(int id) async {
    try {
      print('Deleting notification ID: $id');
      var client = await db;
      return await client.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stackTrace) {
      print('Error deleting notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteAllNotifications() async {
    try {
      print('Deleting all notifications');
      var client = await db;
      return await client.delete('notifications');
    } catch (e, stackTrace) {
      print('Error deleting all notifications: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Additional methods to fix compilation errors
  Future<LoginStatus?> getTodayLoginStatus(int workerId, String date) async {
    try {
      print('Getting today\'s login status for worker ID: $workerId and date: $date');
      var client = await db;
      var results = await client.query(
        'login_status',
        where: 'workerId = ? AND date = ?',
        whereArgs: [workerId, date],
      );
      if (results.isNotEmpty) {
        print('Found login status for worker ID: $workerId and date: $date');
        return LoginStatus.fromMap(results.first);
      }
      print('No login status found for worker ID: $workerId and date: $date');
      return null;
    } catch (e, stackTrace) {
      print('Error getting today\'s login status: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    try {
      print('Getting currently logged in workers (login statuses)');
      var client = await db;
      var results = await client.rawQuery('''
        SELECT ls.* FROM login_status ls
        WHERE ls.isLoggedIn = 1
      ''');
      print('Found ${results.length} currently logged in workers');
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting currently logged in workers: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<LoginStatus>> getTodayLoginStatuses(String date) async {
    try {
      print('Getting today\'s login statuses for date: $date');
      var client = await db;
      var results = await client.query(
        'login_status',
        where: 'date = ?',
        whereArgs: [date],
      );
      print('Found ${results.length} login statuses for date: $date');
      return results.map((map) => LoginStatus.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting today\'s login statuses: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getNotificationsByUser(int userId, String userRole) async {
    try {
      print('Getting notifications for user ID: $userId and role: $userRole');
      var client = await db;
      var results = await client.query(
        'notifications',
        where: 'userId = ? AND userRole = ?',
        whereArgs: [userId, userRole],
      );
      print('Found ${results.length} notifications for user ID: $userId and role: $userRole');
      return results.map((map) => NotificationModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting notifications by user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<List<NotificationModel>> getUnreadNotificationsByUser(int userId, String userRole) async {
    try {
      print('Getting unread notifications for user ID: $userId and role: $userRole');
      var client = await db;
      var results = await client.query(
        'notifications',
        where: 'userId = ? AND userRole = ? AND isRead = ?',
        whereArgs: [userId, userRole, 0],
      );
      print('Found ${results.length} unread notifications for user ID: $userId and role: $userRole');
      return results.map((map) => NotificationModel.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print('Error getting unread notifications by user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount(int userId, String userRole) async {
    try {
      print('Getting unread notification count for user ID: $userId and role: $userRole');
      var client = await db;
      var results = await client.query(
        'notifications',
        where: 'userId = ? AND userRole = ? AND isRead = ?',
        whereArgs: [userId, userRole, 0],
      );
      print('Found ${results.length} unread notifications for user ID: $userId and role: $userRole');
      return results.length;
    } catch (e, stackTrace) {
      print('Error getting unread notification count: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> markAllNotificationsAsRead(int userId, String userRole) async {
    try {
      print('Marking all notifications as read for user ID: $userId and role: $userRole');
      var client = await db;
      await client.update(
        'notifications',
        {'isRead': 1},
        where: 'userId = ? AND userRole = ?',
        whereArgs: [userId, userRole],
      );
      print('Marked all notifications as read for user ID: $userId and role: $userRole');
    } catch (e, stackTrace) {
      print('Error marking all notifications as read: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}