import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String KEY_IS_LOGGED_IN = "isLoggedIn";
  static const String KEY_USER_ID = "userId";
  static const String KEY_USER_ROLE = "userRole";
  static const String KEY_REMEMBER_ME = "rememberMe";
  static const String KEY_REMEMBERED_PHONE = "rememberedPhone";
  static const String KEY_LAST_LOGIN_TIME = "lastLoginTime";

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
      
      // Save last login time
      final now = DateTime.now().toString();
      await _prefs.setString(KEY_LAST_LOGIN_TIME, now);
      
      // Verify the session was saved
      bool isLoggedIn = _prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
      int savedUserId = _prefs.getInt(KEY_USER_ID) ?? 0;
      String savedUserRole = _prefs.getString(KEY_USER_ROLE) ?? '';
      print('Session verification - Logged in: $isLoggedIn, User ID: $savedUserId, Role: $savedUserRole');
      
      print('Login session set successfully');
    } catch (e) {
      print('Error setting login session: $e');
      rethrow;
    }
  }

  // Remember me functionality
  Future<void> setRememberMe(String phone) async {
    try {
      await _prefs.setBool(KEY_REMEMBER_ME, true);
      await _prefs.setString(KEY_REMEMBERED_PHONE, phone);
    } catch (e) {
      print('Error setting remember me: $e');
    }
  }

  Future<void> clearRememberMe() async {
    try {
      await _prefs.remove(KEY_REMEMBER_ME);
      await _prefs.remove(KEY_REMEMBERED_PHONE);
    } catch (e) {
      print('Error clearing remember me: $e');
    }
  }

  Future<Map<String, String>?> getRememberMe() async {
    try {
      final isRemembered = _prefs.getBool(KEY_REMEMBER_ME) ?? false;
      if (isRemembered) {
        final phone = _prefs.getString(KEY_REMEMBERED_PHONE) ?? '';
        return {'phone': phone};
      }
      return null;
    } catch (e) {
      print('Error getting remember me: $e');
      return null;
    }
  }

  // Last login time
  Future<String?> getLastLoginTime() async {
    try {
      return _prefs.getString(KEY_LAST_LOGIN_TIME);
    } catch (e) {
      print('Error getting last login time: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      bool isLoggedIn = _prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
      print('Checking if user is logged in: $isLoggedIn');
      
      // Additional debugging
      if (isLoggedIn) {
        int userId = _prefs.getInt(KEY_USER_ID) ?? 0;
        String userRole = _prefs.getString(KEY_USER_ROLE) ?? '';
        print('Session data - User ID: $userId, Role: $userRole');
      }
      
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
      
      // Verify logout
      bool isLoggedIn = _prefs.getBool(KEY_IS_LOGGED_IN) ?? false;
      int userId = _prefs.getInt(KEY_USER_ID) ?? 0;
      String userRole = _prefs.getString(KEY_USER_ROLE) ?? '';
      print('Session after logout - Logged in: $isLoggedIn, User ID: $userId, Role: $userRole');
      
      print('User logged out successfully');
    } catch (e) {
      print('Error logging out user: $e');
      rethrow;
    }
  }
}