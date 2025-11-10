import '../models/user.dart';
import '../services/users_service.dart';
import '../services/auth_service.dart';
import 'base_provider.dart';
import '../utils/logger.dart';

class UserProvider extends BaseProvider {
  final UsersService _usersService = UsersService();
  final AuthService _authService = AuthService();

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
      final usersData = await _usersService.getUsers();
      _workers = usersData.map((data) => User.fromMap(data)).toList();
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
      await _usersService.insertUser(user.toMap());
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
      await _usersService.updateUser(user.id!, user.toMap());

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
      await _usersService.deleteUser(id);
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
      // First, find the user by phone
      final userData = await _usersService.getUserByPhone(phone);
      if (userData == null) {
        Logger.warning('Authentication failed: User not found with phone: $phone');
        setState(ViewState.idle);
        notifyListeners();
        return null;
      }
      
      // For demo purposes, we'll assume authentication is successful
      // In a real app, you would integrate with Supabase Auth
      _currentUser = User.fromMap(userData);
      Logger.info('Authentication result: SUCCESS');
      Logger.info('Authenticated user: ${_currentUser!.name}, role: ${_currentUser!.role}');
      
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
      final userData = await _usersService.getUser(id);
      return userData != null ? User.fromMap(userData) : null;
    } catch (e, stackTrace) {
      Logger.error('Error getting user by ID: $e', e, stackTrace);
      rethrow;
    }
  }
}