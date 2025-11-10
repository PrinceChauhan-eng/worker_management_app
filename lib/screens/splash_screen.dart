import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/error_reporter.dart';
import '../services/database_helper.dart';
import '../services/session_manager.dart';
import '../providers/user_provider.dart';
import '../models/user.dart'; // Import User model
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

      // Ensure database is initialized first
      print('Initializing database...');
      final dbHelper = DatabaseHelper();
      await dbHelper.initDB();
      
      // Force database upgrade to ensure all columns exist
      await dbHelper.forceUpgrade();
      
      print('Database initialized successfully');

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
        final dbHelper = DatabaseHelper();
        final user = await dbHelper.getUser(currentUserId);
        
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
        final dbHelper = DatabaseHelper();
        final user = await dbHelper.getUser(userId);
        
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
          final dbHelper = DatabaseHelper();
          
          // Try to find user by phone (we'll need to get all users with this phone and check)
          var client = await dbHelper.db;
          var results = await client.query(
            'users',
            where: 'phone = ?',
            whereArgs: [rememberedPhone],
          );
          
          if (results.isNotEmpty) {
            final user = User.fromMap(results.first);
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
            // App Logo (using Icon as placeholder)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work,
                size: 80,
                color: Color(0xFF1E88E5), // Royal Blue
              ),
            ),
            const SizedBox(height: 30),
            // App Name
            Text(
              'Worker Management',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Manage your workforce efficiently',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 50),
            // Progress indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}