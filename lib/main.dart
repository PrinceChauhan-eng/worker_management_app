import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/session_manager.dart';
import 'providers/user_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/advance_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/login_status_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/hybrid_database_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qhjkngudpxrzldacxlpx.supabase.co',
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoamtuZ3VkcHhyemxkYWN4bHB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NTk2NjAsImV4cCI6MjA3ODMzNTY2MH0.GlY_-LZSR7nxx1wllMGnJuDu4oxw629LMBm_2XaOufg'),
  );

  // Add Supabase authentication state change listener
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;

    if (event == AuthChangeEvent.signedIn) {
      // user logged in successfully after redirect
      print("User signed in");
    }

    if (event == AuthChangeEvent.signedOut) {
      print("User signed out");
    }
  });

  // Initialize notification service
  await NotificationService().init();
  
  // Initialize session manager
  await SessionManager().init();
  
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