import '../models/attendance.dart';
import '../services/attendance_service.dart';
import 'base_provider.dart';

class AttendanceProvider extends BaseProvider {
  final AttendanceService _attendanceService = AttendanceService();
  
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
      setState(ViewState.idle);
      notifyListeners();
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
      setState(ViewState.idle);
      notifyListeners();
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
      setState(ViewState.idle);
      notifyListeners();
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
      setState(ViewState.idle);
      return false;
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
      setState(ViewState.idle);
      return false;
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
      setState(ViewState.idle);
      return false;
    }
  }
}