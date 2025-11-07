import 'package:flutter/foundation.dart';
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
// Removed location_service import since we're removing location features
import 'package:intl/intl.dart';

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
      print('Error loading login statuses: $e');
    }
  }

  // Load login statuses for a specific worker
  Future<void> loadLoginStatusesByWorkerId(int workerId) async {
    try {
      _loginStatuses = await _dbHelper.getLoginStatusesByWorkerId(workerId);
      notifyListeners();
    } catch (e) {
      print('Error loading login statuses for worker: $e');
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
      print('Error checking today login status: $e');
    }
  }

  // Worker login without location verification
  Future<Map<String, dynamic>> workerLogin(User worker) async {
    try {
      // Check if worker already has a login status for today
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      LoginStatus? existingStatus = await _dbHelper.getTodayLoginStatus(worker.id!, today);
      
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
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
        'message': 'Login successful! Attendance marked.',
        'loginStatus': loginStatus,
      };
    } catch (e) {
      print('Error during worker login: $e');
      return {
        'success': false,
        'message': 'Error during login: $e',
      };
    }
  }

  // Worker logout without location verification
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

      // Check if 8 hours have passed since login
      if (todayStatus.loginTime != null) {
        try {
          final loginTime = DateTime.parse('$today ${todayStatus.loginTime}');
          final currentTime = DateTime.now();
          final duration = currentTime.difference(loginTime);
          final hoursWorked = duration.inMinutes / 60.0;
          
          if (hoursWorked < 8.0) {
            final remainingHours = 8.0 - hoursWorked;
            return {
              'success': false,
              'message': 'You must work at least 8 hours. ${remainingHours.toStringAsFixed(1)} hours remaining.',
            };
          }
        } catch (e) {
          print('Error calculating work duration: $e');
          // If there's an error in calculation, we'll allow logout but log the error
        }
      }

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

      // Calculate and display working hours (capped at 8 hours for display)
      double workingHours = updatedStatus.workingHours;
      if (workingHours > 8.0) {
        workingHours = 8.0;
      }

      return {
        'success': true,
        'message': 'Logout successful! Working hours: ${workingHours.toStringAsFixed(2)} hrs',
        'loginStatus': updatedStatus,
      };
    } catch (e) {
      print('Error during worker logout: $e');
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
      print('Error updating login status: $e');
      rethrow;
    }
  }

  // Get currently logged in workers (for admin dashboard)
  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    try {
      return await _dbHelper.getCurrentlyLoggedInWorkers();
    } catch (e) {
      print('Error getting logged in workers: $e');
      return [];
    }
  }

  // Get login statistics
  Future<Map<String, int>> getLoginStatistics() async {
    try {
      List<User> allWorkers = await _dbHelper.getUsers();
      List<User> workers = allWorkers.where((u) => u.role == 'worker').toList();
      
      List<LoginStatus> loggedInWorkers = await getCurrentlyLoggedInWorkers();
      
      int totalWorkers = workers.length;
      int loggedIn = loggedInWorkers.length;
      int absent = totalWorkers - loggedIn;

      return {
        'total': totalWorkers,
        'loggedIn': loggedIn,
        'absent': absent,
      };
    } catch (e) {
      print('Error getting login statistics: $e');
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