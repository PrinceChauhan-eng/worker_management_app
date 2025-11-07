import 'package:flutter_test/flutter_test.dart';
import 'package:worker_managment_app/models/salary.dart';
import 'package:worker_managment_app/models/user.dart';

void main() {
  group('Salary Processing Tests', () {
    test('Salary model creation with all fields', () {
      final salary = Salary(
        id: 1,
        workerId: 101,
        month: 'January',
        year: '2023',
        totalDays: 31,
        presentDays: 25,
        absentDays: 6,
        grossSalary: 12500.0,
        totalAdvance: 2000.0,
        netSalary: 10500.0,
        paid: true,
        paidDate: '2023-01-31',
      );

      expect(salary.id, 1);
      expect(salary.workerId, 101);
      expect(salary.month, 'January');
      expect(salary.year, '2023');
      expect(salary.totalDays, 31);
      expect(salary.presentDays, 25);
      expect(salary.absentDays, 6);
      expect(salary.grossSalary, 12500.0);
      expect(salary.totalAdvance, 2000.0);
      expect(salary.netSalary, 10500.0);
      expect(salary.paid, true);
      expect(salary.paidDate, '2023-01-31');
    });

    test('Salary model creation with minimal fields', () {
      final salary = Salary(
        workerId: 102,
        month: 'February',
        totalDays: 28,
        paid: false,
      );

      expect(salary.workerId, 102);
      expect(salary.month, 'February');
      expect(salary.totalDays, 28);
      expect(salary.paid, false);
    });

    test('Salary toMap and fromMap conversion', () {
      final salary = Salary(
        id: 2,
        workerId: 103,
        month: 'March',
        year: '2023',
        totalDays: 31,
        presentDays: 28,
        absentDays: 3,
        grossSalary: 14000.0,
        totalAdvance: 1500.0,
        netSalary: 12500.0,
        paid: true,
        paidDate: '2023-03-31',
      );

      final map = salary.toMap();
      final salaryFromMap = Salary.fromMap(map);

      expect(salaryFromMap.id, salary.id);
      expect(salaryFromMap.workerId, salary.workerId);
      expect(salaryFromMap.month, salary.month);
      expect(salaryFromMap.year, salary.year);
      expect(salaryFromMap.totalDays, salary.totalDays);
      expect(salaryFromMap.presentDays, salary.presentDays);
      expect(salaryFromMap.absentDays, salary.absentDays);
      expect(salaryFromMap.grossSalary, salary.grossSalary);
      expect(salaryFromMap.totalAdvance, salary.totalAdvance);
      expect(salaryFromMap.netSalary, salary.netSalary);
      expect(salaryFromMap.paid, salary.paid);
      expect(salaryFromMap.paidDate, salary.paidDate);
    });

    test('User model creation', () {
      final user = User(
        id: 1,
        name: 'Test Worker',
        phone: '9876543210',
        password: 'test123',
        role: 'worker',
        wage: 500.0,
        joinDate: '2023-01-01',
      );

      expect(user.id, 1);
      expect(user.name, 'Test Worker');
      expect(user.phone, '9876543210');
      expect(user.password, 'test123');
      expect(user.role, 'worker');
      expect(user.wage, 500.0);
      expect(user.joinDate, '2023-01-01');
    });
  });
}