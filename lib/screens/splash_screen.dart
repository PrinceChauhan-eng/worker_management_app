import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/error_reporter.dart';
import '../services/session_manager.dart';
import '../providers/user_provider.dart';
import '../models/user.dart'; // Import User model
import '../services/users_service.dart'; // Import UsersService
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'worker_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    print('SplashScreen initState called');
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      print('Splash screen delay completed');

      // Database initialization is handled by Supabase, no need to initialize here
      print('Using Supabase for data storage');

      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }

      // Check for tab-specific current user first
      final sessionManager = SessionManager();
      final currentUserId = await sessionManager.getCurrentUserId();
      
      if (currentUserId != null) {
        print('Found tab-specific user ID: $currentUserId');
        // Load specific user for this tab
        final usersService = UsersService();
        final userData = await usersService.getUser(currentUserId);
        final user = userData != null ? User.fromMap(userData) : null;
        
        if (user != null) {
          print('Found current user for this tab: ${user.name} (ID: $currentUserId)');
          
          // Set user in provider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setCurrentUser(user);
          
          // Navigate to appropriate dashboard
          if (user.role == 'admin') {
            print('Navigating to Admin Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else {
            print('Navigating to Worker Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
            );
          }
          return;
        } else {
          print('User not found for ID: $currentUserId, clearing current user ID');
          await sessionManager.clearCurrentUserId();
        }
      }

      // Check for existing sessions if no tab-specific user
      final sessions = await sessionManager.getActiveSessions();
      
      if (sessions.isNotEmpty) {
        // Load user data for the first session
        final userId = sessions.first.userId;
        final userRole = sessions.first.userRole;
        
        print('Found existing session for user ID: $userId, role: $userRole');
        
        // Load user from database
        final usersService = UsersService();
        final userData = await usersService.getUser(userId);
        final user = userData != null ? User.fromMap(userData) : null;
        
        if (user != null && user.role == userRole) {
          print('User loaded from database: ${user.name}');
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setCurrentUser(user);
          print('Setting current user: ${user.name}');
          
          // Set this user as current for this tab
          await sessionManager.setCurrentUserId(userId);
          
          // Navigate to appropriate dashboard
          if (user.role == 'admin') {
            print('Navigating to Admin Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          } else {
            print('Navigating to Worker Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
            );
          }
          return;
        } else {
          print('User not found or role mismatch, clearing sessions');
          await sessionManager.clearAllSessions();
        }
      }
      
      // Check for "remember me" functionality as a last resort
      final remembered = await sessionManager.getRememberMe();
      if (remembered != null && remembered['phone'] != null) {
        final rememberedPhone = remembered['phone'];
        if (rememberedPhone != null && rememberedPhone.isNotEmpty) {
          print('Found remembered user, attempting auto-login for phone: $rememberedPhone');
          final usersService = UsersService();
          
          // Try to find user by phone
          final userData = await usersService.getUserByPhone(rememberedPhone);
          
          if (userData != null) {
            final user = User.fromMap(userData);
            print('Auto-login successful for user: ${user.name}');
            
            // Set user in provider
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            userProvider.setCurrentUser(user);
            
            // Add session and set current user ID
            await sessionManager.addSession(user.id!, user.role);
            await sessionManager.setCurrentUserId(user.id!);
            
            // Navigate to appropriate dashboard
            if (user.role == 'admin') {
              print('Navigating to Admin Dashboard');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              );
            } else {
              print('Navigating to Worker Dashboard');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const WorkerDashboardScreen()),
              );
            }
            return;
          } else {
            print('No user found with remembered phone number: $rememberedPhone');
          }
        }
      }
      
      // No valid session found, go to login screen
      print('No valid session found, navigating to login screen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e, stackTrace) {
      print('=== SPLASH SCREEN ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      print('==========================');
      
      // Use the error reporter to handle the error
      ErrorReporter.reportError(e, stackTrace, context: 'App Initialization');
      
      // If there's an error, navigate to login screen
      print('Navigating to Login Screen due to error');
      
      String errorMessage = ErrorReporter.getErrorMessage(e);
      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red,
      );
      
      // Small delay to show the error message
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('SplashScreen build called');
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E88E5), // Royal Blue
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work,
                size: 80,
                color: Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Worker Management',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Professional Solution',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ),
          ],
        ),
      ),
    );
  }
}