import '../models/advance.dart';
import '../services/database_helper.dart';
import '../providers/hybrid_database_provider.dart';
import 'base_provider.dart';
import '../utils/logger.dart';

class AdvanceProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final HybridDatabaseProvider _hybridProvider = HybridDatabaseProvider();
  
  List<Advance> _advances = [];
  List<Advance> get advances => _advances;

  Future<void> loadAdvances() async {
    setState(ViewState.busy);
    try {
      // Try to get advances from hybrid provider (will fall back to local if Firebase not available)
      _advances = await _hybridProvider.getAdvances();
      Logger.info('Loaded ${_advances.length} advances from database');
    } catch (e) {
      Logger.error('Error loading advances: $e', e);
      // Fallback to local database directly
      try {
        _advances = await _dbHelper.getAdvances();
        Logger.info('Loaded ${_advances.length} advances from local database (fallback)');
      } catch (e2) {
        Logger.error('Error loading advances from local database: $e2', e2);
        _advances = [];
      }
    }
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<void> loadAdvancesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    try {
      // Try to get advances from hybrid provider (will fall back to local if Firebase not available)
      _advances = await _hybridProvider.getAdvancesByWorkerId(workerId);
      Logger.info('Loaded ${_advances.length} advances for worker ID: $workerId');
    } catch (e) {
      Logger.error('Error loading advances by worker ID: $e', e);
      // Fallback to local database directly
      try {
        _advances = await _dbHelper.getAdvancesByWorkerId(workerId);
        Logger.info('Loaded ${_advances.length} advances for worker ID: $workerId from local database (fallback)');
      } catch (e2) {
        Logger.error('Error loading advances by worker ID from local database: $e2', e2);
        _advances = [];
      }
    }
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<List<Advance>> getAdvancesByWorkerIdAndMonth(int workerId, String month) async {
    try {
      return await _dbHelper.getAdvancesByWorkerIdAndMonth(workerId, month);
    } catch (e) {
      Logger.error('Error getting advances by worker ID and month: $e', e);
      return [];
    }
  }

  Future<double> getTotalAdvanceByWorkerId(int workerId) async {
    try {
      return await _dbHelper.getTotalAdvanceByWorkerId(workerId);
    } catch (e) {
      Logger.error('Error getting total advance by worker ID: $e', e);
      return 0.0;
    }
  }

  Future<bool> addAdvance(Advance advance) async {
    setState(ViewState.busy);
    try {
      int id = await _hybridProvider.insertAdvance(advance);
      Logger.info('Inserted advance with ID: $id');
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      Logger.error('Error inserting advance: $e', e);
      
      // Provide more specific error messages
      if (e.toString().contains('no such column')) {
        Logger.error('Database schema issue: Missing columns in advance table');
      } else if (e.toString().contains('Firebase')) {
        Logger.warning('Firebase service error - falling back to local storage');
      }
      
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> updateAdvance(Advance advance) async {
    setState(ViewState.busy);
    try {
      if (advance.id == null) {
        Logger.warning('Cannot update advance: ID is null');
        setState(ViewState.idle);
        return false;
      }
      
      int rowsAffected = await _hybridProvider.updateAdvance(advance);
      Logger.info('Updated advance ID: ${advance.id}, rows affected: $rowsAffected');
      
      if (rowsAffected > 0) {
        await loadAdvances();
        setState(ViewState.idle);
        return true;
      } else {
        Logger.warning('No rows affected when updating advance ID: ${advance.id}');
        setState(ViewState.idle);
        return false;
      }
    } catch (e) {
      Logger.error('Error updating advance: $e', e);
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> deleteAdvance(int id) async {
    setState(ViewState.busy);
    try {
      await _hybridProvider.deleteAdvance(id);
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      Logger.error('Error deleting advance: $e', e);
      setState(ViewState.idle);
      return false;
    }
  }
}