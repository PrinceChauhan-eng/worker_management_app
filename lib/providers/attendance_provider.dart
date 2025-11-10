import '../models/attendance.dart';
import '../services/database_helper.dart';
import 'base_provider.dart';

class AttendanceProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Attendance> _attendances = [];
  List<Attendance> get attendances => _attendances;

  Future<void> loadAttendances() async {
    setState(ViewState.busy);
    _attendances = await _dbHelper.getAttendances();
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<void> loadAttendancesByWorkerId(int workerId) async {
    setState(ViewState.busy);
    _attendances = await _dbHelper.getAttendancesByWorkerId(workerId);
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<void> loadAttendancesByWorkerIdAndDate(int workerId, String date) async {
    setState(ViewState.busy);
    _attendances = await _dbHelper.getAttendancesByWorkerIdAndDate(workerId, date);
    setState(ViewState.idle);
    notifyListeners();
  }

  Future<bool> addAttendance(Attendance attendance) async {
    setState(ViewState.busy);
    try {
      await _dbHelper.insertAttendance(attendance);
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
      await _dbHelper.updateAttendance(attendance);
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
      await _dbHelper.deleteAttendance(id);
      await loadAttendances();
      setState(ViewState.idle);
      return true;
    } catch (e) {
      setState(ViewState.idle);
      return false;
    }
  }
}