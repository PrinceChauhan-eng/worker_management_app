import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String KEY_IS_LOGGED_IN = "isLoggedIn";
  static const String KEY_USER_ID = "userId";
  static const String KEY_USER_ROLE = "userRole";

  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      print('Initializing SessionManager...');
      _prefs = await SharedPreferences.getInstance();
      print('SessionManager initialized successfully');
    } catch (e) {
      print('Error initializing SessionManager: $e');
      rethrow;
    }
  }

  // Login session methods
  Future<void> setLoginSession(int userId, String userRole) async {
    try {
      print('Setting login session for user ID: $userId, role: $userRole');
      await _prefs.setBool(KEY_IS_LOGGED_IN, true);
      await _prefs.setInt(KEY_USER_ID, userId);
      await _prefs.setString(KEY_USER_ROLE, userRole);
      print('Login session set successfully');
    } catch (e) {
      print('Error setting login session: $e');
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      bool isLoggedIn = _prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
      print('Checking if user is logged in: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('Error checking if user is logged in: $e');
      return false;
    }
  }

  Future<int> getUserId() async {
    try {
      int userId = _prefs.getInt(KEY_USER_ID) ?? 0;
      print('Retrieved user ID from session: $userId');
      return userId;
    } catch (e) {
      print('Error getting user ID from session: $e');
      return 0;
    }
  }

  Future<String> getUserRole() async {
    try {
      String userRole = _prefs.getString(KEY_USER_ROLE) ?? '';
      print('Retrieved user role from session: $userRole');
      return userRole;
    } catch (e) {
      print('Error getting user role from session: $e');
      return '';
    }
  }

  Future<void> logout() async {
    try {
      print('Logging out user');
      await _prefs.remove(KEY_IS_LOGGED_IN);
      await _prefs.remove(KEY_USER_ID);
      await _prefs.remove(KEY_USER_ROLE);
      print('User logged out successfully');
    } catch (e) {
      print('Error logging out user: $e');
      rethrow;
    }
  }
}