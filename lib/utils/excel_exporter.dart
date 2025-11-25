import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import '../models/user.dart';
import '../services/attendance_service.dart';
import '../services/users_service.dart';
import '../services/advance_service.dart';
import '../services/salary_calculation_service.dart';
import '../utils/logger.dart';

class ExcelExporter {
  final AttendanceService _attendanceService = AttendanceService();
  final UsersService _usersService = UsersService();
  final AdvanceService _advanceService = AdvanceService();
  final SalaryCalculationService _salaryService = SalaryCalculationService();

  /// Export salary data to Excel for a given month
  Future<String> exportSalaryToExcel(String month) async {
    try {
      Logger.info('Exporting salary data to Excel for month: $month');
      
      // Get all workers
      final workersData = await _usersService.getWorkersForCurrentAdmin();
      final workers = workersData.map((data) => User.fromMap(data)).toList();
      
      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Salary Report'];
      
      // Add header row
      sheet.appendRow([
        'Worker ID',
        'Name',
        'Phone',
        'Total Days',
        'Present Days',
        'Half Days',
        'Absent Days',
        'Total Hours',
        'Overtime Hours',
        'Gross Salary',
        'Total Advance',
        'Net Salary',
      ]);
      
      // Process each worker
      for (var worker in workers) {
        try {
          // Calculate salary for this worker
          final salaryResult = await _salaryService.calculateMonthlySalary(
            worker: worker,
            month: month,
          );
          
          // Add row to Excel sheet
          sheet.appendRow([
            worker.id!,
            worker.name,
            worker.phone ?? '',
            salaryResult.totalDays,
            salaryResult.presentDays,
            salaryResult.halfDays,
            salaryResult.absentDays,
            salaryResult.totalHoursWorked.toStringAsFixed(2),
            salaryResult.overtimeHours.toStringAsFixed(2),
            salaryResult.grossSalary.toStringAsFixed(2),
            salaryResult.totalAdvance.toStringAsFixed(2),
            salaryResult.netSalary.toStringAsFixed(2),
          ]);
        } catch (e) {
          Logger.error('Error calculating salary for worker ${worker.id}: $e', e);
          // Add row with error indication
          sheet.appendRow([
            worker.id!,
            worker.name,
            worker.phone ?? '',
            'Error',
            'Error',
            'Error',
            'Error',
            'Error',
            'Error',
            'Error',
            'Error',
            'Error',
          ]);
        }
      }
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/salary_$month.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);
      
      Logger.info('Salary Excel exported successfully to: $filePath');
      return filePath;
    } catch (e) {
      Logger.error('Error exporting salary to Excel: $e', e);
      rethrow;
    }
  }
}