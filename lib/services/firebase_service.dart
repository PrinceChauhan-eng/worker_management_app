import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../models/login_status.dart';
import '../models/advance.dart';
import '../models/salary.dart';
import '../utils/logger.dart';

class FirebaseService {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  bool _initialized = false;

  FirebaseService() {
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Try to initialize Firebase
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _initialized = true;
      Logger.info('Firebase initialized successfully');
    } catch (e) {
      Logger.error('Firebase initialization failed: $e', e);
      _initialized = false;
      _firestore = null;
      _auth = null;
    }
  }

  // Check if Firebase is initialized
  bool get isInitialized => _initialized;

  // Helper method to ensure Firebase is available
  void _ensureInitialized() {
    if (!_initialized || _firestore == null) {
      throw Exception('Firebase service has not initialized');
    }
  }

  // Users collection methods
  Future<void> addUser(app_user.User user) async {
    _ensureInitialized();
    try {
      await _firestore!.collection('users').doc(user.id.toString()).set({
        'id': user.id,
        'name': user.name,
        'phone': user.phone,
        'password': user.password,
        'role': user.role,
        'wage': user.wage,
        'joinDate': user.joinDate,
        'workLocationLatitude': user.workLocationLatitude,
        'workLocationLongitude': user.workLocationLongitude,
        'workLocationAddress': user.workLocationAddress,
        'locationRadius': user.locationRadius,
        'profilePhoto': user.profilePhoto,
        'idProof': user.idProof,
        'address': user.address,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'emailVerificationCode': user.emailVerificationCode,
        'designation': user.designation,
      });
    } catch (e) {
      Logger.error('Error adding user to Firebase: $e', e);
      rethrow;
    }
  }

  Future<List<app_user.User>> getUsers() async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!.collection('users').get();
      return snapshot.docs
          .map((doc) => app_user.User.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting users from Firebase: $e', e);
      rethrow;
    }
  }

  Future<app_user.User?> getUserByPhoneAndPassword(
      String phone, String password) async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!
          .collection('users')
          .where('phone', isEqualTo: phone)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return app_user.User.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      Logger.error('Error authenticating user from Firebase: $e', e);
      rethrow;
    }
  }

  Future<void> updateUser(app_user.User user) async {
    _ensureInitialized();
    try {
      await _firestore!.collection('users').doc(user.id.toString()).update({
        'name': user.name,
        'phone': user.phone,
        'password': user.password,
        'role': user.role,
        'wage': user.wage,
        'joinDate': user.joinDate,
        'workLocationLatitude': user.workLocationLatitude,
        'workLocationLongitude': user.workLocationLongitude,
        'workLocationAddress': user.workLocationAddress,
        'locationRadius': user.locationRadius,
        'profilePhoto': user.profilePhoto,
        'idProof': user.idProof,
        'address': user.address,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'emailVerificationCode': user.emailVerificationCode,
        'designation': user.designation,
      });
    } catch (e) {
      Logger.error('Error updating user in Firebase: $e', e);
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    _ensureInitialized();
    try {
      await _firestore!.collection('users').doc(id.toString()).delete();
    } catch (e) {
      Logger.error('Error deleting user from Firebase: $e', e);
      rethrow;
    }
  }

  // Login Status collection methods
  Future<void> addLoginStatus(LoginStatus loginStatus) async {
    _ensureInitialized();
    try {
      await _firestore!
          .collection('login_status')
          .doc(loginStatus.id?.toString())
          .set({
        'id': loginStatus.id,
        'workerId': loginStatus.workerId,
        'date': loginStatus.date,
        'loginTime': loginStatus.loginTime,
        'logoutTime': loginStatus.logoutTime,
        'isLoggedIn': loginStatus.isLoggedIn,
      });
    } catch (e) {
      Logger.error('Error adding login status to Firebase: $e', e);
      rethrow;
    }
  }

  Future<List<LoginStatus>> getLoginStatuses() async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!.collection('login_status').get();
      return snapshot.docs
          .map((doc) => LoginStatus.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting login statuses from Firebase: $e', e);
      rethrow;
    }
  }

  Future<LoginStatus?> getTodayLoginStatus(int workerId, String date) async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!
          .collection('login_status')
          .where('workerId', isEqualTo: workerId)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LoginStatus.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      Logger.error('Error getting today login status from Firebase: $e', e);
      rethrow;
    }
  }

  Future<void> updateLoginStatus(LoginStatus loginStatus) async {
    _ensureInitialized();
    try {
      await _firestore!
          .collection('login_status')
          .doc(loginStatus.id?.toString())
          .update({
        'workerId': loginStatus.workerId,
        'date': loginStatus.date,
        'loginTime': loginStatus.loginTime,
        'logoutTime': loginStatus.logoutTime,
        'isLoggedIn': loginStatus.isLoggedIn,
      });
    } catch (e) {
      Logger.error('Error updating login status in Firebase: $e', e);
      rethrow;
    }
  }

  Future<List<LoginStatus>> getCurrentlyLoggedInWorkers() async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!
          .collection('login_status')
          .where('isLoggedIn', isEqualTo: 1)
          .get();
      return snapshot.docs
          .map((doc) => LoginStatus.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting logged in workers from Firebase: $e', e);
      rethrow;
    }
  }

  // Advance collection methods
  Future<void> addAdvance(Advance advance) async {
    _ensureInitialized();
    try {
      await _firestore!.collection('advance').doc(advance.id?.toString()).set({
        'id': advance.id,
        'workerId': advance.workerId,
        'amount': advance.amount,
        'date': advance.date,
        'purpose': advance.purpose,
        'note': advance.note,
        'status': advance.status,
        'deductedFromSalaryId': advance.deductedFromSalaryId,
        'approvedBy': advance.approvedBy,
        'approvedDate': advance.approvedDate,
      });
    } catch (e) {
      Logger.error('Error adding advance to Firebase: $e', e);
      rethrow;
    }
  }

  Future<List<Advance>> getAdvances() async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!.collection('advance').get();
      return snapshot.docs
          .map((doc) => Advance.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting advances from Firebase: $e', e);
      rethrow;
    }
  }

  Future<List<Advance>> getAdvancesByWorkerId(int workerId) async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!
          .collection('advance')
          .where('workerId', isEqualTo: workerId)
          .get();
      return snapshot.docs
          .map((doc) => Advance.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting advances by worker ID from Firebase: $e', e);
      rethrow;
    }
  }

  Future<void> updateAdvance(Advance advance) async {
    _ensureInitialized();
    try {
      await _firestore!
          .collection('advance')
          .doc(advance.id?.toString())
          .update({
        'workerId': advance.workerId,
        'amount': advance.amount,
        'date': advance.date,
        'purpose': advance.purpose,
        'note': advance.note,
        'status': advance.status,
        'deductedFromSalaryId': advance.deductedFromSalaryId,
        'approvedBy': advance.approvedBy,
        'approvedDate': advance.approvedDate,
      });
    } catch (e) {
      Logger.error('Error updating advance in Firebase: $e', e);
      rethrow;
    }
  }

  // Salary collection methods
  Future<void> addSalary(Salary salary) async {
    _ensureInitialized();
    try {
      await _firestore!.collection('salary').doc(salary.id?.toString()).set({
        'id': salary.id,
        'workerId': salary.workerId,
        'month': salary.month,
        'totalDays': salary.totalDays,
        'totalSalary': salary.totalSalary,
        'paid': salary.paid,
        'year': salary.year,
        'presentDays': salary.presentDays,
        'absentDays': salary.absentDays,
        'grossSalary': salary.grossSalary,
        'totalAdvance': salary.totalAdvance,
        'netSalary': salary.netSalary,
        'paidDate': salary.paidDate,
        'pdfUrl': salary.pdfUrl,
      });
    } catch (e) {
      Logger.error('Error adding salary to Firebase: $e', e);
      rethrow;
    }
  }

  Future<List<Salary>> getSalaries() async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!.collection('salary').get();
      return snapshot.docs
          .map((doc) => Salary.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Logger.error('Error getting salaries from Firebase: $e', e);
      rethrow;
    }
  }

  Future<Salary?> getSalaryByWorkerIdAndMonth(
      int workerId, String month) async {
    _ensureInitialized();
    try {
      final snapshot = await _firestore!
          .collection('salary')
          .where('workerId', isEqualTo: workerId)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Salary.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      Logger.error('Error getting salary by worker ID and month from Firebase: $e', e);
      rethrow;
    }
  }

  Future<void> updateSalary(Salary salary) async {
    _ensureInitialized();
    try {
      await _firestore!.collection('salary').doc(salary.id?.toString()).update({
        'workerId': salary.workerId,
        'month': salary.month,
        'totalDays': salary.totalDays,
        'totalSalary': salary.totalSalary,
        'paid': salary.paid,
        'year': salary.year,
        'presentDays': salary.presentDays,
        'absentDays': salary.absentDays,
        'grossSalary': salary.grossSalary,
        'totalAdvance': salary.totalAdvance,
        'netSalary': salary.netSalary,
        'paidDate': salary.paidDate,
        'pdfUrl': salary.pdfUrl,
      });
    } catch (e) {
      Logger.error('Error updating salary in Firebase: $e', e);
      rethrow;
    }
  }

  // Authentication methods
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    _ensureInitialized();
    try {
      final userCredential = await _auth!.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      Logger.error('Error signing in with email and password: $e', e);
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    _ensureInitialized();
    try {
      final userCredential = await _auth!.createUserWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      Logger.error('Error creating user with email and password: $e', e);
      return null;
    }
  }

  Future<void> signOut() async {
    _ensureInitialized();
    await _auth!.signOut();
  }
}