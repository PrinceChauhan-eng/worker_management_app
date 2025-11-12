class LoginStatus {
  final int? id;
  final int workerId;
  final String date; // Date in YYYY-MM-DD format
  final String? loginTime; // Time when worker logged in
  final String? logoutTime; // Time when worker logged out
  final bool isLoggedIn; // Current login status
  // Location fields for login
  final double? loginLatitude;
  final double? loginLongitude;
  final String? loginAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;
  // Location fields for logout
  final double? logoutLatitude;
  final double? logoutLongitude;
  final String? logoutAddress;
  final String? logoutCity;
  final String? logoutState;
  final String? logoutPincode;

  LoginStatus({
    this.id,
    required this.workerId,
    required this.date,
    this.loginTime,
    this.logoutTime,
    this.isLoggedIn = false,
    this.loginLatitude,
    this.loginLongitude,
    this.loginAddress,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.logoutLatitude,
    this.logoutLongitude,
    this.logoutAddress,
    this.logoutCity,
    this.logoutState,
    this.logoutPincode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'login_time': loginTime,
      'logout_time': logoutTime,
      'is_logged_in': isLoggedIn ? 1 : 0,
      'login_latitude': loginLatitude,
      'login_longitude': loginLongitude,
      'login_address': loginAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'logout_latitude': logoutLatitude,
      'logout_longitude': logoutLongitude,
      'logout_address': logoutAddress,
      'logout_city': logoutCity,
      'logout_state': logoutState,
      'logout_pincode': logoutPincode,
    };
  }

  factory LoginStatus.fromMap(Map<String, dynamic> map) {
    return LoginStatus(
      id: map['id'],
      workerId: map['worker_id'] ?? map['workerId'],
      date: map['date'],
      loginTime: map['login_time'] ?? map['loginTime'],
      logoutTime: map['logout_time'] ?? map['logoutTime'],
      isLoggedIn: (map['is_logged_in'] ?? map['isLoggedIn']) == 1,
      loginLatitude: map['login_latitude'] ?? map['loginLatitude'],
      loginLongitude: map['login_longitude'] ?? map['loginLongitude'],
      loginAddress: map['login_address'] ?? map['loginAddress'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      country: map['country'],
      logoutLatitude: map['logout_latitude'] ?? map['logoutLatitude'],
      logoutLongitude: map['logout_longitude'] ?? map['logoutLongitude'],
      logoutAddress: map['logout_address'] ?? map['logoutAddress'],
      logoutCity: map['logout_city'],
      logoutState: map['logout_state'],
      logoutPincode: map['logout_pincode'],
    );
  }

  // Helper method to check if worker is present (logged in)
  bool get isPresent => loginTime != null;

  // Helper method to check if worker has logged out
  bool get hasLoggedOut => logoutTime != null;

  // Helper method to get working hours (capped at 8 hours for display)
  double get workingHours {
    if (loginTime == null || logoutTime == null) return 0.0;
    
    try {
      final login = DateTime.parse('$date $loginTime');
      final logout = DateTime.parse('$date $logoutTime');
      final duration = logout.difference(login);
      final hours = duration.inMinutes / 60.0;
      // Cap at 8 hours for display purposes
      return hours > 8.0 ? 8.0 : hours;
    } catch (e) {
      return 0.0;
    }
  }
}