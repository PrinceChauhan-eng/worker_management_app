import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/schema_refresher.dart';
import 'base_provider.dart';

class AttendanceProvider extends BaseProvider {
  final AttendanceService _attendanceService = AttendanceService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  List<Attendance> _attendances = [];
  List<Attendance> get attendances => _attendances;

  Future<void> loadAttendances() async {
    setState(ViewState.busy);
    try {
      final attendancesData = await _attendanceService.all();
      _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final attendancesData = await _attendanceService.all();
        _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
      }
    }
  }

  Future<void> loadAttendancesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    try {
      final attendancesData = await _attendanceService.byWorker(workerId);
      _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final attendancesData = await _attendanceService.byWorker(workerId);
        _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
      }
    }
  }

  Future<void> loadAttendancesByWorkerIdAndDate(int workerId, String date) async {
    setState(ViewState.busy);
    try {
      final attendancesData = await _attendanceService.byWorkerAndDate(workerId, date);
      _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final attendancesData = await _attendanceService.byWorkerAndDate(workerId, date);
        _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
      }
    }
  }

  Future<bool> addAttendance(Attendance attendance) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.insert(attendance.toMap());
      await loadAttendances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.insert(attendance.toMap());
        await loadAttendances();
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  Future<bool> updateAttendance(Attendance attendance) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.updateById(attendance.id!, attendance.toMap());
      await loadAttendances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.updateById(attendance.id!, attendance.toMap());
        await loadAttendances();
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  /// Upsert attendance (insert or update based on worker_id + date)
  Future<bool> upsertAttendance(Attendance attendance) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.upsertAttendance(attendance.toMap());
      await loadAttendances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.upsertAttendance(attendance.toMap());
        await loadAttendances();
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  Future<bool> deleteAttendance(int id) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.deleteById(id);
      await loadAttendances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.deleteById(id);
        await loadAttendances();
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  /// Mark worker login in attendance
  Future<void> markLogin({
    required int workerId,
    required String inTime,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.markLogin(
        workerId: workerId,
        inTime: inTime,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      // Reload attendances to reflect changes
      await loadAttendances();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.markLogin(
          workerId: workerId,
          inTime: inTime,
          address: address,
          latitude: latitude,
          longitude: longitude,
        );
        // Reload attendances to reflect changes
        await loadAttendances();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
      }
    }
  }

  /// Mark worker logout in attendance
  Future<void> markLogout({
    required int workerId,
    required String outTime,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.markLogout(
        workerId: workerId,
        outTime: outTime,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      // Reload attendances to reflect changes
      await loadAttendances();
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.markLogout(
          workerId: workerId,
          outTime: outTime,
          address: address,
          latitude: latitude,
          longitude: longitude,
        );
        // Reload attendances to reflect changes
        await loadAttendances();
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
      }
    }
  }

  /// Get today's attendance summary
  Future<Map<String, int>> getTodaySummary() async {
    try {
      return await _attendanceService.getTodaySummary();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 2));
      return await _attendanceService.getTodaySummary();
    }
  }

  /// Mark absentees (can be triggered on app start)
  Future<void> markAbsentees() async {
    try {
      await _attendanceService.markAbsentees();
      // Reload attendances to reflect changes
      await loadAttendances();
      notifyListeners();
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.markAbsentees();
        // Reload attendances to reflect changes
        await loadAttendances();
        notifyListeners();
      } catch (retryError) {
        notifyListeners();
      }
    }
  }
}