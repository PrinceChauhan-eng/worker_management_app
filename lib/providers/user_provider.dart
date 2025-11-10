import '../models/user.dart';
import '../services/database_helper.dart';
import 'base_provider.dart';
import '../utils/logger.dart';

class UserProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  UserProvider() {
    Logger.debug('UserProvider created');
  }

  List<User> _workers = [];
  List<User> get workers => _workers;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> loadWorkers() async {
    setState(ViewState.busy);
    try {
      Logger.info('Loading workers...');
      await _dbHelper.initDB(); // Ensure database is initialized
      _workers = await _dbHelper.getUsers();
      Logger.info('Workers loaded successfully. Count: ${_workers.length}');

      // Log each worker for debugging
      for (var worker in _workers) {
        Logger.debug('Worker loaded: ID=${worker.id}, Name=${worker.name}, Phone=${worker.phone}, Role=${worker.role}');
      }

      setState(ViewState.idle);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error loading workers: $e', e, stackTrace);
      setState(ViewState.idle);
      notifyListeners();
    }
  }

  Future<bool> addUser(User user) async {
    setState(ViewState.busy);
    try {
      Logger.info('Adding user: ${user.name}');
      await _dbHelper.initDB(); // Ensure database is initialized
      await _dbHelper.insertUser(user);
      await loadWorkers();
      setState(ViewState.idle);
      Logger.info('User added successfully: ${user.name}');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error adding user: $e', e, stackTrace);
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    setState(ViewState.busy);
    try {
      Logger.info('Updating user: ${user.name} (ID: ${user.id})');
      Logger.debug('Profile photo: ${user.profilePhoto}');
      Logger.debug('Email: ${user.email}');
      await _dbHelper.initDB(); // Ensure database is initialized
      await _dbHelper.updateUser(user);

      // Update current user if this is the logged-in user
      if (_currentUser != null && _currentUser!.id == user.id) {
        _currentUser = user;
        Logger.info('Current user updated in provider');
      }

      await loadWorkers();
      setState(ViewState.idle);
      notifyListeners();
      Logger.info('User update completed successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error updating user: $e', e, stackTrace);
      setState(ViewState.idle);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    setState(ViewState.busy);
    try {
      Logger.info('Deleting user with ID: $id');
      await _dbHelper.initDB(); // Ensure database is initialized
      await _dbHelper.deleteUser(id);
      await loadWorkers();
      setState(ViewState.idle);
      return true;
    } catch (e, stackTrace) {
      Logger.error('Error deleting user: $e', e, stackTrace);
      setState(ViewState.idle);
      return false;
    }
  }

  Future<User?> authenticateUser(String phone, String password) async {
    setState(ViewState.busy);
    try {
      Logger.info('Authenticating user with phone: $phone');
      await _dbHelper
          .initDB(); // Ensure database is initialized before authentication
      Logger.debug('Database initialized successfully for authentication');
      _currentUser = await _dbHelper.getUserByPhoneAndPassword(phone, password);
      Logger.info('Authentication result: ${_currentUser != null ? "SUCCESS" : "FAILED"}');
      if (_currentUser != null) {
        Logger.info('Authenticated user: ${_currentUser!.name}, role: ${_currentUser!.role}');
      } else {
        Logger.warning('Authentication failed: User not found or invalid credentials');
      }
      setState(ViewState.idle);
      notifyListeners();
      return _currentUser;
    } catch (e, stackTrace) {
      Logger.error('Error authenticating user: $e', e, stackTrace);
      setState(ViewState.idle);
      return null;
    }
  }

  void setCurrentUser(User user) {
    Logger.info('Setting current user: ${user.name} (ID: ${user.id})');
    Logger.debug('User details: Phone=${user.phone}, Role=${user.role}, Email=${user.email}, Verified=${user.emailVerified}');
    _currentUser = user;
    notifyListeners();
  }

  void clearCurrentUser() {
    Logger.info('Clearing current user');
    _currentUser = null;
    notifyListeners();
  }

  Future<User?> getUser(int id) async {
    try {
      Logger.info('Getting user by ID: $id');
      return await _dbHelper.getUser(id);
    } catch (e, stackTrace) {
      Logger.error('Error getting user by ID: $e', e, stackTrace);
      rethrow;
    }
  }
}
