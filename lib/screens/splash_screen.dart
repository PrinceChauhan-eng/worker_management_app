import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/session_manager.dart';
import '../services/database_helper.dart';
import '../providers/user_provider.dart';
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

  _navigateToNextScreen() async {
    print('Splash screen navigation started');
    try {
      await Future.delayed(const Duration(seconds: 2));
      print('Splash screen delay completed');
      
      // Ensure database is initialized first
      print('Initializing database...');
      final dbHelper = DatabaseHelper();
      await dbHelper.initDB();
      print('Database initialized successfully');
      
      SessionManager sessionManager = SessionManager();
      print('Checking if user is logged in...');
      bool isLoggedIn = await sessionManager.isLoggedIn();
      print('Is user logged in: $isLoggedIn');
      
      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }
      
      if (isLoggedIn) {
        try {
          print('User is logged in, getting user data...');
          int userId = await sessionManager.getUserId();
          String userRole = await sessionManager.getUserRole();
          print('Logged in user ID: $userId, role: $userRole');
          
          if (userId <= 0) {
            print('Invalid user ID, navigating to login');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
            return;
          }
          
          // Load user from database and set in provider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final user = await dbHelper.getUser(userId);
          
          if (user != null) {
            print('User loaded from database: ${user.name}');
            userProvider.setCurrentUser(user);
            
            if (userRole == 'admin') {
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
          } else {
            print('User not found in database, logging out');
            await sessionManager.logout();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } catch (e) {
          print('Error retrieving user data from session: $e');
          // If there's an error, navigate to login screen
          print('Navigating to Login Screen due to error');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        print('User is not logged in, navigating to Login Screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error in splash screen navigation: $e');
      // If there's an error, navigate to login screen
      print('Navigating to Login Screen due to error');
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