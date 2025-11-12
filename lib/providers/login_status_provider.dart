import 'package:intl/intl.dart'; // Fix the import
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/login_service.dart';
import '../services/users_service.dart'; // Add this import
import '../services/location_service.dart'; // Add this import
import '../services/schema_refresher.dart'; // Add this import
import '../utils/logger.dart';
import 'base_provider.dart';

class LoginStatusProvider extends BaseProvider {
  final LoginService _loginService = LoginService();
  final UsersService _usersService = UsersService(); // Add this
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  List<LoginStatus> _loginStatuses = [];
  LoginStatus? _todayLoginStatus;
  bool _isLoggedIn = false;

  List<LoginStatus> get loginStatuses => _loginStatuses;
  LoginStatus? get todayLoginStatus => _todayLoginStatus;
  bool get isLoggedIn => _isLoggedIn;

  // Load all login statuses
  Future<void> loadLoginStatuses() async {
    setState(ViewState.busy);
    try {
      final statusesData = await _loginService.statuses();
      _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final statusesData = await _loginService.statuses();
        _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
      }
    }
  }

  // Load login statuses for a specific worker
  Future<void> loadLoginStatusesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    try {
      final statusesData = await _loginService.statusesByWorker(workerId);
      _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading login statuses for worker: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final statusesData = await _loginService.statusesByWorker(workerId);
        _loginStatuses = statusesData.map((data) => LoginStatus.fromMap(data)).toList();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
      }
    }
  }

  // Get login status for a specific worker and date
  Future<LoginStatus?> getLoginStatusForDate(int workerId, String date) async {
    setState(ViewState.busy);
    try {
      final statusData = await _loginService.todayForWorker(workerId, date);
      setState(ViewState.idle);
      return statusData != null ? LoginStatus.fromMap(statusData) : null;
    } catch (e) {
      Logger.error('Error getting login status for date: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final statusData = await _loginService.todayForWorker(workerId, date);
        setState(ViewState.idle);
        return statusData != null ? LoginStatus.fromMap(statusData) : null;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        return null;
      }
    }
  }

  // Check today's login status for a worker
  Future<void> checkTodayLoginStatus(int workerId) async {
    setState(ViewState.busy);
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final statusData = await _loginService.todayForWorker(workerId, today);
      _todayLoginStatus = statusData != null ? LoginStatus.fromMap(statusData) : null;
      _isLoggedIn = _todayLoginStatus?.isLoggedIn ?? false;
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error checking today login status: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final statusData = await _loginService.todayForWorker(workerId, today);
        _todayLoginStatus = statusData != null ? LoginStatus.fromMap(statusData) : null;
        _isLoggedIn = _todayLoginStatus?.isLoggedIn ?? false;
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
      }
    }
  }

  // Worker login with location tracking
  Future<Map<String, dynamic>> workerLogin(User worker) async {
    setState(ViewState.busy);
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      
      // Get current location with address
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocationWithAddress();
      
      if (locationData == null) {
        setState(ViewState.idle);
        return {
          'success': false,
          'message': 'Unable to get location. Please enable location services and try again.',
        };
      }
      
      // Check if there's already a login status for today
      final existingStatusData = await _loginService.todayForWorker(worker.id!, today);
      final LoginStatus? existingStatus = existingStatusData != null ? LoginStatus.fromMap(existingStatusData) : null;
      
      LoginStatus loginStatus;
      Map<String, dynamic> statusData;
      
      if (existingStatus != null) {
        // Update existing login status with location data
        statusData = {
          'id': existingStatus.id,
          'worker_id': worker.id!,
          'date': today,
          'login_time': existingStatus.loginTime ?? currentTime,
          'logout_time': existingStatus.logoutTime,
          'is_logged_in': true,
          'login_latitude': locationData['latitude'],
          'login_longitude': locationData['longitude'],
          'login_address': locationData['address'],
        };
        
        await _loginService.upsertStatus(statusData);
        loginStatus = LoginStatus.fromMap(statusData);
      } else {
        // Create new login status record with location data
        statusData = {
          'worker_id': worker.id!,
          'date': today,
          'login_time': currentTime,
          'is_logged_in': true,
          'login_latitude': locationData['latitude'],
          'login_longitude': locationData['longitude'],
          'login_address': locationData['address'],
        };
        
        await _loginService.upsertStatus(statusData);
        loginStatus = LoginStatus.fromMap(statusData);
      }
      
      // Update local state
      _todayLoginStatus = loginStatus;
      _isLoggedIn = true;
      setState(ViewState.idle);
      notifyListeners();

      return {
        'success': true,
        'message': 'Login successful! Attendance marked as present.\nLocation: ${locationData['address']}',
        'loginStatus': loginStatus,
      };
    } catch (e) {
      Logger.error('Error during worker login: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Retry the login operation
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        
        // Get current location with address
        final locationService = LocationService();
        final locationData = await locationService.getCurrentLocationWithAddress();
        
        if (locationData == null) {
          setState(ViewState.idle);
          return {
            'success': false,
            'message': 'Unable to get location. Please enable location services and try again.',
          };
        }
        
        // Check if there's already a login status for today
        final existingStatusData = await _loginService.todayForWorker(worker.id!, today);
        final LoginStatus? existingStatus = existingStatusData != null ? LoginStatus.fromMap(existingStatusData) : null;
        
        LoginStatus loginStatus;
        Map<String, dynamic> statusData;
        
        if (existingStatus != null) {
          // Update existing login status with location data
          statusData = {
            'id': existingStatus.id,
            'worker_id': worker.id!,
            'date': today,
            'login_time': existingStatus.loginTime ?? currentTime,
            'logout_time': existingStatus.logoutTime,
            'is_logged_in': true,
            'login_latitude': locationData['latitude'],
            'login_longitude': locationData['longitude'],
            'login_address': locationData['address'],
          };
          
          await _loginService.upsertStatus(statusData);
          loginStatus = LoginStatus.fromMap(statusData);
        } else {
          // Create new login status record with location data
          statusData = {
            'worker_id': worker.id!,
            'date': today,
            'login_time': currentTime,
            'is_logged_in': true,
            'login_latitude': locationData['latitude'],
            'login_longitude': locationData['longitude'],
            'login_address': locationData['address'],
          };
          
          await _loginService.upsertStatus(statusData);
          loginStatus = LoginStatus.fromMap(statusData);
        }
        
        // Update local state
        _todayLoginStatus = loginStatus;
        _isLoggedIn = true;
        setState(ViewState.idle);
        notifyListeners();

        return {
          'success': true,
          'message': 'Login successful! Attendance marked as present.\nLocation: ${locationData['address']}',
          'loginStatus': loginStatus,
        };
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        return {
          'success': false,
          'message': 'Error during login: $retryError',
        };
      }
    }
  }

  // Worker logout with location tracking
  Future<Map<String, dynamic>> workerLogout(User worker) async {
    setState(ViewState.busy);
    try {
      // Check if worker is logged in
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayStatusData = await _loginService.todayForWorker(worker.id!, today);
      final LoginStatus? todayStatus = todayStatusData != null ? LoginStatus.fromMap(todayStatusData) : null;

      if (todayStatus == null || !todayStatus.isLoggedIn) {
        setState(ViewState.idle);
        return {
          'success': false,
          'message': 'You are not logged in today.',
        };
      }

      // Get current location with address for logout
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocationWithAddress();
      
      if (locationData == null) {
        setState(ViewState.idle);
        return {
          'success': false,
          'message': 'Unable to get location. Please enable location services and try again.',
        };
      }

      // Update login status with logout information and location data
      String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      
      final updatedStatusData = {
        'id': todayStatus.id,
        'worker_id': worker.id!,
        'date': today,
        'login_time': todayStatus.loginTime,
        'logout_time': currentTime,
        'is_logged_in': false,
        'login_latitude': todayStatus.loginLatitude,
        'login_longitude': todayStatus.loginLongitude,
        'login_address': todayStatus.loginAddress,
        'logout_latitude': locationData['latitude'],
        'logout_longitude': locationData['longitude'],
        'logout_address': locationData['address'],
      };

      await _loginService.upsertStatus(updatedStatusData);

      // Update local state
      _todayLoginStatus = LoginStatus.fromMap(updatedStatusData);
      _isLoggedIn = false;
      setState(ViewState.idle);
      notifyListeners();

      return {
        'success': true,
        'message': 'Logout successful!\nLocation: ${locationData['address']}',
      };
    } catch (e) {
      Logger.error('Error during worker logout: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Retry the logout operation
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayStatusData = await _loginService.todayForWorker(worker.id!, today);
        final LoginStatus? todayStatus = todayStatusData != null ? LoginStatus.fromMap(todayStatusData) : null;

        if (todayStatus == null || !todayStatus.isLoggedIn) {
          setState(ViewState.idle);
          return {
            'success': false,
            'message': 'You are not logged in today.',
          };
        }

        // Get current location with address for logout
        final locationService = LocationService();
        final locationData = await locationService.getCurrentLocationWithAddress();
        
        if (locationData == null) {
          setState(ViewState.idle);
          return {
            'success': false,
            'message': 'Unable to get location. Please enable location services and try again.',
          };
        }

        // Update login status with logout information and location data
        String currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
        
        final updatedStatusData = {
          'id': todayStatus.id,
          'worker_id': worker.id!,
          'date': today,
          'login_time': todayStatus.loginTime,
          'logout_time': currentTime,
          'is_logged_in': false,
          'login_latitude': todayStatus.loginLatitude,
          'login_longitude': todayStatus.loginLongitude,
          'login_address': todayStatus.loginAddress,
          'logout_latitude': locationData['latitude'],
          'logout_longitude': locationData['longitude'],
          'logout_address': locationData['address'],
        };

        await _loginService.upsertStatus(updatedStatusData);

        // Update local state
        _todayLoginStatus = LoginStatus.fromMap(updatedStatusData);
        _isLoggedIn = false;
        setState(ViewState.idle);
        notifyListeners();

        return {
          'success': true,
          'message': 'Logout successful!\nLocation: ${locationData['address']}',
        };
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        return {
          'success': false,
          'message': 'Error during logout: $retryError',
        };
      }
    }
  }

  /// Get login statistics (total workers, logged in, absent)
  Future<Map<String, int>> getLoginStatistics() async {
    try {
      // Get currently logged in workers
      final loggedInData = await _loginService.currentlyLoggedIn();
      final loggedInCount = loggedInData.length;
      
      // For total workers, we'll need to get this from another source
      // For now, we'll return just the logged in count and set others to 0
      // The dashboard screen will need to get total workers from UserProvider
      return {
        'total': 0, // Will be updated by dashboard
        'loggedIn': loggedInCount,
        'absent': 0, // Will be calculated by dashboard
      };
    } catch (e) {
      Logger.error('Error getting login statistics: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Get currently logged in workers
        final loggedInData = await _loginService.currentlyLoggedIn();
        final loggedInCount = loggedInData.length;
        
        return {
          'total': 0, // Will be updated by dashboard
          'loggedIn': loggedInCount,
          'absent': 0, // Will be calculated by dashboard
        };
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        return {
          'total': 0,
          'loggedIn': 0,
          'absent': 0,
        };
      }
    }
  }

  /// Get currently logged in workers as LoginStatus objects
  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    try {
      final loggedInData = await _loginService.currentlyLoggedIn();
      return loggedInData.map((data) => LoginStatus.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting currently logged in workers: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 1));
      final loggedInData = await _loginService.currentlyLoggedIn();
      return loggedInData.map((data) => LoginStatus.fromMap(data)).toList();
    }
  }

  /// Update or insert login status (handles both cases)
  Future<int> updateLoginStatus(LoginStatus loginStatus) async {
    setState(ViewState.busy);
    try {
      final id = await _loginService.upsertStatus(loginStatus.toMap());
      
      // Reload login statuses to reflect changes
      await loadLoginStatuses();
      
      setState(ViewState.idle);
      notifyListeners();
      return id;
    } catch (e) {
      Logger.error('Error updating login status: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final id = await _loginService.upsertStatus(loginStatus.toMap());
        
        // Reload login statuses to reflect changes
        await loadLoginStatuses();
        
        setState(ViewState.idle);
        notifyListeners();
        return id;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        rethrow;
      }
    }
  }
}