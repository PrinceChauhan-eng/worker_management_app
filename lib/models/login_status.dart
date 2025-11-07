class LoginStatus {
  final int? id;
  final int workerId;
  final String date; // Date in YYYY-MM-DD format
  final String? loginTime; // Time when worker logged in
  final String? logoutTime; // Time when worker logged out
  final bool isLoggedIn; // Current login status

  LoginStatus({
    this.id,
    required this.workerId,
    required this.date,
    this.loginTime,
    this.logoutTime,
    this.isLoggedIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date,
      'loginTime': loginTime,
      'logoutTime': logoutTime,
      'isLoggedIn': isLoggedIn ? 1 : 0,
    };
  }

  factory LoginStatus.fromMap(Map<String, dynamic> map) {
    return LoginStatus(
      id: map['id'],
      workerId: map['workerId'],
      date: map['date'],
      loginTime: map['loginTime'],
      logoutTime: map['logoutTime'],
      isLoggedIn: map['isLoggedIn'] == 1,
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