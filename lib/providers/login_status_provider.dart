import 'package:flutter/foundation.dart';
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import '../services/location_service.dart';
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

  // Worker login with location verification
  Future<Map<String, dynamic>> workerLogin(User worker) async {
    try {
      // Check if worker has work location set
      if (worker.workLocationLatitude == null || worker.workLocationLongitude == null) {
        return {
          'success': false,
          'message': 'Work location not set. Please contact admin.',
        };
      }

      // Verify current location
      Map<String, dynamic> locationResult = await LocationService.verifyLocation(
        worker.workLocationLatitude!,
        worker.workLocationLongitude!,
        worker.locationRadius ?? 100.0,
      );

      if (!locationResult['success']) {
        return {
          'success': false,
          'message': locationResult['message'],
        };
      }

      // Create login status record
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());

      LoginStatus loginStatus = LoginStatus(
        workerId: worker.id!,
        date: today,
        loginTime: currentTime,
        loginLatitude: locationResult['latitude'],
        loginLongitude: locationResult['longitude'],
        loginAddress: locationResult['address'],
        loginDistance: locationResult['distance'],
        isLoggedIn: true,
      );

      await _dbHelper.insertLoginStatus(loginStatus);
      
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

  // Worker logout with location verification
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

      // Check if worker has work location set
      if (worker.workLocationLatitude == null || worker.workLocationLongitude == null) {
        return {
          'success': false,
          'message': 'Work location not set. Please contact admin.',
        };
      }

      // Verify current location
      Map<String, dynamic> locationResult = await LocationService.verifyLocation(
        worker.workLocationLatitude!,
        worker.workLocationLongitude!,
        worker.locationRadius ?? 100.0,
      );

      if (!locationResult['success']) {
        return {
          'success': false,
          'message': locationResult['message'],
        };
      }

      // Update login status with logout information
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      
      LoginStatus updatedStatus = LoginStatus(
        id: todayStatus.id,
        workerId: worker.id!,
        date: today,
        loginTime: todayStatus.loginTime,
        logoutTime: currentTime,
        loginLatitude: todayStatus.loginLatitude,
        loginLongitude: todayStatus.loginLongitude,
        loginAddress: todayStatus.loginAddress,
        logoutLatitude: locationResult['latitude'],
        logoutLongitude: locationResult['longitude'],
        logoutAddress: locationResult['address'],
        loginDistance: todayStatus.loginDistance,
        logoutDistance: locationResult['distance'],
        isLoggedIn: false,
      );

      await _dbHelper.updateLoginStatus(updatedStatus);
      
      // Update local state
      _todayLoginStatus = updatedStatus;
      _isLoggedIn = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'Logout successful! Working hours: ${updatedStatus.workingHours.toStringAsFixed(2)} hrs',
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
