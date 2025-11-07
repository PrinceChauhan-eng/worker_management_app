
class LoginHistory {
  final int? id;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime loginTime;
  final String ipAddress;
  final String userAgent;
  final bool success;
  final String? failureReason;

  LoginHistory({
    this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.loginTime,
    required this.ipAddress,
    required this.userAgent,
    required this.success,
    this.failureReason,
  });

  // Create from database map
  factory LoginHistory.fromMap(Map<String, dynamic> map) {
    return LoginHistory(
      id: map['id'],
      userId: map['user_id'],
      userName: map['user_name'],
      userRole: map['user_role'],
      loginTime: DateTime.fromMillisecondsSinceEpoch(map['login_time']),
      ipAddress: map['ip_address'],
      userAgent: map['user_agent'],
      success: map['success'] == 1,
      failureReason: map['failure_reason'],
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'login_time': loginTime.millisecondsSinceEpoch,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'success': success ? 1 : 0,
      'failure_reason': failureReason,
    };
  }

  // Create a copy with new values
  LoginHistory copyWith({
    int? id,
    int? userId,
    String? userName,
    String? userRole,
    DateTime? loginTime,
    String? ipAddress,
    String? userAgent,
    bool? success,
    String? failureReason,
  }) {
    return LoginHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      loginTime: loginTime ?? this.loginTime,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      success: success ?? this.success,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginHistory &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.userRole == userRole &&
        other.loginTime == loginTime &&
        other.ipAddress == ipAddress &&
        other.userAgent == userAgent &&
        other.success == success &&
        other.failureReason == failureReason;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        userRole.hashCode ^
        loginTime.hashCode ^
        ipAddress.hashCode ^
        userAgent.hashCode ^
        success.hashCode ^
        failureReason.hashCode;
  }

  @override
  String toString() {
    return 'LoginHistory(id: $id, userId: $userId, userName: $userName, userRole: $userRole, loginTime: $loginTime, ipAddress: $ipAddress, userAgent: $userAgent, success: $success, failureReason: $failureReason)';
  }
}