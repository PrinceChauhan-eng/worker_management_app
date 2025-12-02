import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/error_reporter.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';
import '../services/users_service.dart';
import '../services/session_manager.dart';

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

      // Replace the route guard logic with direct session management
      final savedId = await SessionManager().getCurrentUserId();

      if (savedId != null) {
        final userData = await UsersService().getUser(savedId);
        if (userData != null) {
          final user = User.fromMap(userData);

          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.currentUser = user;
          userProvider.notifyListeners();

          if (!mounted) return;

          if (user.role == "admin") {
            Navigator.pushReplacementNamed(context, "/admin_dashboard");
          } else {
            Navigator.pushReplacementNamed(context, "/worker_dashboard");
          }
        } else {
          Navigator.pushReplacementNamed(context, "/login");
        }
      } else {
        Navigator.pushReplacementNamed(context, "/login");
      }
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
      
      Navigator.pushReplacementNamed(context, "/login");
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