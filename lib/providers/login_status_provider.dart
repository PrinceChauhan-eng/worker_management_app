import 'package:flutter/foundation.dart';
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
// Removed location_service import since we're removing location features
import 'package:intl/intl.dart';
import '../utils/logger.dart';

class LoginStatusProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<LoginStatus> _loginStatuses = [];
  LoginStatus? _todayLoginStatus;
  bool _isLoggedIn = false;

  List<LoginStatus> get loginStatuses => _loginStatuses;
  LoginStatus? get todayLoginStatus => _todayLoginStatus;
  bool get isLoggedIn => _isLoggedIn;

  // Load all login statuses
  Future<void> loadLoginStatuses() async {
    try {
      _loginStatuses = await _dbHelper.getLoginStatuses();
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses: $e', e);
    }
  }

  // Load login statuses for a specific worker
  Future<void> loadLoginStatusesByWorkerId(int workerId) async {
    try {
      _loginStatuses = await _dbHelper.getLoginStatusesByWorkerId(workerId);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses for worker: $e', e);
    }
  }

  // Get login status for a specific worker and date
  Future<LoginStatus?> getLoginStatusForDate(int workerId, String date) async {
    try {
      return await _dbHelper.getTodayLoginStatus(workerId, date);
    } catch (e) {
      Logger.error('Error getting login status for date: $e', e);
      return null;
    }
  }

  // Check today's login status for a worker
  Future<void> checkTodayLoginStatus(int workerId) async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayLoginStatus = await _dbHelper.getTodayLoginStatus(workerId, today);
      _isLoggedIn = _todayLoginStatus?.isLoggedIn ?? false;
      notifyListeners();
    } catch (e) {
      Logger.error('Error checking today login status: $e', e);
    }
  }

  // Worker login without location verification
  Future<Map<String, dynamic>> workerLogin(User worker) async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      
      // Check if there's already a login status for today
      LoginStatus? existingStatus = await _dbHelper.getTodayLoginStatus(worker.id!, today);
      
      LoginStatus loginStatus;
      
      if (existingStatus != null) {
        // Update existing login status
        loginStatus = LoginStatus(
          id: existingStatus.id,
          workerId: worker.id!,
          date: today,
          loginTime: existingStatus.loginTime ?? currentTime,
          logoutTime: existingStatus.logoutTime,
          isLoggedIn: true,
        );
        
        await _dbHelper.updateLoginStatus(loginStatus);
      } else {
        // Create new login status record
        loginStatus = LoginStatus(
          workerId: worker.id!,
          date: today,
          loginTime: currentTime,
          isLoggedIn: true,
        );
        
        await _dbHelper.insertLoginStatus(loginStatus);
      }
      
      // Update local state
      _todayLoginStatus = loginStatus;
      _isLoggedIn = true;
      notifyListeners();

      return {
        'success': true,
        'message': 'Login successful! Attendance marked as present.',
        'loginStatus': loginStatus,
      };
    } catch (e) {
      Logger.error('Error during worker login: $e', e);
      return {
        'success': false,
        'message': 'Error during login: $e',
      };
    }
  }

  // Worker logout without location verification and without 8-hour requirement
  Future<Map<String, dynamic>> workerLogout(User worker) async {
    try {
      // Check if worker is logged in
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      LoginStatus? todayStatus = await _dbHelper.getTodayLoginStatus(worker.id!, today);

      if (todayStatus == null || !todayStatus.isLoggedIn) {
        return {
          'success': false,
          'message': 'You are not logged in today.',
        };
      }

      // Remove the 8-hour work requirement check
      // Workers can now logout at any time after logging in

      // Update login status with logout information
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      
      LoginStatus updatedStatus = LoginStatus(
        id: todayStatus.id,
        workerId: worker.id!,
        date: today,
        loginTime: todayStatus.loginTime,
        logoutTime: currentTime,
        isLoggedIn: false,
      );

      await _dbHelper.updateLoginStatus(updatedStatus);
      
      // Update local state
      _todayLoginStatus = updatedStatus;
      _isLoggedIn = false;
      notifyListeners();

      // Calculate and display working hours
      double workingHours = updatedStatus.workingHours;

      return {
        'success': true,
        'message': 'Logout successful! Working hours: ${workingHours.toStringAsFixed(2)} hrs',
        'loginStatus': updatedStatus,
      };
    } catch (e) {
      Logger.error('Error during worker logout: $e', e);
      return {
        'success': false,
        'message': 'Error during logout: $e',
      };
    }
  }

  // Update login status (for admin editing)
  Future<void> updateLoginStatus(LoginStatus loginStatus) async {
    try {
      await _dbHelper.updateLoginStatus(loginStatus);
      
      // Reload the login statuses to reflect the changes
      await loadLoginStatusesByWorkerId(loginStatus.workerId);
      
      // Also update today's login status if this is for the current user
      final today = DateTime.now().toString().split(' ')[0];
      if (loginStatus.date == today) {
        _todayLoginStatus = loginStatus;
        _isLoggedIn = loginStatus.isLoggedIn;
      }
      
      notifyListeners();
    } catch (e) {
      Logger.error('Error updating login status: $e', e);
      rethrow;
    }
  }

  // Get currently logged in workers (for admin dashboard)
  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    try {
      return await _dbHelper.getCurrentlyLoggedInWorkers();
    } catch (e) {
      Logger.error('Error getting logged in workers: $e', e);
      return [];
    }
  }

  // Get login statistics
  Future<Map<String, int>> getLoginStatistics() async {
    try {
      List<User> allWorkers = await _dbHelper.getUsers();
      List<User> workers = allWorkers.where((u) => u.role == 'worker').toList();
      
      // Get today's date
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Get all login statuses for today
      List<LoginStatus> todayLoginStatuses = await _dbHelper.getTodayLoginStatuses(today);
      
      // Count unique workers with login statuses for today
      Set<int> workersWithTodayStatus = todayLoginStatuses.map((status) => status.workerId).toSet();
      
      int totalWorkers = workers.length;
      int loggedIn = todayLoginStatuses.where((status) => status.isLoggedIn).length;
      // Absent workers are those who don't have a login status for today or have a status but are not logged in
      int absent = totalWorkers - workersWithTodayStatus.length;

      return {
        'total': totalWorkers,
        'loggedIn': loggedIn,
        'absent': absent,
      };
    } catch (e) {
      Logger.error('Error getting login statistics: $e', e);
      return {
        'total': 0,
        'loggedIn': 0,
        'absent': 0,
      };
    }
  }

  // Clear login statuses (for refresh)
  void clearLoginStatuses() {
    _loginStatuses = [];
    _todayLoginStatus = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}