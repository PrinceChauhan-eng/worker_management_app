import '../models/salary.dart';
import '../services/database_helper.dart';
import 'base_provider.dart';
import '../utils/logger.dart';

class SalaryProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Salary> _salaries = [];
  List<Salary> get salaries => _salaries;

  Future<void> loadSalaries() async {
    setState(ViewState.busy);
    try {
      Logger.info('Loading salaries...');
      _salaries = await _dbHelper.getSalaries();
      Logger.info('Loaded ${_salaries.length} salaries');
      setState(ViewState.idle);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error loading salaries: $e', e, stackTrace);
      setState(ViewState.idle);
      notifyListeners();
      rethrow;
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(int workerId, String month) async {
    try {
      Logger.info('Getting salary for worker ID: $workerId and month: $month');
      return await _dbHelper.getSalaryByWorkerIdAndMonth(workerId, month);
    } catch (e, stackTrace) {
      Logger.error('Error getting salary by worker ID and month: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<void> loadSalariesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    try {
      Logger.info('Loading salaries for worker ID: $workerId');
      _salaries = await _dbHelper.getSalariesByWorkerId(workerId);
      Logger.info('Loaded ${_salaries.length} salaries for worker ID: $workerId');
      setState(ViewState.idle);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error loading salaries by worker ID: $e', e, stackTrace);
      setState(ViewState.idle);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Salary>> getPaidSalaries() async {
    try {
      Logger.info('Getting paid salaries...');
      return await _dbHelper.getPaidSalaries();
    } catch (e, stackTrace) {
      Logger.error('Error getting paid salaries: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Salary>> getPaidSalariesByMonth(String month) async {
    try {
      Logger.info('Getting paid salaries for month: $month');
      return await _dbHelper.getPaidSalariesByMonth(month);
    } catch (e, stackTrace) {
      Logger.error('Error getting paid salaries by month: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Salary>> getPaidSalariesByWorkerIdAndMonth(int workerId, String month) async {
    try {
      Logger.info('Getting paid salaries for worker ID: $workerId, month: $month');
      return await _dbHelper.getPaidSalariesByWorkerIdAndMonth(workerId, month);
    } catch (e, stackTrace) {
      Logger.error('Error getting paid salaries by worker ID and month: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> addSalary(Salary salary) async {
    setState(ViewState.busy);
    try {
      Logger.info('=== ADDING SALARY ===');
      Logger.debug('Salary data: ${salary.toMap()}');
      
      // Log individual fields for debugging
      Logger.debug('Salary fields:');
      Logger.debug('  ID: ${salary.id}');
      Logger.debug('  Worker ID: ${salary.workerId}');
      Logger.debug('  Month: ${salary.month}');
      Logger.debug('  Year: ${salary.year}');
      Logger.debug('  Total Days: ${salary.totalDays}');
      Logger.debug('  Present Days: ${salary.presentDays}');
      Logger.debug('  Absent Days: ${salary.absentDays}');
      Logger.debug('  Gross Salary: ${salary.grossSalary}');
      Logger.debug('  Total Advance: ${salary.totalAdvance}');
      Logger.debug('  Net Salary: ${salary.netSalary}');
      Logger.debug('  Total Salary: ${salary.totalSalary}');
      Logger.debug('  Paid: ${salary.paid}');
      Logger.debug('  Paid Date: ${salary.paidDate}');
      Logger.debug('  PDF URL: ${salary.pdfUrl}');
      
      // Validate salary object
      if (salary.workerId <= 0) {
        throw Exception('Invalid worker ID: ${salary.workerId}');
      }
      
      if (salary.month.isEmpty) {
        throw Exception('Month is required');
      }
      
      Logger.info('Inserting salary into database...');
      final result = await _dbHelper.insertSalary(salary);
      Logger.info('Salary inserted with result: $result');
      
      Logger.info('Reloading salaries...');
      await loadSalaries();
      Logger.info('Salaries reloaded successfully');
      
      setState(ViewState.idle);
      Logger.info('Salary added successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.error('!!! ERROR ADDING SALARY !!! Error type: ${e.runtimeType}, Error message: $e', e, stackTrace);
      setState(ViewState.idle);
      // Show a more detailed error message
      if (e.toString().contains('UNIQUE constraint failed')) {
        Logger.warning('This is a duplicate salary entry error');
      } else if (e.toString().contains('constraint')) {
        Logger.warning('This is likely a database constraint error');
      } else if (e.toString().contains('column')) {
        Logger.warning('This is likely a database column error');
      }
      return false;
    }
  }

  Future<bool> updateSalary(Salary salary) async {
    setState(ViewState.busy);
    try {
      Logger.info('Updating salary ID: ${salary.id}');
      await _dbHelper.updateSalary(salary);
      await loadSalaries();
      setState(ViewState.idle);
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error updating salary: $e', e, stackTrace);
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> deleteSalary(int id) async {
    setState(ViewState.busy);
    try {
      Logger.info('Deleting salary ID: $id');
      await _dbHelper.deleteSalary(id);
      await loadSalaries();
      setState(ViewState.idle);
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error deleting salary: $e', e, stackTrace);
      setState(ViewState.idle);
      return false;
    }
  }
}