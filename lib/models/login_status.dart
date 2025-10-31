class LoginStatus {
  final int? id;
  final int workerId;
  final String date; // Date in YYYY-MM-DD format
  final String? loginTime; // Time when worker logged in
  final String? logoutTime; // Time when worker logged out
  final double? loginLatitude; // GPS latitude at login
  final double? loginLongitude; // GPS longitude at login
  final String? loginAddress; // Address at login
  final double? logoutLatitude; // GPS latitude at logout
  final double? logoutLongitude; // GPS longitude at logout
  final String? logoutAddress; // Address at logout
  final bool isLoggedIn; // Current login status
  final double? loginDistance; // Distance from work location at login (meters)
  final double? logoutDistance; // Distance from work location at logout (meters)

  LoginStatus({
    this.id,
    required this.workerId,
    required this.date,
    this.loginTime,
    this.logoutTime,
    this.loginLatitude,
    this.loginLongitude,
    this.loginAddress,
    this.logoutLatitude,
    this.logoutLongitude,
    this.logoutAddress,
    this.isLoggedIn = false,
    this.loginDistance,
    this.logoutDistance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date,
      'loginTime': loginTime,
      'logoutTime': logoutTime,
      'loginLatitude': loginLatitude,
      'loginLongitude': loginLongitude,
      'loginAddress': loginAddress,
      'logoutLatitude': logoutLatitude,
      'logoutLongitude': logoutLongitude,
      'logoutAddress': logoutAddress,
      'isLoggedIn': isLoggedIn ? 1 : 0,
      'loginDistance': loginDistance,
      'logoutDistance': logoutDistance,
    };
  }

  factory LoginStatus.fromMap(Map<String, dynamic> map) {
    return LoginStatus(
      id: map['id'],
      workerId: map['workerId'],
      date: map['date'],
      loginTime: map['loginTime'],
      logoutTime: map['logoutTime'],
      loginLatitude: map['loginLatitude'],
      loginLongitude: map['loginLongitude'],
      loginAddress: map['loginAddress'],
      logoutLatitude: map['logoutLatitude'],
      logoutLongitude: map['logoutLongitude'],
      logoutAddress: map['logoutAddress'],
      isLoggedIn: map['isLoggedIn'] == 1,
      loginDistance: map['loginDistance'],
      logoutDistance: map['logoutDistance'],
    );
  }

  // Helper method to check if worker is present (logged in)
  bool get isPresent => loginTime != null;

  // Helper method to check if worker has logged out
  bool get hasLoggedOut => logoutTime != null;

  // Helper method to get working hours
  double get workingHours {
    if (loginTime == null || logoutTime == null) return 0.0;
    
    try {
      final login = DateTime.parse('$date $loginTime');
      final logout = DateTime.parse('$date $logoutTime');
      final duration = logout.difference(login);
      return duration.inMinutes / 60.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Helper to check if location verification passed
  bool get loginLocationValid => loginDistance != null && loginDistance! <= 100;
  bool get logoutLocationValid => logoutDistance != null && logoutDistance! <= 100;
}
