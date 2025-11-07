import '../models/salary.dart';
import '../services/database_helper.dart';
import 'base_provider.dart';

class SalaryProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Salary> _salaries = [];
  List<Salary> get salaries => _salaries;

  Future<void> loadSalaries() async {
    setState(ViewState.busy);
    _salaries = await _dbHelper.getSalaries();
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<void> loadSalariesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    _salaries = await _dbHelper.getSalariesByWorkerId(workerId);
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(int workerId, String month) async {
    return await _dbHelper.getSalaryByWorkerIdAndMonth(workerId, month);
  }

  Future<List<Salary>> getPaidSalaries() async {
    return await _dbHelper.getPaidSalaries();
  }

  Future<List<Salary>> getPaidSalariesByMonth(String month) async {
    return await _dbHelper.getPaidSalariesByMonth(month);
  }

  Future<bool> addSalary(Salary salary) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.insertSalary(salary);
      await loadSalaries();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> updateSalary(Salary salary) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.updateSalary(salary);
      await loadSalaries();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> deleteSalary(int id) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.deleteSalary(id);
      await loadSalaries();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }
}