import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/users_service.dart';
import '../utils/password_utils.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Login with identifier (phone/email/id) and password
  Future<bool> login({
    required String identifier,
    required String password,
    required String role,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final authService = AuthService();
      final usersService = UsersService();

      User? user;

      // Try to find user by different methods
      if (_isValidEmail(identifier)) {
        // Email login
        final userData = await usersService.getUserByEmail(identifier);
        if (userData != null && userData['role'] == role) {
          final foundUser = User.fromMap(userData);
          if (_verifyPassword(password, foundUser.password)) {
            user = foundUser;
          }
        }
      } else if (_isValidPhone(identifier)) {
        // Phone login
        final userData = await usersService.getUserByPhone(identifier);
        if (userData != null && userData['role'] == role) {
          final foundUser = User.fromMap(userData);
          if (_verifyPassword(password, foundUser.password)) {
            user = foundUser;
          }
        }
      } else {
        // Try ID login (numeric)
        final userId = int.tryParse(identifier);
        if (userId != null && userId > 0) {
          final userData = await usersService.getUser(userId);
          if (userData != null && userData['role'] == role) {
            final foundUser = User.fromMap(userData);
            if (_verifyPassword(password, foundUser.password)) {
              user = foundUser;
            }
          }
        }
      }

      if (user != null) {
        // Login successful
        _currentUser = user;
        
        // Save session
        final sessionManager = SessionManager();
        await sessionManager.addSession(user.id!, user.role);
        await sessionManager.setCurrentUserId(user.id!);
        
        // Handle remember me
        if (rememberMe) {
          await sessionManager.setRememberMe(user.phone ?? identifier);
        }
        
        Future.microtask(() => notifyListeners());
        return true;
      } else {
        _setError('Invalid credentials');
        return false;
      }
    } catch (e) {
      Logger.error('Login error: $e', e);
      _setError('Login failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout current user
  Future<void> logout({bool clearAllSessions = false}) async {
    _setLoading(true);

    try {
      final sessionManager = SessionManager();

      if (clearAllSessions) {
        await sessionManager.clearAllSessions();
      } else {
        // Clear only this tab's session
        await sessionManager.clearCurrentUserId();
      }

      _currentUser = null;

      Future.microtask(() => notifyListeners());
    } catch (e) {
      Logger.error('Logout error: $e', e);
      _setError('Logout failed');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if user has required role
  bool hasRole(String requiredRole) {
    return _currentUser?.role == requiredRole;
  }

  /// Check if user can access a route
  bool canAccessRoute(String route) {
    if (_currentUser == null) return false;
    
    // Admin can access everything
    if (_currentUser!.role == 'admin') return true;
    
    // Worker restrictions
    if (_currentUser!.role == 'worker') {
      // Workers can only access worker-specific routes
      return route.startsWith('/worker') || 
             route == '/worker-dashboard' || 
             route == '/' || 
             route.startsWith('/profile');
    }
    
    return false;
  }

  /// Set current user (used during app initialization)
  void setCurrentUser(User user) {
    _currentUser = user;
    Future.microtask(() => notifyListeners());
  }

  /// Clear current user
  void clearCurrentUser() {
    _currentUser = null;
    Future.microtask(() => notifyListeners());
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  void _setError(String error) {
    _errorMessage = error;
    Future.microtask(() => notifyListeners());
  }

  void _clearError() {
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Remove any spaces, dashes, or brackets
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return false;
    }

    // Check for valid length (10 digits for most countries, including India)
    if (cleanPhone.length < 10) {
      return false;
    }

    if (cleanPhone.length > 15) {
      return false;
    }

    // For India: Check if it starts with 6-9 (valid mobile number prefix)
    if (cleanPhone.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(cleanPhone)) {
        return false;
      }
    }

    return true;
  }

  bool _verifyPassword(String inputPassword, String storedPassword) {
    if (PasswordUtils.isHashed(storedPassword)) {
      return PasswordUtils.verifyPassword(inputPassword, storedPassword);
    } else {
      return inputPassword == storedPassword;
    }
  }
}