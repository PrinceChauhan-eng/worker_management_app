import '../models/user.dart';
import '../services/database_helper.dart';
import 'base_provider.dart';

class UserProvider extends BaseProvider {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  UserProvider() {
    print('UserProvider created');
  }
  
  List<User> _workers = [];
  List<User> get workers => _workers;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> loadWorkers() async {
    setState(ViewState.busy);
    try {
      print('Loading workers...');
      await _dbHelper.initDB(); // Ensure database is initialized
      _workers = await _dbHelper.getUsers();
      print('Workers loaded successfully. Count: ${_workers.length}');
      
      // Log each worker for debugging
      for (var worker in _workers) {
        print('Worker loaded: ID=${worker.id}, Name=${worker.name}, Phone=${worker.phone}, Role=${worker.role}');
      }
      
      setState(ViewState.idle);
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error loading workers: $e');
      print('Stack trace: $stackTrace');
      setState(ViewState.idle);
      notifyListeners();
    }
  }

  Future<bool> addUser(User user) async {
    setState(ViewState.busy);
    try {
      print('Adding user: ${user.name}');
      await _dbHelper.initDB(); // Ensure database is initialized
      await _dbHelper.insertUser(user);
      await loadWorkers();
      setState(ViewState.idle);
      print('User added successfully: ${user.name}');
      return true;
    } catch (e, stackTrace) {
      print('Error adding user: $e');
      print('Stack trace: $stackTrace');
      setState(ViewState.idle);
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    setState(ViewState.busy);
    try {
      print('Updating user: ${user.name} (ID: ${user.id})');
      print('Profile photo: ${user.profilePhoto}');
      print('Email: ${user.email}');
      await _dbHelper.initDB(); // Ensure database is initialized
      await _dbHelper.updateUser(user);
      
      // Update current user if this is the logged-in user
      if (_currentUser != null && _currentUser!.id == user.id) {
        _currentUser = user;
        print('Current user updated in provider');
      }
      
      await loadWorkers();
      setState(ViewState.idle);
      notifyListeners();
      print('User update completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('Error updating user: $e');
      print('Stack trace: $stackTrace');
      setState(ViewState.idle);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    setState(ViewState.busy);
    try {
      print('Deleting user with ID: $id');
      await _dbHelper.initDB(); // Ensure database is initialized
      await _dbHelper.deleteUser(id);
      await loadWorkers();
      setState(ViewState.idle);
      return true;
    } catch (e, stackTrace) {
      print('Error deleting user: $e');
      print('Stack trace: $stackTrace');
      setState(ViewState.idle);
      return false;
    }
  }

  Future<User?> authenticateUser(String phone, String password) async {
    setState(ViewState.busy);
    try {
      print('Authenticating user with phone: $phone and password: $password');
      await _dbHelper.initDB(); // Ensure database is initialized before authentication
      print('Database initialized successfully for authentication');
      _currentUser = await _dbHelper.getUserByPhoneAndPassword(phone, password);
      print('Authentication result: ${_currentUser != null ? "SUCCESS" : "FAILED"}');
      if (_currentUser != null) {
        print('Authenticated user: ${_currentUser!.name}, role: ${_currentUser!.role}');
      } else {
        print('Authentication failed: User not found or invalid credentials');
        // Let's try to get all users to see what's in the database
        try {
          print('Attempting to get all users for debugging...');
          var allUsers = await _dbHelper.getUsers();
          print('Total users in database: ${allUsers.length}');
          for (var user in allUsers) {
            print('User in database: ID=${user.id}, name=${user.name}, phone=${user.phone}, role=${user.role}');
          }
        } catch (e, stackTrace) {
          print('Error getting all users for debugging: $e');
          print('Stack trace: $stackTrace');
        }
      }
      setState(ViewState.idle);
      notifyListeners();
      return _currentUser;
    } catch (e, stackTrace) {
      print('Error authenticating user: $e');
      print('Stack trace: $stackTrace');
      setState(ViewState.idle);
      return null;
    }
  }

  void setCurrentUser(User user) {
    print('Setting current user: ${user.name} (ID: ${user.id})');
    print('User details: Phone=${user.phone}, Role=${user.role}, Email=${user.email}, Verified=${user.emailVerified}');
    _currentUser = user;
    notifyListeners();
  }

  void clearCurrentUser() {
    print('Clearing current user');
    _currentUser = null;
    notifyListeners();
  }
}