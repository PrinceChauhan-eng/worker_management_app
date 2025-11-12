import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worker_managment_app/services/users_service.dart';
import 'package:worker_managment_app/services/attendance_service.dart';
import 'package:worker_managment_app/services/advance_service.dart';
import 'package:worker_managment_app/services/salary_service.dart';
import 'package:worker_managment_app/services/login_service.dart';

void main() {
  group('Supabase Integration Tests', () {
    late UsersService usersService;
    late AttendanceService attendanceService;
    late AdvanceService advanceService;
    late SalaryService salaryService;
    late LoginService loginService;

    setUpAll(() async {
      // Initialize Supabase with the same configuration as main.dart
      await Supabase.initialize(
        url: 'https://qhjkngudpxrzldacxlpx.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoamtuZ3VkcHhyemxkYWN4bHB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3NTk2NjAsImV4cCI6MjA3ODMzNTY2MH0.GlY_-LZSR7nxx1wllMGnJuDu4oxw629LMBm_2XaOufg',
      );
      
      // Initialize services
      usersService = UsersService();
      attendanceService = AttendanceService();
      advanceService = AdvanceService();
      salaryService = SalaryService();
      loginService = LoginService();
    });

    test('Users Service - Get All Users', () async {
      // This should not throw an exception
      final users = await usersService.getUsers();
      expect(users, isA<List<Map<String, dynamic>>>());
      // Log the number of users for debugging
      print('Found ${users.length} users in database');
    });

    test('Attendance Service - Get All Attendance Records', () async {
      // This should not throw an exception
      final attendanceRecords = await attendanceService.all();
      expect(attendanceRecords, isA<List<Map<String, dynamic>>>());
      print('Found ${attendanceRecords.length} attendance records in database');
    });

    test('Advance Service - Get All Advances', () async {
      // This should not throw an exception
      final advances = await advanceService.all();
      expect(advances, isA<List<Map<String, dynamic>>>());
      print('Found ${advances.length} advances in database');
    });

    test('Salary Service - Get All Salaries', () async {
      // This should not throw an exception
      final salaries = await salaryService.all();
      expect(salaries, isA<List<Map<String, dynamic>>>());
      print('Found ${salaries.length} salaries in database');
    });

    test('Login Service - Get All Login Statuses', () async {
      // This should not throw an exception
      final loginStatuses = await loginService.statuses();
      expect(loginStatuses, isA<List<Map<String, dynamic>>>());
      print('Found ${loginStatuses.length} login statuses in database');
    });
  });
}