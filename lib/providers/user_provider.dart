import '../models/user.dart';
import '../services/users_service.dart';
import '../services/auth_service.dart';
import '../services/schema_refresher.dart';
import 'base_provider.dart';
import '../utils/logger.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:io';

class UserProvider extends BaseProvider {
  final UsersService _usersService = UsersService();
  final AuthService _authService = AuthService();
  final SchemaRefresher _schemaRefresher = SchemaRefresher();

  UserProvider() {
    Logger.info('UserProvider created');
  }

  List<User> _workers = [];
  List<User> get workers => _workers;

  User? _currentUser;
  User? get currentUser => _currentUser;
  set currentUser(User? user) => _currentUser = user;

  Future<void> loadWorkers() async {
    setState(ViewState.busy);
    try {
      Logger.info('Loading workers...');
      final usersData = await _usersService.getUsers();
      _workers = usersData.map((data) => User.fromMap(data)).toList();
      Logger.info('Workers loaded successfully. Count: ${_workers.length}');

      // Log each worker for debugging
      for (var worker in _workers) {
        Logger.info('Worker loaded: ID=${worker.id}, Name=${worker.name}, Phone=${worker.phone}, Role=${worker.role}');
      }

      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      Logger.error('Error loading workers: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        final usersData = await _usersService.getUsers();
        _workers = usersData.map((data) => User.fromMap(data)).toList();
        Logger.info('Workers loaded successfully. Count: ${_workers.length}');
        
        // Log each worker for debugging
        for (var worker in _workers) {
          Logger.info('Worker loaded: ID=${worker.id}, Name=${worker.name}, Phone=${worker.phone}, Role=${worker.role}');
        }
        
        setState(ViewState.idle);
        notifyListeners();
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        notifyListeners();
      }
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
    } catch (e) {
      Logger.error('Error adding user: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _usersService.insertUser(user.toMap());
        await loadWorkers();
        setState(ViewState.idle);
        Logger.info('User added successfully: ${user.name}');
        return true;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        return false;
      }
    }
  }

  Future<bool> updateUser(User user) async {
    setState(ViewState.busy);
    try {
      Logger.info('Updating user: ${user.name} (ID: ${user.id})');
      Logger.info('Profile photo: ${user.profilePhoto}');
      Logger.info('Email: ${user.email}');
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
    } catch (e) {
      Logger.error('Error updating user: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixExtendedSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
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
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        notifyListeners();
        return false;
      }
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
    } catch (e) {
      Logger.error('Error deleting user: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        await _usersService.deleteUser(id);
        await loadWorkers();
        setState(ViewState.idle);
        return true;
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        return false;
      }
    }
  }

  Future<User?> authenticateUser(String phone, String password) async {
    setState(ViewState.busy);
    try {
      Logger.info('Authenticating user with phone: $phone');
      // First, find the user by phone
      final userData = await _usersService.getUserByPhone(phone);
      if (userData == null) {
        Logger.warn('Authentication failed: User not found with phone: $phone');
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
    } catch (e) {
      Logger.error('Error authenticating user: $e', e);
      // Try to fix schema errors
      await _schemaRefresher.tryFixSchemaError(e);
      
      // Retry after schema refresh
      try {
        await Future.delayed(const Duration(seconds: 2));
        // First, find the user by phone
        final userData = await _usersService.getUserByPhone(phone);
        if (userData == null) {
          Logger.warn('Authentication failed: User not found with phone: $phone');
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
      } catch (retryError) {
        Logger.error('Retry failed: $retryError', retryError);
        setState(ViewState.idle);
        notifyListeners();
        return null;
      }
    }
  }

  final supabase = Supabase.instance.client;

  Future<String?> _uploadProfileImage(File file) async {
    try {
      final path = "profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage
          .from('profile_images')
          .upload(path, file);

      final url = supabase.storage
          .from('profile_images')
          .getPublicUrl(path);

      return url;
    } catch (e) {
      print("Image upload failed: $e");
      return null;
    }
  }

  Future<void> updateAdminProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String designation,
    File? imageFile,
  }) async {
    String? profileUrl = currentUser?.profilePhoto;

    if (imageFile != null) {
      final uploadedUrl = await _uploadProfileImage(imageFile);
      if (uploadedUrl != null) profileUrl = uploadedUrl;
    }

    await supabase.from('users').update({
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'designation': designation,
      'profilePhoto': profileUrl,
    }).eq('id', currentUser!.id!);

    currentUser = currentUser!.copyWith(
      name: name,
      email: email,
      phone: phone,
      address: address,
      designation: designation,
      profilePhoto: profileUrl,
    );

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (currentUser == null) return;

    await supabase
        .from('users')
        .delete()
        .eq('id', currentUser!.id!);

    currentUser = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    currentUser = null;
    notifyListeners();
  }

  Future<void> loadUser(String id) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', id)
        .single();

    currentUser = User.fromMap(response);
    notifyListeners();
  }

  /// Get profile completion percentage
  double getProfileCompletion() {
    int total = 5;
    int filled = 0;

    if (currentUser?.name.isNotEmpty == true) filled++;
    if (currentUser?.phone.isNotEmpty == true) filled++;
    if (currentUser?.email?.isNotEmpty == true) filled++;
    if (currentUser?.address?.isNotEmpty == true) filled++;
    if (currentUser?.profilePhoto?.isNotEmpty == true) filled++;

    return (filled / total) * 100;
  }

  /// Get account age in days
  String getAccountAge() {
    if (currentUser?.joinDate == null) return "--";

    try {
      final created = DateTime.parse(currentUser!.joinDate!);
      final diff = DateTime.now().difference(created).inDays;
      return "$diff days";
    } catch (e) {
      return "--";
    }
  }

  /// Get user by ID from workers list
  Future<User?> getUser(int id) async {
    try {
      return _workers.firstWhere((user) => user.id == id);
    } catch (e) {
      return null; // Return null if user not found
    }
  }
}