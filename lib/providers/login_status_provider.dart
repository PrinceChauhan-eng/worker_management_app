import 'package:intl/intl.dart'; // Fix the import
import '../models/login_status.dart';
import '../models/user.dart';
import '../services/login_service.dart';
// Add this import
import '../services/location_service.dart'; // Add this import
import '../services/schema_refresher.dart'; // Add this import
import '../utils/logger.dart';
import 'base_provider.dart';

class LoginStatusProvider extends BaseProvider {
  final LoginService _loginService = LoginService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  List<LoginStatus> _loginStatuses = [];
  LoginStatus? _todayLoginStatus;
  bool _isLoggedIn = false;

  // Add caching flags for today's data (Fix #5)
  bool _isLoadingToday = false;
  bool _isLoadedToday = false;
  Map<String, dynamic>? _todayCache;

  List<LoginStatus> get loginStatuses => _loginStatuses;
  LoginStatus? get todayLoginStatus => _todayLoginStatus;
  bool get isLoggedIn => _isLoggedIn;

  // Invalidate today's cache (Fix #5)
  void _invalidateTodayCache() {
    _isLoadedToday = false;
    _todayCache = null;
  }

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

  // Check today's login status for a worker with caching (Fix #5)
  Future<void> checkTodayLoginStatus(int workerId) async {
    // Check if already loaded
    if (_isLoadedToday && _todayCache != null) {
      // Use cached data
      _todayLoginStatus = _todayCache!['todayLoginStatus'] as LoginStatus?;
      _isLoggedIn = _todayCache!['isLoggedIn'] as bool;
      notifyListeners();
      return;
    }

    // Check if already loading
    if (_isLoadingToday) {
      // Wait for the ongoing request to complete
      while (_isLoadingToday) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return cached data if available
      if (_todayCache != null) {
        _todayLoginStatus = _todayCache!['todayLoginStatus'] as LoginStatus?;
        _isLoggedIn = _todayCache!['isLoggedIn'] as bool;
        notifyListeners();
      }
      return;
    }

    // Set loading flag
    _isLoadingToday = true;
    setState(ViewState.busy);
    
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final statusData = await _loginService.todayForWorker(workerId, today);
      _todayLoginStatus = statusData != null ? LoginStatus.fromMap(statusData) : null;
      _isLoggedIn = _todayLoginStatus?.isLoggedIn ?? false;
      
      // Cache the data
      _todayCache = {
        'todayLoginStatus': _todayLoginStatus,
        'isLoggedIn': _isLoggedIn,
      };
      _isLoadedToday = true;
      
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
        
        // Cache the data
        _todayCache = {
          'todayLoginStatus': _todayLoginStatus,
          'isLoggedIn': _isLoggedIn,
        };
        _isLoadedToday = true;
        
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
      }
    } finally {
      // Reset loading flag
      _isLoadingToday = false;
    }
  }

  /// Load today's login status only if not already loaded or if forced
  Future<void> loadIfNeeded(int workerId) async {
    // Only load if todayLoginStatus is null
    if (_todayLoginStatus == null) {
      await checkTodayLoginStatus(workerId);
    }
  }

  // Worker login with location tracking
  Future<Map<String, dynamic>> workerLogin(User worker) async {
    setState(ViewState.busy);
    try {
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      // Use normalized time method (Fix #7)
      String currentTime = Logger.nowTime();
      
      // Get current location with address (with timeout)
      final locationService = LocationService();
      LocationData? locationData;
      
      try {
        // Add timeout to the location request
        locationData = await locationService.getCurrentLocationWithAddress()
            .timeout(const Duration(seconds: 15)); // 15 second timeout
      } catch (e) {
        Logger.error('Location request timed out during login: $e', e);
        // Continue with login even if location fails
      }
      
      // Check if there's already a login status for today
      final existingStatusData = await _loginService.todayForWorker(worker.id!, today);
      final LoginStatus? existingStatus = existingStatusData != null ? LoginStatus.fromMap(existingStatusData) : null;
      
      LoginStatus loginStatus;
      Map<String, dynamic> statusData;
      
      if (existingStatus != null) {
        // Update existing login status with location data
        statusData = {
          'id': existingStatus.id, // Keep ID for updates
          'worker_id': worker.id!,
          'date': today,
          'login_time': existingStatus.loginTime ?? currentTime,
          'logout_time': existingStatus.logoutTime,
          'is_logged_in': true,
          'login_latitude': existingStatus.loginLatitude,
          'login_longitude': existingStatus.loginLongitude,
          'login_address': existingStatus.loginAddress,
        };
        
        // Add new location data only if we got it
        if (locationData != null) {
          statusData.addAll({
            'login_latitude': locationData.latitude,
            'login_longitude': locationData.longitude,
            'login_address': locationData.address,
          });
        }
        
        await _loginService.upsertStatus(statusData);
        loginStatus = LoginStatus.fromMap(statusData);
      } else {
        // Create new login status record (no ID for inserts)
        statusData = {
          'worker_id': worker.id!,
          'date': today,
          'login_time': currentTime,
          'is_logged_in': true,
        };
        
        // Add location data only if we got it
        if (locationData != null) {
          statusData.addAll({
            'login_latitude': locationData.latitude,
            'login_longitude': locationData.longitude,
            'login_address': locationData.address,
          });
        }
        
        await _loginService.upsertStatus(statusData);
        loginStatus = LoginStatus.fromMap(statusData);
      }
      
      // Update local state
      _todayLoginStatus = loginStatus;
      _isLoggedIn = true;
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
      setState(ViewState.idle);
      notifyListeners();

      // Create message based on whether we got location data
      String message = 'Login successful! Attendance marked as present.';
      if (locationData != null) {
        message += '\nLocation: ${locationData.address}';
      } else {
        message += '\nLocation data not available.';
      }

      return {
        'success': true,
        'message': message,
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
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
        // Use normalized time method (Fix #7)
        String currentTime = Logger.nowTime();
        
        // Get current location with address (with timeout)
        final locationService = LocationService();
        LocationData? locationData;
        
        try {
          // Add timeout to the location request
          locationData = await locationService.getCurrentLocationWithAddress()
              .timeout(const Duration(seconds: 15)); // 15 second timeout
        } catch (e) {
          Logger.error('Location request timed out during login: $e', e);
          // Continue with login even if location fails
        }
        
        // Check if there's already a login status for today
        final existingStatusData = await _loginService.todayForWorker(worker.id!, today);
        final LoginStatus? existingStatus = existingStatusData != null ? LoginStatus.fromMap(existingStatusData) : null;
        
        LoginStatus loginStatus;
        Map<String, dynamic> statusData;
        
        if (existingStatus != null) {
          // Update existing login status with location data
          statusData = {
            'id': existingStatus.id, // Keep ID for updates
            'worker_id': worker.id!,
            'date': today,
            'login_time': existingStatus.loginTime ?? currentTime,
            'logout_time': existingStatus.logoutTime,
            'is_logged_in': true,
            'login_latitude': existingStatus.loginLatitude,
            'login_longitude': existingStatus.loginLongitude,
            'login_address': existingStatus.loginAddress,
          };
          
          // Add new location data only if we got it
          if (locationData != null) {
            statusData.addAll({
              'login_latitude': locationData.latitude,
              'login_longitude': locationData.longitude,
              'login_address': locationData.address,
            });
          }
          
          await _loginService.upsertStatus(statusData);
          loginStatus = LoginStatus.fromMap(statusData);
        } else {
          // Create new login status record (no ID for inserts)
          statusData = {
            'worker_id': worker.id!,
            'date': today,
            'login_time': currentTime,
            'is_logged_in': true,
          };
          
          // Add location data only if we got it
          if (locationData != null) {
            statusData.addAll({
              'login_latitude': locationData.latitude,
              'login_longitude': locationData.longitude,
              'login_address': locationData.address,
            });
          }
          
          await _loginService.upsertStatus(statusData);
          loginStatus = LoginStatus.fromMap(statusData);
        }
        
        // Update local state
        _todayLoginStatus = loginStatus;
        _isLoggedIn = true;
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
        setState(ViewState.idle);
        notifyListeners();

        // Create message based on whether we got location data
        String message = 'Login successful! Attendance marked as present.';
        if (locationData != null) {
          message += '\nLocation: ${locationData.address}';
        } else {
          message += '\nLocation data not available.';
        }

        return {
          'success': true,
          'message': message,
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

  // Worker logout with optional location tracking
  Future<Map<String, dynamic>> workerLogout(User worker) async {
    setState(ViewState.busy);
    try {
      // Check if worker is logged in
      String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      final todayStatusData = await _loginService.todayForWorker(worker.id!, today);
      final LoginStatus? todayStatus = todayStatusData != null ? LoginStatus.fromMap(todayStatusData) : null;

      if (todayStatus == null || !todayStatus.isLoggedIn) {
        setState(ViewState.idle);
        return {
          'success': false,
          'message': 'You are not logged in today.',
        };
      }

      // Try to get current location with address for logout (but don't block if it fails)
      final locationService = LocationService();
      LocationData? locationData;
      
      try {
        // Add timeout to the location request
        locationData = await locationService.getCurrentLocationWithAddress()
            .timeout(const Duration(seconds: 15)); // 15 second timeout
      } catch (e) {
        Logger.error('Location request timed out or failed during logout: $e', e);
        // Continue with logout even if location fails
      }

      // Update login status with logout information
      // Use normalized time method (Fix #7)
      String currentTime = Logger.nowTime();
      
      final updatedStatusData = {
        'id': todayStatus.id, // Keep ID for updates
        'worker_id': worker.id!,
        'date': today,
        'login_time': todayStatus.loginTime,
        'logout_time': currentTime,
        'is_logged_in': false,
        'login_latitude': todayStatus.loginLatitude,
        'login_longitude': todayStatus.loginLongitude,
        'login_address': todayStatus.loginAddress,
      };

      // Add logout location data only if we got it
      if (locationData != null) {
        updatedStatusData.addAll({
          'logout_latitude': locationData.latitude,
          'logout_longitude': locationData.longitude,
          'logout_address': locationData.address,
        });
      }

      await _loginService.upsertStatus(updatedStatusData);

      // Update local state
      _todayLoginStatus = LoginStatus.fromMap(updatedStatusData);
      _isLoggedIn = false;
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
      setState(ViewState.idle);
      notifyListeners();

      // Create message based on whether we got location data
      String message = 'Logout successful!';
      if (locationData != null) {
        message += '\nLocation: ${locationData.address}';
      } else {
        message += '\nLocation data not available.';
      }

      return {
        'success': true,
        'message': message,
      };
    } catch (e) {
      Logger.error('Error during worker logout: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        // Retry the logout operation
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
        final todayStatusData = await _loginService.todayForWorker(worker.id!, today);
        final LoginStatus? todayStatus = todayStatusData != null ? LoginStatus.fromMap(todayStatusData) : null;

        if (todayStatus == null || !todayStatus.isLoggedIn) {
          setState(ViewState.idle);
          return {
            'success': false,
            'message': 'You are not logged in today.',
          };
        }

        // Try to get current location with address for logout (but don't block if it fails)
        final locationService = LocationService();
        LocationData? locationData;
        
        try {
          // Add timeout to the location request
          locationData = await locationService.getCurrentLocationWithAddress()
              .timeout(const Duration(seconds: 15)); // 15 second timeout
        } catch (e) {
          Logger.error('Location request timed out or failed during logout: $e', e);
          // Continue with logout even if location fails
        }

        // Update login status with logout information
        // Use normalized time method (Fix #7)
        String currentTime = Logger.nowTime();
        
        final updatedStatusData = {
          'id': todayStatus.id, // Keep ID for updates
          'worker_id': worker.id!,
          'date': today,
          'login_time': todayStatus.loginTime,
          'logout_time': currentTime,
          'is_logged_in': false,
          'login_latitude': todayStatus.loginLatitude,
          'login_longitude': todayStatus.loginLongitude,
          'login_address': todayStatus.loginAddress,
        };

        // Add logout location data only if we got it
        if (locationData != null) {
          updatedStatusData.addAll({
            'logout_latitude': locationData.latitude,
            'logout_longitude': locationData.longitude,
            'logout_address': locationData.address,
          });
        }

        await _loginService.upsertStatus(updatedStatusData);

        // Update local state
        _todayLoginStatus = LoginStatus.fromMap(updatedStatusData);
        _isLoggedIn = false;
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
        setState(ViewState.idle);
        notifyListeners();

        // Create message based on whether we got location data
        String message = 'Logout successful!';
        if (locationData != null) {
          message += '\nLocation: ${locationData.address}';
        } else {
          message += '\nLocation data not available.';
        }

        return {
          'success': true,
          'message': message,
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
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
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
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
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

  /// Get today's login status
  Future<List<Map<String, dynamic>>> getTodayLoginStatus() async {
    try {
      return await _loginService.getTodayLoginStatus();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 2));
      return await _loginService.getTodayLoginStatus();
    }
  }

  /// Refresh today's login status data
  Future<void> refreshToday() async {
    // Invalidate cache
    _invalidateTodayCache();
    
    // Reload login statuses
    await loadLoginStatuses();
    
    // Notify listeners
    notifyListeners();
  }
}