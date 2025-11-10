import 'package:flutter/foundation.dart';
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/login_service.dart';
// Removed location_service import since we're removing location features
import 'package:intl/intl.dart';
import '../utils/logger.dart';

class LoginStatusProvider with ChangeNotifier {
  final LoginService _loginService = LoginService();
  List<LoginStatus> _loginStatuses = [];
  LoginStatus? _todayLoginStatus;
  bool _isLoggedIn = false;

  List<LoginStatus> get loginStatuses => _loginStatuses;
  LoginStatus? get todayLoginStatus => _todayLoginStatus;
  bool get isLoggedIn => _isLoggedIn;

  // Load all login statuses
  Future<void> loadLoginStatuses() async {
    try {
      final statusesData = await _loginService.statuses();
      _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses: $e', e);
    }
  }

  // Load login statuses for a specific worker
  Future<void> loadLoginStatusesByWorkerId(int workerId) async {
    try {
      final statusesData = await _loginService.statusesByWorker(workerId);
      _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses for worker: $e', e);
    }
  }

  // Get login status for a specific worker and date
  Future<LoginStatus?> getLoginStatusForDate(int workerId, String date) async {
    try {
      final statusData = await _loginService.todayForWorker(workerId, date);
      return statusData != null ? LoginStatus.fromMap(statusData) : null;
    } catch (e) {
      Logger.error('Error getting login status for date: $e', e);
      return null;
    }
  }

  // Check today's login status for a worker
  Future<void> checkTodayLoginStatus(int workerId) async {
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final statusData = await _loginService.todayForWorker(workerId, today);
      _todayLoginStatus = statusData != null ? LoginStatus.fromMap(statusData) : null;
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
      final existingStatusData = await _loginService.todayForWorker(worker.id!, today);
      final LoginStatus? existingStatus = existingStatusData != null ? LoginStatus.fromMap(existingStatusData) : null;
      
      LoginStatus loginStatus;
      Map<String, dynamic> statusData;
      
      if (existingStatus != null) {
        // Update existing login status
        statusData = {
          'id': existingStatus.id,
          'worker_id': worker.id!,
          'date': today,
          'login_time': existingStatus.loginTime ?? currentTime,
          'logout_time': existingStatus.logoutTime,
          'is_logged_in': true,
        };
        
        await _loginService.upsertStatus(statusData);
        loginStatus = LoginStatus.fromMap(statusData);
      } else {
        // Create new login status record
        statusData = {
          'worker_id': worker.id!,
          'date': today,
          'login_time': currentTime,
          'is_logged_in': true,
        };
        
        await _loginService.upsertStatus(statusData);
        loginStatus = LoginStatus.fromMap(statusData);
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
      final todayStatusData = await _loginService.todayForWorker(worker.id!, today);
      final LoginStatus? todayStatus = todayStatusData != null ? LoginStatus.fromMap(todayStatusData) : null;

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
      
      final updatedStatusData = {
        'id': todayStatus.id,
        'worker_id': worker.id!,
        'date': today,
        'login_time': todayStatus.loginTime,
        'logout_time': currentTime,
        'is_logged_in': false,
      };

      await _loginService.upsertStatus(updatedStatusData);
      final LoginStatus updatedStatus = LoginStatus.fromMap(updatedStatusData);
      
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
      await _loginService.upsertStatus(loginStatus.toMap());
      
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
      final statusesData = await _loginService.currentlyLoggedIn();
      return statusesData.map((data) => LoginStatus.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting logged in workers: $e', e);
      return [];
    }
  }

  // Get login statistics
  Future<Map<String, int>> getLoginStatistics() async {
    try {
      // For now, we'll return empty statistics since we don't have access to users
      // In a real implementation, you would fetch users from the users service
      return {
        'total': 0,
        'loggedIn': 0,
        'absent': 0,
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