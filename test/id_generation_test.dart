import 'package:flutter_test/flutter_test.dart';
import 'package:worker_managment_app/models/advance.dart';
import 'package:worker_managment_app/models/attendance.dart';
import 'package:worker_managment_app/models/user.dart';

void main() {
  group('Model toMap() methods', () {
    test('Advance model toMap() includes id when null', () {
      final advance = Advance(
        workerId: 1,
        amount: 1000.0,
        date: '2025-11-10',
        purpose: 'Medical',
        note: 'Medical emergency',
        status: 'pending',
      );
      
      final map = advance.toMap();
      // Should include id in the map even when it's null
      expect(map.containsKey('id'), true);
      expect(map['id'], null);
    });
    
    test('Attendance model toMap() includes id when null', () {
      final attendance = Attendance(
        workerId: 1,
        date: '2025-11-10',
        inTime: '09:00',
        outTime: '17:00',
        present: true,
      );
      
      final map = attendance.toMap();
      // Should include id in the map even when it's null
      expect(map.containsKey('id'), true);
      expect(map['id'], null);
    });
    
    test('User model toMap() includes id when null', () {
      final user = User(
        name: 'Test User',
        phone: '1234567890',
        password: 'password123',
        role: 'worker',
        wage: 500.0,
        joinDate: '2025-11-10',
      );
      
      final map = user.toMap();
      // Should include id in the map even when it's null
      expect(map.containsKey('id'), true);
      expect(map['id'], null);
    });
  });
}