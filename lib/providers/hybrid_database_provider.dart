import 'package:flutter/foundation.dart';
import '../services/users_service.dart';
import '../services/attendance_service.dart';
import '../services/advance_service.dart';
import '../services/salary_service.dart';
import '../services/login_service.dart';
import '../models/user.dart';
import '../models/login_status.dart';
import '../models/advance.dart';
import '../utils/logger.dart';
import '../models/salary.dart';

class HybridDatabaseProvider with ChangeNotifier {
  final UsersService _usersService = UsersService();
  final AttendanceService _attendanceService = AttendanceService();
  final AdvanceService _advanceService = AdvanceService();
  final SalaryService _salaryService = SalaryService();
  final LoginService _loginService = LoginService();
  
  bool _useCloud = false;
  bool _firebaseInitialized = false;

  HybridDatabaseProvider() {
    // Since we've migrated to Supabase, we'll always use cloud storage
    _firebaseInitialized = true;
    _useCloud = true;
  }

  // Toggle between local and cloud storage
  void toggleStorageMode(bool useCloud) {
    // Always use cloud storage since we've migrated to Supabase
    _useCloud = true;
    _firebaseInitialized = true;
    notifyListeners();
  }

  bool get isUsingCloud => _useCloud && _firebaseInitialized;

  // Users methods
  Future<List<User>> getUsers() async {
    try {
      final usersData = await _usersService.getUsers();
      return usersData.map((data) => User.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting users: $e', e);
      return [];
    }
  }

  Future<User?> getUser(int id) async {
    try {
      final userData = await _usersService.getUser(id);
      return userData != null ? User.fromMap(userData) : null;
    } catch (e) {
      Logger.error('Error getting user: $e', e);
      return null;
    }
  }

  Future<User?> getUserByPhoneAndPassword(String phone, String password) async {
    try {
      // First find user by phone
      final userData = await _usersService.getUserByPhone(phone);
      if (userData == null) return null;
      
      // For demo purposes, we'll assume authentication is successful
      // In a real app, you would integrate with Supabase Auth
      final user = User.fromMap(userData);
      
      // Check if password matches (in a real app, this would be handled by Supabase Auth)
      // For now, we'll just return the user
      return user;
    } catch (e) {
      Logger.error('Error authenticating user: $e', e);
      return null;
    }
  }

  Future<bool> addUser(User user) async {
    try {
      await _usersService.insertUser(user.toMap());
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error adding user: $e', e);
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      await _usersService.updateUser(user.id!, user.toMap());
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error updating user: $e', e);
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      await _usersService.deleteUser(id);
      notifyListeners();
      return true;
    } catch (e) {
      Logger.error('Error deleting user: $e', e);
      return false;
    }
  }

  // Login Status methods
  Future<List<LoginStatus>> getLoginStatuses() async {
    try {
      // For login statuses, we'll need to implement a method to get all
      // For now, we'll return an empty list as this would require a specific Supabase query
      return [];
    } catch (e) {
      Logger.error('Error getting login statuses: $e', e);
      return [];
    }
  }

  Future<LoginStatus?> getTodayLoginStatus(int workerId, String date) async {
    try {
      final statusData = await _loginService.todayForWorker(workerId, date);
      return statusData != null ? LoginStatus.fromMap(statusData) : null;
    } catch (e) {
      Logger.error('Error getting today login status: $e', e);
      return null;
    }
  }

  Future<int> insertLoginStatus(LoginStatus loginStatus) async {
    try {
      final id = await _loginService.upsertStatus(loginStatus.toMap());
      return id;
    } catch (e) {
      Logger.error('Error inserting login status: $e', e);
      rethrow;
    }
  }

  Future<int> updateLoginStatus(LoginStatus loginStatus) async {
    try {
      await _loginService.upsertStatus(loginStatus.toMap());
      return loginStatus.id ?? 0;
    } catch (e) {
      Logger.error('Error updating login status: $e', e);
      rethrow;
    }
  }

  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    try {
      final statusesData = await _loginService.currentlyLoggedIn();
      return statusesData.map((data) => LoginStatus.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting logged in workers: $e', e);
      return [];
    }
  }

  // Advance methods
  Future<List<Advance>> getAdvances() async {
    try {
      final advancesData = await _advanceService.all();
      return advancesData.map((data) => Advance.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting advances: $e', e);
      return [];
    }
  }

  Future<List<Advance>> getAdvancesByWorkerId(int workerId) async {
    try {
      final advancesData = await _advanceService.byWorker(workerId);
      return advancesData.map((data) => Advance.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting advances by worker ID: $e', e);
      return [];
    }
  }

  Future<int> insertAdvance(Advance advance) async {
    try {
      final id = await _advanceService.insert(advance.toMap());
      return id;
    } catch (e, stackTrace) {
      Logger.error('Error in HybridDatabaseProvider.insertAdvance: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<int> updateAdvance(Advance advance) async {
    try {
      await _advanceService.updateById(advance.id!, advance.toMap());
      return advance.id ?? 0;
    } catch (e) {
      Logger.error('Error updating advance: $e', e);
      rethrow;
    }
  }

  Future<int> deleteAdvance(int id) async {
    try {
      await _advanceService.deleteById(id);
      return id;
    } catch (e) {
      Logger.error('Error deleting advance: $e', e);
      rethrow;
    }
  }

  // Salary methods
  Future<List<Salary>> getSalaries() async {
    try {
      final salariesData = await _salaryService.all();
      return salariesData.map((data) => Salary.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting salaries: $e', e);
      return [];
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(int workerId, String month) async {
    try {
      final salaryData = await _salaryService.byWorkerAndMonth(workerId, month);
      return salaryData != null ? Salary.fromMap(salaryData) : null;
    } catch (e) {
      Logger.error('Error getting salary by worker ID and month: $e', e);
      return null;
    }
  }

  Future<int> insertSalary(Salary salary) async {
    try {
      final id = await _salaryService.insert(salary.toMap());
      return id;
    } catch (e) {
      Logger.error('Error inserting salary: $e', e);
      rethrow;
    }
  }

  Future<int> updateSalary(Salary salary) async {
    try {
      await _salaryService.updateById(salary.id!, salary.toMap());
      return salary.id ?? 0;
    } catch (e) {
      Logger.error('Error updating salary: $e', e);
      rethrow;
    }
  }

  // Sync methods (not needed with Supabase since it's always cloud-based)
  Future<void> syncLocalToCloud() async {
    // Not needed with Supabase since it's always cloud-based
    Logger.info('Sync not needed with Supabase - data is always cloud-based');
  }

  Future<void> syncCloudToLocal() async {
    // Not needed with Supabase since it's always cloud-based
    Logger.info('Sync not needed with Supabase - data is always cloud-based');
  }
}