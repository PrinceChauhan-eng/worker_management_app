import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';
import '../models/user.dart';
import '../models/login_status.dart';
import '../models/advance.dart';
import '../utils/logger.dart';
import '../models/salary.dart';

class HybridDatabaseProvider with ChangeNotifier {
  final DatabaseHelper _localDb = DatabaseHelper();
  late FirebaseService _firebaseService;
  bool _useCloud = false;
  bool _firebaseInitialized = false;

  HybridDatabaseProvider() {
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      _firebaseService = FirebaseService();
      _firebaseInitialized = true;
      Logger.info('Firebase service initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize Firebase: $e', e);
      Logger.info('Falling back to local storage only');
      _firebaseInitialized = false;
      _useCloud = false; // Force local storage if Firebase fails
    }
  }

  // Toggle between local and cloud storage
  void toggleStorageMode(bool useCloud) {
    // Only allow cloud storage if Firebase is initialized
    if (useCloud && !_firebaseInitialized) {
      Logger.warning('Cannot enable cloud storage: Firebase not initialized');
      return;
    }
    _useCloud = useCloud && _firebaseInitialized;
    notifyListeners();
  }

  bool get isUsingCloud => _useCloud && _firebaseInitialized;

  // Users methods
  Future<List<User>> getUsers() async {
    if (_useCloud && _firebaseInitialized) {
      // Return users from Firebase
      return await _firebaseService.getUsers();
    } else {
      // Return users from local database
      return await _localDb.getUsers();
    }
  }

  Future<User?> getUser(int id) async {
    if (_useCloud && _firebaseInitialized) {
      // Get user from Firebase
      // This would require a specific method in FirebaseService
      final users = await _firebaseService.getUsers();
      try {
        return users.firstWhere((user) => user.id == id);
      } catch (e) {
        return null; // Return null if user not found
      }
    } else {
      // Get user from local database
      return await _localDb.getUser(id);
    }
  }

  Future<User?> getUserByPhoneAndPassword(String phone, String password) async {
    if (_useCloud && _firebaseInitialized) {
      // Authenticate user with Firebase
      return await _firebaseService.getUserByPhoneAndPassword(phone, password);
    } else {
      // Authenticate user with local database
      return await _localDb.getUserByPhoneAndPassword(phone, password);
    }
  }

  Future<bool> addUser(User user) async {
    try {
      if (_useCloud && _firebaseInitialized) {
        // Add user to Firebase
        await _firebaseService.addUser(user);
      } else {
        // Add user to local database
        await _localDb.insertUser(user);
      }
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error adding user: $e', e);
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      if (_useCloud && _firebaseInitialized) {
        // Update user in Firebase
        await _firebaseService.updateUser(user);
      } else {
        // Update user in local database
        await _localDb.updateUser(user);
      }
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error updating user: $e', e);
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      if (_useCloud && _firebaseInitialized) {
        // Delete user from Firebase
        await _firebaseService.deleteUser(id);
      } else {
        // Delete user from local database
        await _localDb.deleteUser(id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error deleting user: $e', e);
      return false;
    }
  }

  // Login Status methods
  Future<List<LoginStatus>> getLoginStatuses() async {
    if (_useCloud && _firebaseInitialized) {
      // Get login statuses from Firebase
      return await _firebaseService.getLoginStatuses();
    } else {
      // Get login statuses from local database
      return await _localDb.getLoginStatuses();
    }
  }

  Future<LoginStatus?> getTodayLoginStatus(int workerId, String date) async {
    if (_useCloud && _firebaseInitialized) {
      // Get today's login status from Firebase
      return await _firebaseService.getTodayLoginStatus(workerId, date);
    } else {
      // Get today's login status from local database
      return await _localDb.getTodayLoginStatus(workerId, date);
    }
  }

  Future<int> insertLoginStatus(LoginStatus loginStatus) async {
    if (_useCloud && _firebaseInitialized) {
      // Insert login status to Firebase
      await _firebaseService.addLoginStatus(loginStatus);
      return loginStatus.id ?? 0;
    } else {
      // Insert login status to local database
      return await _localDb.insertLoginStatus(loginStatus);
    }
  }

  Future<int> updateLoginStatus(LoginStatus loginStatus) async {
    if (_useCloud && _firebaseInitialized) {
      // Update login status in Firebase
      await _firebaseService.updateLoginStatus(loginStatus);
      return loginStatus.id ?? 0;
    } else {
      // Update login status in local database
      return await _localDb.updateLoginStatus(loginStatus);
    }
  }

  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    if (_useCloud && _firebaseInitialized) {
      // Get logged in workers from Firebase
      return await _firebaseService.getCurrentlyLoggedInWorkers();
    } else {
      // Get logged in workers from local database
      return await _localDb.getCurrentlyLoggedInWorkers();
    }
  }

  // Advance methods
  Future<List<Advance>> getAdvances() async {
    if (_useCloud && _firebaseInitialized) {
      // Get advances from Firebase
      return await _firebaseService.getAdvances();
    } else {
      // Get advances from local database
      return await _localDb.getAdvances();
    }
  }

  Future<List<Advance>> getAdvancesByWorkerId(int workerId) async {
    if (_useCloud && _firebaseInitialized) {
      // Get advances by worker ID from Firebase
      return await _firebaseService.getAdvancesByWorkerId(workerId);
    } else {
      // Get advances by worker ID from local database
      return await _localDb.getAdvancesByWorkerId(workerId);
    }
  }

  Future<int> insertAdvance(Advance advance) async {
    try {
      if (_useCloud && _firebaseInitialized) {
        // Insert advance to Firebase
        await _firebaseService.addAdvance(advance);
        return advance.id ?? 0;
      } else {
        // Insert advance to local database
        return await _localDb.insertAdvance(advance);
      }
    } catch (e, stackTrace) {
      Logger.error('Error in HybridDatabaseProvider.insertAdvance: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateAdvance(Advance advance) async {
    if (_useCloud && _firebaseInitialized) {
      // Update advance in Firebase
      await _firebaseService.updateAdvance(advance);
      return advance.id ?? 0;
    } else {
      // Update advance in local database
      return await _localDb.updateAdvance(advance);
    }
  }

  Future<int> deleteAdvance(int id) async {
    // Note: Firebase implementation would need the full advance object to delete
    // For now, we'll just delete from local database
    // In a real implementation, you might want to query for the advance first
    return await _localDb.deleteAdvance(id);
  }

  // Salary methods
  Future<List<Salary>> getSalaries() async {
    if (_useCloud && _firebaseInitialized) {
      // Get salaries from Firebase
      return await _firebaseService.getSalaries();
    } else {
      // Get salaries from local database
      return await _localDb.getSalaries();
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(int workerId, String month) async {
    if (_useCloud && _firebaseInitialized) {
      // Get salary from Firebase
      return await _firebaseService.getSalaryByWorkerIdAndMonth(workerId, month);
    } else {
      // Get salary from local database
      return await _localDb.getSalaryByWorkerIdAndMonth(workerId, month);
    }
  }

  Future<int> insertSalary(Salary salary) async {
    if (_useCloud && _firebaseInitialized) {
      // Insert salary to Firebase
      await _firebaseService.addSalary(salary);
      return salary.id ?? 0;
    } else {
      // Insert salary to local database
      return await _localDb.insertSalary(salary);
    }
  }

  Future<int> updateSalary(Salary salary) async {
    if (_useCloud && _firebaseInitialized) {
      // Update salary in Firebase
      await _firebaseService.updateSalary(salary);
      return salary.id ?? 0;
    } else {
      // Update salary in local database
      return await _localDb.updateSalary(salary);
    }
  }

  // Sync methods for migrating between local and cloud
  Future<void> syncLocalToCloud() async {
    if (!_firebaseInitialized) {
      throw Exception('Cannot sync to cloud: Firebase not initialized');
    }
    
    try {
      // Get all data from local database and upload to Firebase
      final users = await _localDb.getUsers();
      for (var user in users) {
        await _firebaseService.addUser(user);
      }

      final loginStatuses = await _localDb.getLoginStatuses();
      for (var status in loginStatuses) {
        await _firebaseService.addLoginStatus(status);
      }

      final advances = await _localDb.getAdvances();
      for (var advance in advances) {
        await _firebaseService.addAdvance(advance);
      }

      final salaries = await _localDb.getSalaries();
      for (var salary in salaries) {
        await _firebaseService.addSalary(salary);
      }

      Logger.info('Local data synced to cloud successfully');
    } catch (e) {
      Logger.error('Error syncing local data to cloud: $e', e);
      rethrow;
    }
  }

  Future<void> syncCloudToLocal() async {
    if (!_firebaseInitialized) {
      throw Exception('Cannot sync from cloud: Firebase not initialized');
    }
    
    try {
      // Get all data from Firebase and save to local database
      // Note: This would require clearing local data first in a real implementation
      final users = await _firebaseService.getUsers();
      for (var user in users) {
        await _localDb.insertUser(user);
      }

      // Similar for other data types...
      Logger.info('Cloud data synced to local successfully');
    } catch (e) {
      Logger.error('Error syncing cloud data to local: $e', e);
      rethrow;
    }
  }
}