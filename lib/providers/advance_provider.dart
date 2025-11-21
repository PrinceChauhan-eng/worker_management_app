import '../models/advance.dart';
import '../services/advance_service.dart';
import '../services/schema_refresher.dart'; // Add this import
import 'base_provider.dart';
import '../utils/logger.dart';

class AdvanceProvider extends BaseProvider {
  final AdvanceService _advanceService = AdvanceService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher(); // Add this
  
  List<Advance> _advances = [];
  List<Advance> get advances => _advances;

  Future<void> loadAdvances() async {
    setState(ViewState.busy);
    try {
      // Try to get advances from Supabase service
      final advancesData = await _advanceService.all();
      _advances = advancesData.map((data) => Advance.fromMap(data)).toList();
      Logger.info('Loaded ${_advances.length} advances from database');
    } catch (e) {
      Logger.error('Error loading advances: $e', e);
      // Fallback to Supabase service
      try {
        final advancesData = await _advanceService.all();
        _advances = advancesData.map((data) => Advance.fromMap(data)).toList();
        Logger.info('Loaded ${_advances.length} advances from Supabase (fallback)');
      } catch (e2) {
        Logger.error('Error loading advances from Supabase: $e2', e2);
        // Try to fix schema errors
        await _schemaRefresher.tryFixSchemaError(e2);
        
        // Retry after schema refresh
        try {
          await Future.delayed(const Duration(seconds: 2));
          final advancesData = await _advanceService.all();
          _advances = advancesData.map((data) => Advance.fromMap(data)).toList();
          Logger.info('Loaded ${_advances.length} advances from Supabase (fallback)');
        } catch (retryError) {
          Logger.error('Retry failed: $retryError', retryError);
          _advances = [];
        }
      }
    }
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<void> loadAdvancesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    try {
      // Try to get advances from Supabase service
      final advancesData = await _advanceService.byWorker(workerId);
      _advances = advancesData.map((data) => Advance.fromMap(data)).toList();
      Logger.info('Loaded ${_advances.length} advances for worker ID: $workerId');
    } catch (e) {
      Logger.error('Error loading advances by worker ID: $e', e);
      // Fallback to Supabase service
      try {
        final advancesData = await _advanceService.byWorker(workerId);
        _advances = advancesData.map((data) => Advance.fromMap(data)).toList();
        Logger.info('Loaded ${_advances.length} advances for worker ID: $workerId from Supabase (fallback)');
      } catch (e2) {
        Logger.error('Error loading advances by worker ID from Supabase: $e2', e2);
        // Try to fix schema errors
        await _schemaRefresher.tryFixExtendedSchemaError(e2);
        
        // Retry after schema refresh
        try {
          await Future.delayed(const Duration(seconds: 2));
          final advancesData = await _advanceService.byWorker(workerId);
          _advances = advancesData.map((data) => Advance.fromMap(data)).toList();
          Logger.info('Loaded ${_advances.length} advances for worker ID: $workerId from Supabase (fallback)');
        } catch (retryError) {
          Logger.error('Retry failed: $retryError', retryError);
          _advances = [];
        }
      }
    }
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<List<Advance>> getAdvancesByWorkerIdAndMonth(int workerId, String month) async {
    try {
      final advancesData = await _advanceService.byWorkerAndMonth(workerId, month);
      return advancesData.map((data) => Advance.fromMap(data)).toList();
    } catch (e) {
      Logger.error('Error getting advances by worker ID and month: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final advancesData = await _advanceService.byWorkerAndMonth(workerId, month);
        return advancesData.map((data) => Advance.fromMap(data)).toList();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        return [];
      }
    }
  }

  Future<double> getTotalAdvanceByWorkerId(int workerId) async {
    try {
      final advancesData = await _advanceService.byWorker(workerId);
      final advances = advancesData.map((data) => Advance.fromMap(data)).toList();
      double total = 0.0;
      for (var advance in advances) {
        total += advance.amount;
      }
      return total;
    } catch (e) {
      Logger.error('Error getting total advance by worker ID: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final advancesData = await _advanceService.byWorker(workerId);
        final advances = advancesData.map((data) => Advance.fromMap(data)).toList();
        double total = 0.0;
        for (var advance in advances) {
          total += advance.amount;
        }
        return total;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        return 0.0;
      }
    }
  }

  Future<bool> addAdvance(Advance advance) async {
    setState(ViewState.busy);
    try {
      int id = await _advanceService.insert(advance.toMap());
      Logger.info('Inserted advance with ID: $id');
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      Logger.error('Error inserting advance: $e', e);
      
      // Provide more specific error messages
      if (e.toString().contains('no such column')) {
        Logger.error('Database schema issue: Missing columns in advance table', null);
      } else if (e.toString().contains('Firebase')) {
        Logger.warn('Firebase service error - falling back to local storage');
      } else {
        // Try to fix schema errors
        await _schemaRefresher.tryFixExtendedSchemaError(e);
        
        // Retry after schema refresh
        try {
          await Future.delayed(const Duration(seconds: 2));
          int id = await _advanceService.insert(advance.toMap());
          Logger.info('Inserted advance with ID: $id');
          await loadAdvances();
          setState(ViewState.idle);
          return true;
        } catch (retryError) {
          Logger.error('Retry failed: $retryError', retryError);
        }
      }
      
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> updateAdvance(Advance advance) async {
    setState(ViewState.busy);
    try {
      if (advance.id == null) {
        Logger.warn('Cannot update advance: ID is null');
        setState(ViewState.idle);
        return false;
      }
      
      Logger.info('Updating advance ID: ${advance.id} with data: ${advance.toMap()}');
      await _advanceService.updateById(advance.id!, advance.toMap());
      Logger.info('Updated advance ID: ${advance.id}');
      
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e, stackTrace) {
      Logger.error('!!! ERROR UPDATING ADVANCE !!! Error type: ${e.runtimeType}, Error message: $e', e);
      setState(ViewState.idle);
      
      // Show a more detailed error message
      if (e.toString().contains('constraint')) {
        Logger.warn('This is likely a database constraint error');
      } else if (e.toString().contains('column')) {
        Logger.warn('This is likely a database column error');
      } else {
        // Try to fix schema errors
        await _schemaRefresher.tryFixSchemaError(e);
        
        // Retry after schema refresh
        try {
          await Future.delayed(const Duration(seconds: 2));
          if (advance.id != null) {
            Logger.info('Retrying update of advance ID: ${advance.id} with data: ${advance.toMap()}');
            await _advanceService.updateById(advance.id!, advance.toMap());
            Logger.info('Updated advance ID: ${advance.id}');
            
            await loadAdvances();
            setState(ViewState.idle);
            return true;
          }
        } catch (retryError) {
          Logger.error('Retry failed: $retryError', retryError);
        }
      }
      
      return false;
    }
  }

  Future<bool> deleteAdvance(int id) async {
    setState(ViewState.busy);
    try {
      await _advanceService.deleteById(id);
      await loadAdvances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      Logger.error('Error deleting advance: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _advanceService.deleteById(id);
        await loadAdvances();
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