import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/session_manager.dart';
import '../services/users_service.dart';
import '../screens/login_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/worker_dashboard/worker_dashboard_screen.dart';
import '../utils/logger.dart';

class RouteGuard {
  static Future<User?> checkAuthentication() async {
    try {
      // Check for tab-specific current user first
      final sessionManager = SessionManager();
      final currentUserId = await sessionManager.getCurrentUserId();
      
      if (currentUserId != null) {
        // Load specific user for this tab
        final usersService = UsersService();
        final userData = await usersService.getUser(currentUserId);
        final user = userData != null ? User.fromMap(userData) : null;
        
        if (user != null) {
          return user;
        } else {
          // User not found, clear current user ID
          await sessionManager.clearCurrentUserId();
        }
      }

      // Check for existing sessions if no tab-specific user
      final sessions = await sessionManager.getActiveSessions();
      
      if (sessions.isNotEmpty) {
        // Load user data for the first session
        final userId = sessions.first.userId;
        final userRole = sessions.first.userRole;
        
        // Load user from database
        final usersService = UsersService();
        final userData = await usersService.getUser(userId);
        final user = userData != null ? User.fromMap(userData) : null;
        
        if (user != null && user.role == userRole) {
          // Set this user as current for this tab
          await sessionManager.setCurrentUserId(userId);
          return user;
        } else {
          // User not found or role mismatch, clear sessions
          await sessionManager.clearAllSessions();
        }
      }
      
      return null;
    } catch (e) {
      Logger.error('Error in route guard: $e', e);
      return null;
    }
  }

  static bool canAccessRoute(User user, String route) {
    // Admin can access everything
    if (user.role == 'admin') {
      // Prevent admin from accessing worker-only routes
      if (route.startsWith('/worker/') && !route.startsWith('/admin/')) {
        return false;
      }
      return true;
    }
    
    // Worker restrictions
    if (user.role == 'worker') {
      // Workers can only access worker-specific routes
      return route.startsWith('/worker') || 
             route == '/worker_dashboard' || 
             route == '/' || 
             route.startsWith('/profile') ||
             route == '/notifications';
    }
    
    return false;
  }

  static Widget getRedirectScreen(User user) {
    if (user.role == 'admin') {
      return const AdminDashboardScreen();
    } else if (user.role == 'worker') {
      return const WorkerDashboardScreen();
    } else {
      return const LoginScreen();
    }
  }

  static void redirectToLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  static void redirectToDashboard(BuildContext context, User user) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => user.role == 'admin' 
            ? const AdminDashboardScreen() 
            : const WorkerDashboardScreen(),
      ),
      (route) => false,
    );
  }
}