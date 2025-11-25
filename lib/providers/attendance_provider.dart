import '../models/attendance.dart';
import '../models/attendance_log.dart';
import '../services/attendance_service.dart';
import '../services/attendance_log_service.dart';
import '../services/schema_refresher.dart';
import 'base_provider.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class AttendanceProvider extends BaseProvider {
  final AttendanceService _attendanceService = AttendanceService();
  final AttendanceLogService _attendanceLogService = AttendanceLogService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();
  
  List<Attendance> _attendances = [];
  List<Attendance> get attendances => _attendances;

  // Add caching flags for today's data (Fix #5)
  bool _isLoadingToday = false;
  bool _isLoadedToday = false;
  Map<String, dynamic>? _todayCache;

  // Invalidate today's cache (Fix #5)
  void _invalidateTodayCache() {
    _isLoadedToday = false;
    _todayCache = null;
  }

  // Public method to invalidate today's cache
  void invalidateTodayCache() {
    _invalidateTodayCache();
  }

  Future<void> loadAttendances() async {
    setState(ViewState.busy);
    try {
      final attendancesData = await _attendanceService.all();
      _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
      setState(ViewState.idle);
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final attendancesData = await _attendanceService.all();
        _attendances = attendancesData.map((data) => Attendance.fromMap(data)).toList();
        setState(ViewState.idle);
        Future.microtask(() {
          notifyListeners();
        });
      } catch (retryError) {
        setState(ViewState.idle);
        Future.microtask(() {
          notifyListeners();
        });
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

  Future<bool> deleteAttendance(int id) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.deleteById(id);
      await loadAttendances();
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
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
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  /// Insert new attendance record
  Future<bool> addAttendance(Attendance attendance) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.insert(attendance.toMap());
      await loadAttendances();
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
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
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        setState(ViewState.idle);
        return false;
      }
    }
  }

  /// Update existing attendance record
  Future<bool> updateAttendance(Attendance attendance) async {
    setState(ViewState.busy);
    try {
      await _attendanceService.updateById(attendance.id!, attendance.toMap());
      await loadAttendances();
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
      setState(ViewState.idle);
      return true;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _attendanceService.updateById(attendance.id!, attendance.toMap());
        await loadAttendances();
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
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
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
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
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
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
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
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
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        setState(ViewState.idle);
        notifyListeners();
      }
    }
  }

  /// Get attendance timeline for a worker on a specific date
  Future<List<AttendanceLog>> getAttendanceTimeline(int workerId, String date) async {
    try {
      return await _attendanceLogService.getTimeline(workerId, date);
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 2));
      return await _attendanceLogService.getTimeline(workerId, date);
    }
  }

  /// Get today's attendance summary with caching (Fix #5)
  Future<Map<String, int>> getTodaySummary() async {
    // Check if already loaded
    if (_isLoadedToday && _todayCache != null) {
      return _todayCache!['todaySummary'] as Map<String, int>;
    }

    // Check if already loading
    if (_isLoadingToday) {
      // Wait for the ongoing request to complete
      while (_isLoadingToday) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return cached data if available
      if (_todayCache != null) {
        return _todayCache!['todaySummary'] as Map<String, int>;
      }
      return {'total': 0, 'present': 0, 'absent': 0};
    }

    // Set loading flag
    _isLoadingToday = true;
    
    try {
      final result = await _attendanceService.getTodaySummary();
      
      // Cache the data
      _todayCache = {
        'todaySummary': result,
      };
      _isLoadedToday = true;
      
      return result;
    } catch (e) {
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      await Future.delayed(const Duration(seconds: 2));
      final result = await _attendanceService.getTodaySummary();
      
      // Cache the data
      _todayCache = {
        'todaySummary': result,
      };
      _isLoadedToday = true;
      
      return result;
    } finally {
      // Reset loading flag
      _isLoadingToday = false;
    }
  }

  /// Get today's attendance with pagination
  Future<List<Attendance>> getTodayAttendancePaged({
    required int page,
    int limit = 5,
  }) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      final attendancesData = await _attendanceService.getAttendancePaged(
        date: today,
        limit: limit,
        offset: page * limit,
      );
      return attendancesData.map((e) => Attendance.fromMap(e)).toList();
    } catch (e) {
      await _schemaRefresher.tryFixSchemaError(e);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now().toLocal());
      final attendancesData = await _attendanceService.getAttendancePaged(
        date: today,
        limit: limit,
        offset: page * limit,
      );
      return attendancesData.map((e) => Attendance.fromMap(e)).toList();
    }
  }

  /// Mark absentees (can be triggered on app start)
  Future<void> markAbsentees() async {
    try {
      await _attendanceService.markAbsentees();
      // Reload attendances to reflect changes
      await loadAttendances();
      
      // Invalidate cache for today's data (Fix #5)
      _invalidateTodayCache();
      
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
        
        // Invalidate cache for today's data (Fix #5)
        _invalidateTodayCache();
        
        notifyListeners();
      } catch (retryError) {
        notifyListeners();
      }
    }
  }
}