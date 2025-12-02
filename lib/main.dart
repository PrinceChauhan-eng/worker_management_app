import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/session_manager.dart';
import 'providers/user_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/advance_provider.dart';
import 'providers/salary_provider.dart';
import 'providers/login_status_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/activity_provider.dart';
import 'services/notification_service.dart';
import 'services/database_updater.dart';
import 'services/location_table_updater.dart';
import 'screens/splash_screen.dart';
import 'screens/my_attendance_screen.dart';
import 'screens/my_salary_screen.dart';
import 'screens/my_advance_screen.dart';
import 'screens/admin_profile_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin/profile/admin_profile_edit_screen.dart';
import 'screens/worker/profile/worker_profile_edit_screen.dart';
import 'screens/auth/new_login_screen.dart';
import 'screens/auth/app_splash_screen.dart';
import 'screens/worker_dashboard/worker_dashboard_screen.dart';
import 'utils/logger.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qhjkngudpxrzldacxlpx.supabase.co',
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoamtuZ3VkcHhyemxkYWN4bHB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NTk2NjAsImV4cCI6MjA3ODMzNTY2MH0.GlY_-LZSR7nxx1wllMGnJuDu4oxw629LMBm_2XaOufg'),
  );

  // Initialize notification service
  await NotificationService().init();
  
  // Initialize session manager
  await SessionManager().init();
  
  // Run database migrations
  try {
    final databaseUpdater = DatabaseUpdater();
    await databaseUpdater.runMigrations();
    Logger.info('Database migrations completed successfully');
  } catch (e) {
    Logger.error('Failed to run database migrations: $e', e);
    // Don't crash the app if migrations fail, but log the error
  }
  
  // Run location table synchronization
  try {
    final locationTableUpdater = LocationTableUpdater();
    await locationTableUpdater.syncLocationTables();
    Logger.info('Location table synchronization completed successfully');
  } catch (e) {
    Logger.error('Failed to sync location tables: $e', e);
    // Don't crash the app if location table sync fails, but log the error
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          return UserProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return AuthProvider();
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
          return ThemeProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          return ActivityProvider();
        }),
      ],
      child: AppInitializer(child: const MyApp()),
    ),
  );
}

class AppInitializer extends StatefulWidget {
  final Widget child;
  const AppInitializer({required this.child, super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      // restore custom session
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Worker Management App',
          theme: AppTheme.lightTheme.copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: themeProvider.mode,
          initialRoute: "/splash", // Set splash screen as initial route
          routes: {
            '/splash': (context) => const AppSplashScreen(), // Add splash route
            '/my_attendance': (context) => const MyAttendanceScreen(),
            '/my_salary': (context) => const MySalaryScreen(),
            '/my_advance': (context) => const MyAdvanceScreen(),
            '/admin_profile': (context) => const AdminProfileScreen(),
            '/admin_dashboard': (context) => const AdminDashboardScreen(),
            '/admin_profile_edit': (context) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final user = userProvider.currentUser;
              if (user == null) {
                throw Exception('User not found');
              }
              return AdminProfileEditScreen();
            },
            '/worker-profile-edit': (context) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final user = userProvider.currentUser;
              if (user == null) {
                throw Exception('User not found');
              }
              return const WorkerProfileEditScreen();
            },
            '/worker-dashboard': (context) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final user = userProvider.currentUser;
              if (user == null) {
                throw Exception('User not found');
              }
              return const WorkerDashboardScreen(openAttendanceDetails: false);
            },
            '/worker_dashboard': (context) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final user = userProvider.currentUser;
              if (user == null) {
                throw Exception('User not found');
              }
              return const WorkerDashboardScreen(openAttendanceDetails: false);
            },
            '/login': (context) => const NewLoginScreen(),
          },
        );
      },
    );
  }
}