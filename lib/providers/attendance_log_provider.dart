import '../models/attendance_log.dart';
import '../services/attendance_log_service.dart';
import '../services/schema_refresher.dart';
import 'base_provider.dart';

class AttendanceLogProvider extends BaseProvider {
  final AttendanceLogService _attendanceLogService = AttendanceLogService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  List<AttendanceLog> _logs = [];
  List<AttendanceLog> get logs => _logs;

  // Get timeline for a worker on a specific date
  Future<List<AttendanceLog>> getTimeline(int workerId, String date) async {
    setState(ViewState.busy);
    try {
      final timeline = await _attendanceLogService.getTimeline(workerId, date);
      _logs = timeline;
      setState(ViewState.idle);
      notifyListeners();
      return timeline;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final timeline = await _attendanceLogService.getTimeline(workerId, date);
        _logs = timeline;
        setState(ViewState.idle);
        notifyListeners();
        return timeline;
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
        rethrow;
      }
    }
  }

  // Add a new log entry
  Future<bool> addLog(AttendanceLog log) async {
    setState(ViewState.busy);
    try {
      await _attendanceLogService.addLog(log);
      // Reload logs to reflect changes
      if (log.id != null) {
        await getTimeline(log.workerId, log.date);
      }
      setState(ViewState.idle);
      notifyListeners();
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceLogService.addLog(log);
        // Reload logs to reflect changes
        if (log.id != null) {
          await getTimeline(log.workerId, log.date);
        }
        setState(ViewState.idle);
        notifyListeners();
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
        return false;
      }
    }
  }

  // Update an existing log entry
  Future<bool> updateLog(AttendanceLog log) async {
    setState(ViewState.busy);
    try {
      await _attendanceLogService.updateLog(log);
      // Reload logs to reflect changes
      await getTimeline(log.workerId, log.date);
      setState(ViewState.idle);
      notifyListeners();
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceLogService.updateLog(log);
        // Reload logs to reflect changes
        await getTimeline(log.workerId, log.date);
        setState(ViewState.idle);
        notifyListeners();
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
        return false;
      }
    }
  }

  // Delete a log entry
  Future<bool> deleteLog(int id, int workerId, String date) async {
    setState(ViewState.busy);
    try {
      await _attendanceLogService.deleteLog(id);
      // Reload logs to reflect changes
      await getTimeline(workerId, date);
      setState(ViewState.idle);
      notifyListeners();
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceLogService.deleteLog(id);
        // Reload logs to reflect changes
        await getTimeline(workerId, date);
        setState(ViewState.idle);
        notifyListeners();
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
        return false;
      }
    }
  }
}