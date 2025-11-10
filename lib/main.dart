import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/session_manager.dart';
import 'providers/user_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/advance_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/login_status_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/hybrid_database_provider.dart';
import 'services/notification_service.dart';
import 'services/database_helper.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize notification service
  await NotificationService().init();
  
  // Initialize session manager
  await SessionManager().init();
  
  // Force database upgrade to ensure all columns exist
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.forceUpgrade();
    print('Database upgrade completed successfully');
  } catch (e) {
    print('Error during database upgrade: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          return UserProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return AttendanceProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return AdvanceProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return SalaryProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return LoginStatusProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return NotificationProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return HybridDatabaseProvider();
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worker Management App',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E88E5), // Royal Blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Royal Blue
        ),
        useMaterial3: true,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}