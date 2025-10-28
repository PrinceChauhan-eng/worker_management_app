import '../models/advance.dart';
import '../services/database_helper.dart';
import 'base_provider.dart';

class AdvanceProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Advance> _advances = [];
  List<Advance> get advances => _advances;

  Future<void> loadAdvances() async {
    setState(ViewState.busy);
    _advances = await _dbHelper.getAdvances();
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<void> loadAdvancesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    _advances = await _dbHelper.getAdvancesByWorkerId(workerId);
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<double> getTotalAdvanceByWorkerId(int workerId) async {
    return await _dbHelper.getTotalAdvanceByWorkerId(workerId);
  }

  Future<bool> addAdvance(Advance advance) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.insertAdvance(advance);
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> updateAdvance(Advance advance) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.updateAdvance(advance);
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> deleteAdvance(int id) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.deleteAdvance(id);
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }
}