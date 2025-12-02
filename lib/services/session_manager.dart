import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/logger.dart';

class SessionManager {
  static const String keyActiveSessions = "activeSessions";
  static const String keyDefaultSession = "defaultSession";
  static const String keyRememberMe = "rememberMe";
  static const String keyRememberedPhone = "rememberedPhone";
  static const String keyLastLoginTime = "lastLoginTime";
  static const String keyCurrentUserId = "currentUserId"; // Track current user per tab

  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      Logger.info('Initializing SessionManager...');
      _prefs = await SharedPreferences.getInstance();
      Logger.info('SessionManager initialized successfully');
    } catch (e, stackTrace) {
      Logger.error('Error initializing SessionManager: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      rethrow;
    }
  }

  // Enhanced session management for multiple users
  Future<void> addSession(int userId, String userRole) async {
    try {
      Logger.info('Adding session for user ID: $userId, role: $userRole');
      
      // Get existing sessions
      List<Session> sessions = await getActiveSessions();
      
      // Check if session already exists for this user
      bool sessionExists = sessions.any((session) => session.userId == userId);
      
      if (!sessionExists) {
        // Create new session
        final now = DateTime.now().toString();
        Session newSession = Session(
          userId: userId,
          userRole: userRole,
          loginTime: now,
          lastActiveTime: now,
        );
        
        // Add to sessions list
        sessions.add(newSession);
        
        // Save sessions
        await _saveSessions(sessions);
      }
      
      // Also save as last login time
      await _prefs.setString(keyLastLoginTime, DateTime.now().toString());
      
      Logger.info('Session added/updated successfully for user ID: $userId');
    } catch (e, stackTrace) {
      Logger.error('Error adding session: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      rethrow;
    }
  }

  Future<void> removeSession(int userId) async {
    try {
      Logger.info('Removing session for user ID: $userId');
      
      // Get existing sessions
      List<Session> sessions = await getActiveSessions();
      
      // Remove session for this user
      sessions.removeWhere((session) => session.userId == userId);
      
      // Save updated sessions
      await _saveSessions(sessions);
      
      Logger.info('Session removed successfully for user ID: $userId');
    } catch (e, stackTrace) {
      Logger.error('Error removing session: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      rethrow;
    }
  }

  Future<List<Session>> getActiveSessions() async {
    try {
      String? sessionsJson = _prefs.getString(keyActiveSessions);
      
      // Handle null case
      if (sessionsJson == null) {
        return [];
      }
      
      List<dynamic> sessionsList = jsonDecode(sessionsJson);
      return sessionsList.map((session) => Session.fromJson(session)).toList();
    } catch (e, stackTrace) {
      Logger.error('Error getting active sessions: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      return [];
    }
  }

  Future<Session?> getDefaultSession() async {
    try {
      String? defaultSessionJson = _prefs.getString(keyDefaultSession);
      
      // Handle null case
      if (defaultSessionJson == null) {
        return null;
      }
      
      return Session.fromJson(jsonDecode(defaultSessionJson));
    } catch (e, stackTrace) {
      Logger.error('Error getting default session: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      return null;
    }
  }

  Future<void> setDefaultSession(Session session) async {
    try {
      await _prefs.setString(keyDefaultSession, jsonEncode(session.toJson()));
    } catch (e, stackTrace) {
      Logger.error('Error setting default session: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
    }
  }

  Future<void> _saveSessions(List<Session> sessions) async {
    try {
      String sessionsJson = jsonEncode(sessions.map((session) => session.toJson()).toList());
      await _prefs.setString(keyActiveSessions, sessionsJson);
    } catch (e, stackTrace) {
      Logger.error('Error saving sessions: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      rethrow;
    }
  }

  // Remember me functionality
  Future<void> setRememberMe(String phone) async {
    try {
      await _prefs.setBool(keyRememberMe, true);
      await _prefs.setString(keyRememberedPhone, phone);
    } catch (e, stackTrace) {
      Logger.error('Error setting remember me: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
    }
  }

  Future<void> clearRememberMe() async {
    try {
      await _prefs.remove(keyRememberMe);
      await _prefs.remove(keyRememberedPhone);
    } catch (e, stackTrace) {
      Logger.error('Error clearing remember me: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
    }
  }

  Future<Map<String, String>?> getRememberMe() async {
    try {
      final isRemembered = _prefs.getBool(keyRememberMe) ?? false;
      if (isRemembered) {
        final phone = _prefs.getString(keyRememberedPhone) ?? '';
        return {'phone': phone};
      }
      return null;
    } catch (e, stackTrace) {
      Logger.error('Error getting remember me: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      return null;
    }
  }

  // Last login time
  Future<String?> getLastLoginTime() async {
    try {
      return _prefs.getString(keyLastLoginTime);
    } catch (e, stackTrace) {
      Logger.error('Error getting last login time: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      return null;
    }
  }

  Future<bool> hasActiveSessions() async {
    try {
      List<Session> sessions = await getActiveSessions();
      return sessions.isNotEmpty;
    } catch (e, stackTrace) {
      Logger.error('Error checking active sessions: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      return false;
    }
  }

  Future<void> clearAllSessions() async {
    try {
      Logger.info('Clearing all sessions');
      await _prefs.remove(keyActiveSessions);
      await _prefs.remove(keyDefaultSession);
      await _prefs.remove(keyCurrentUserId); // Clear current user tracking
      Logger.info('All sessions cleared successfully');
    } catch (e, stackTrace) {
      Logger.error('Error clearing all sessions: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      rethrow;
    }
  }

  // New methods for tab-specific session management
  Future<void> setCurrentUserId(int userId) async {
    try {
      Logger.info('Setting current user ID: $userId for this tab');
      await _prefs.setInt(keyCurrentUserId, userId);
    } catch (e, stackTrace) {
      Logger.error('Error setting current user ID: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      final userId = _prefs.getInt(keyCurrentUserId);
      Logger.info('Current user ID for this tab: $userId');
      return userId;
    } catch (e, stackTrace) {
      Logger.error('Error getting current user ID: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      return null;
    }
  }

  Future<void> clearCurrentUserId() async {
    try {
      Logger.info('Clearing current user ID for this tab');
      await _prefs.remove(keyCurrentUserId);
    } catch (e, stackTrace) {
      Logger.error('Error clearing current user ID: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
    }
  }
  
  // Enhanced logout that can clear either all sessions or just current tab
  Future<void> logout(bool clearAllSessions) async {
    try {
      // Always clear the current tab user
      await clearCurrentUserId();

      // Always clear remember me
      await clearRememberMe();

      if (clearAllSessions) {
        // Optional: clear everything
        await this.clearAllSessions();
      }

    } catch (e, stackTrace) {
      Logger.error('Error during logout: $e', e);
      Logger.error('Stack trace: $stackTrace', stackTrace);
      rethrow;
    }
  }
}

class Session {
  final int userId;
  final String userRole;
  final String loginTime;
  final String lastActiveTime;

  Session({
    required this.userId,
    required this.userRole,
    required this.loginTime,
    required this.lastActiveTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userRole': userRole,
      'loginTime': loginTime,
      'lastActiveTime': lastActiveTime,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      userId: json['userId'],
      userRole: json['userRole'],
      loginTime: json['loginTime'],
      lastActiveTime: json['lastActiveTime'],
    );
  }
}