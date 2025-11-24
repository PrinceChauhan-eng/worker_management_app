import '../models/salary.dart';
import '../models/user.dart';
import '../services/salary_service.dart';
import '../services/salary_calculation_service.dart';
import '../services/schema_refresher.dart'; // Add this import
import 'base_provider.dart';
import '../utils/logger.dart';

class SalaryProvider extends BaseProvider {
  final SalaryService _salaryService = SalaryService();
  final SalaryCalculationService _salaryCalculationService = SalaryCalculationService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  List<Salary> _salaries = [];
  List<Salary> get salaries => _salaries;

  Future<void> loadSalaries() async {
    setState(ViewState.busy);
    try {
      Logger.info('Loading salaries...');
      final salariesData = await _salaryService.all();
      _salaries = salariesData.map((data) => Salary.fromMap(data)).toList();
      Logger.info('Loaded ${_salaries.length} salaries');
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading salaries: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final salariesData = await _salaryService.all();
        _salaries = salariesData.map((data) => Salary.fromMap(data)).toList();
        Logger.info('Loaded ${_salaries.length} salaries');
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(int workerId, String month) async {
    try {
      Logger.info('Getting salary for worker ID: $workerId and month: $month');
      final salaryData = await _salaryService.byWorkerAndMonth(workerId, month);
      return salaryData != null ? Salary.fromMap(salaryData) : null;
    } catch (e) {
      Logger.error('Error getting salary by worker ID and month: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final salaryData = await _salaryService.byWorkerAndMonth(workerId, month);
        return salaryData != null ? Salary.fromMap(salaryData) : null;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        rethrow;
      }
    }
  }

  Future<void> loadSalariesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    try {
      Logger.info('Loading salaries for worker ID: $workerId');
      final salariesData = await _salaryService.byWorker(workerId);
      _salaries = salariesData.map((data) => Salary.fromMap(data)).toList();
      Logger.info('Loaded ${_salaries.length} salaries for worker ID: $workerId');
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading salaries by worker ID: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final salariesData = await _salaryService.byWorker(workerId);
        _salaries = salariesData.map((data) => Salary.fromMap(data)).toList();
        Logger.info('Loaded ${_salaries.length} salaries for worker ID: $workerId');
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<List<Salary>> getPaidSalaries() async {
    try {
      Logger.info('Getting paid salaries...');
      final salariesData = await _salaryService.paid();
      return salariesData.map((data) => Salary.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting paid salaries: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final salariesData = await _salaryService.paid();
        return salariesData.map((data) => Salary.fromMap(data)).toList();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        rethrow;
      }
    }
  }

  Future<List<Salary>> getPaidSalariesByMonth(String month) async {
    try {
      Logger.info('Getting paid salaries for month: $month');
      final salariesData = await _salaryService.paidByMonth(month);
      return salariesData.map((data) => Salary.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting paid salaries by month: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final salariesData = await _salaryService.paidByMonth(month);
        return salariesData.map((data) => Salary.fromMap(data)).toList();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        rethrow;
      }
    }
  }

  Future<List<Salary>> getPaidSalariesByWorkerIdAndMonth(int workerId, String month) async {
    try {
      Logger.info('Getting paid salaries for worker ID: $workerId, month: $month');
      final salariesData = await _salaryService.paidByWorkerAndMonth(workerId, month);
      return salariesData.map((data) => Salary.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting paid salaries by worker ID and month: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final salariesData = await _salaryService.paidByWorkerAndMonth(workerId, month);
        return salariesData.map((data) => Salary.fromMap(data)).toList();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        rethrow;
      }
    }
  }

  /// Calculate and generate automated salary for a worker
  Future<SalaryCalculationResult> calculateAutomatedSalary({
    required User worker,
    required String month,
  }) async {
    try {
      Logger.info('Calculating automated salary for worker ${worker.id} for month $month');
      return await _salaryCalculationService.calculateMonthlySalary(
        worker: worker,
        month: month,
      );
    } catch (e) {
      Logger.error('Error calculating automated salary: $e', e);
      rethrow;
    }
  }

  /// Generate salary record from calculation result
  Future<Salary> generateSalaryFromCalculation(SalaryCalculationResult result) async {
    try {
      Logger.info('Generating salary record from calculation');
      
      return Salary(
        workerId: result.workerId,
        month: result.month,
        totalDays: result.totalDays,
        presentDays: result.presentDays,
        absentDays: result.absentDays,
        grossSalary: result.grossSalary,
        totalAdvance: result.totalAdvance,
        netSalary: result.netSalary,
        totalSalary: result.netSalary,
        paid: false,
      );
    } catch (e) {
      Logger.error('Error generating salary from calculation: $e', e);
      rethrow;
    }
  }

  Future<bool> addSalary(Salary salary) async {
    setState(ViewState.busy);
    try {
      Logger.info('=== ADDING SALARY ===');
      Logger.info('Salary data: ${salary.toMap()}');
      
      // Log individual fields for debugging
      Logger.info('Salary fields:');
      Logger.info('  ID: ${salary.id}');
      Logger.info('  Worker ID: ${salary.workerId}');
      Logger.info('  Month: ${salary.month}');
      Logger.info('  Year: ${salary.year}');
      Logger.info('  Total Days: ${salary.totalDays}');
      Logger.info('  Present Days: ${salary.presentDays}');
      Logger.info('  Absent Days: ${salary.absentDays}');
      Logger.info('  Gross Salary: ${salary.grossSalary}');
      Logger.info('  Total Advance: ${salary.totalAdvance}');
      Logger.info('  Net Salary: ${salary.netSalary}');
      Logger.info('  Total Salary: ${salary.totalSalary}');
      Logger.info('  Paid: ${salary.paid}');
      Logger.info('  Paid Date: ${salary.paidDate}');
      Logger.info('  PDF URL: ${salary.pdfUrl}');
      
      // Validate salary object
      if (salary.workerId <= 0) {
        throw Exception('Invalid worker ID: ${salary.workerId}');
      }
      
      if (salary.month.isEmpty) {
        throw Exception('Month is required');
      }
      
      Logger.info('Inserting salary into database...');
      final result = await _salaryService.insert(salary.toMap());
      Logger.info('Salary inserted with result: $result');
      
      Logger.info('Reloading salaries...');
      await loadSalaries();
      Logger.info('Salaries reloaded successfully');
      
      setState(ViewState.idle);
      Logger.info('Salary added successfully');
      return true;
    } catch (e) {
      Logger.error('!!! ERROR ADDING SALARY !!! Error type: ${e.runtimeType}, Error message: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        Logger.info('Retrying salary insertion...');
        final result = await _salaryService.insert(salary.toMap());
        Logger.info('Salary inserted with result: $result');
        
        Logger.info('Reloading salaries...');
        await loadSalaries();
        Logger.info('Salaries reloaded successfully');
        
        setState(ViewState.idle);
        Logger.info('Salary added successfully');
        return true;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        // Show a more detailed error message
        if (e.toString().contains('UNIQUE constraint failed')) {
          Logger.warn('This is a duplicate salary entry error');
        } else if (e.toString().contains('constraint')) {
          Logger.warn('This is likely a database constraint error');
        } else if (e.toString().contains('column')) {
          Logger.warn('This is likely a database column error');
        }
        return false;
      }
    }
  }

  Future<bool> updateSalary(Salary salary) async {
    setState(ViewState.busy);
    try {
      Logger.info('Updating salary ID: ${salary.id}');
      Logger.info('Salary update data: ${salary.toMap()}');
      
      // Validate salary object
      if (salary.id == null) {
        throw Exception('Salary ID is required for update');
      }
      
      if (salary.workerId <= 0) {
        throw Exception('Invalid worker ID: ${salary.workerId}');
      }
      
      await _salaryService.updateById(salary.id!, salary.toMap());
      await loadSalaries();
      setState(ViewState.idle);
      Logger.info('Salary updated successfully');
      return true;
    } catch (e) {
      Logger.error('!!! ERROR UPDATING SALARY !!! Error type: ${e.runtimeType}, Error message: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        if (salary.id != null) {
          Logger.info('Retrying salary update for ID: ${salary.id}');
          await _salaryService.updateById(salary.id!, salary.toMap());
          await loadSalaries();
          setState(ViewState.idle);
          Logger.info('Salary updated successfully');
          return true;
        } else {
          setState(ViewState.idle);
          return false;
        }
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        
        // Show a more detailed error message
        if (e.toString().contains('constraint')) {
          Logger.warn('This is likely a database constraint error');
        } else if (e.toString().contains('column')) {
          Logger.warn('This is likely a database column error');
        }
        
        return false;
      }
    }
  }

  Future<void> markAsPaid(Salary s) async {
    if (s.id == null) throw Exception('Salary id is null');

    try {
      // ✅ Update the Supabase row
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await _salaryService.updateById(s.id!, {
        'paid': true,
        'paid_date': today,
      });

      // ✅ Reload updated salary row from Supabase
      final updatedRow =
          await _salaryService.byWorkerAndMonth(s.workerId, s.month);

      if (updatedRow != null) {
        final updatedSalary = Salary.fromMap(updatedRow);

        // ✅ Update local provider list
        final index = _salaries.indexWhere((x) => x.id == updatedSalary.id);
        if (index >= 0) {
          _salaries[index] = updatedSalary;
        }

        notifyListeners();
      }
    } catch (e) {
      Logger.error('!!! ERROR MARKING SALARY AS PAID !!! Error type: ${e.runtimeType}, Error message: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        // ✅ Update the Supabase row
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await _salaryService.updateById(s.id!, {
          'paid': true,
          'paid_date': today,
        });

        // ✅ Reload updated salary row from Supabase
        final updatedRow =
            await _salaryService.byWorkerAndMonth(s.workerId, s.month);

        if (updatedRow != null) {
          final updatedSalary = Salary.fromMap(updatedRow);

          // ✅ Update local provider list
          final index = _salaries.indexWhere((x) => x.id == updatedSalary.id);
          if (index >= 0) {
            _salaries[index] = updatedSalary;
          }

          notifyListeners();
        }
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        rethrow;
      }
    }
  }

  Future<bool> deleteSalary(int id) async {
    setState(ViewState.busy);
    try {
      Logger.info('Deleting salary ID: $id');
      await _salaryService.deleteById(id);
      await loadSalaries();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      Logger.error('Error deleting salary: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _salaryService.deleteById(id);
        await loadSalaries();
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        return false;
      }
    }
  }
}