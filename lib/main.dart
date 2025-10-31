import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/session_manager.dart';
import 'providers/user_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/advance_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/login_status_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing app...');
  // Initialize session manager
  await SessionManager().init();
  
  print('Initializing providers...');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('Creating UserProvider');
          return UserProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          print('Creating AttendanceProvider');
          return AttendanceProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          print('Creating AdvanceProvider');
          return AdvanceProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          print('Creating SalaryProvider');
          return SalaryProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          print('Creating LoginStatusProvider');
          return LoginStatusProvider();
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