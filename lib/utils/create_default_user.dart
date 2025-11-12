import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/users_service.dart';
import '../utils/password_utils.dart';

/// Utility script to create a default admin user for testing
/// Run this script once to create a default admin user in Supabase

Future<void> createDefaultAdminUser() async {
  try {
    print('Creating default admin user...');
    
    final usersService = UsersService();
    
    // Create default admin user data
    final adminUserData = {
      'name': 'Admin User',
      'phone': '9876543210',
      'email': 'admin@example.com',
      'password': PasswordUtils.hashPassword('admin123'), // Hash the password
      'role': 'admin',
      'wage': 0.0,
      'join_date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
    };
    
    // Insert the user into Supabase
    final userId = await usersService.insertUser(adminUserData);
    
    print('✅ Default admin user created successfully!');
    print('User ID: $userId');
    print('Login credentials:');
    print('  Phone/Email: admin@example.com or 9876543210');
    print('  Password: admin123');
    print('  Role: admin');
    
  } catch (e) {
    print('❌ Error creating default admin user: $e');
  }
}

// For testing worker user
Future<void> createDefaultWorkerUser() async {
  try {
    print('Creating default worker user...');
    
    final usersService = UsersService();
    
    // Create default worker user data
    final workerUserData = {
      'name': 'Worker User',
      'phone': '9876543211',
      'email': 'worker@example.com',
      'password': PasswordUtils.hashPassword('worker123'), // Hash the password
      'role': 'worker',
      'wage': 500.0,
      'join_date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
      'designation': 'General Worker',
    };
    
    // Insert the user into Supabase
    final userId = await usersService.insertUser(workerUserData);
    
    print('✅ Default worker user created successfully!');
    print('User ID: $userId');
    print('Login credentials:');
    print('  Phone/Email: worker@example.com or 9876543211');
    print('  Password: worker123');
    print('  Role: worker');
    
  } catch (e) {
    print('❌ Error creating default worker user: $e');
  }
}

void main() async {
  // Initialize Supabase (same as in main.dart)
  await Supabase.initialize(
    url: 'https://qhjkngudpxrzldacxlpx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoamtuZ3VkcHhyemxkYWN4bHB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NTk2NjAsImV4cCI6MjA3ODMzNTY2MH0.GlY_-LZSR7nxx1wllMGnJuDu4oxw629LMBm_2XaOufg',
  );
  
  print('Supabase initialized');
  
  // Create default users
  await createDefaultAdminUser();
  await createDefaultWorkerUser();
  
  print('All default users created. You can now login to the app.');
}