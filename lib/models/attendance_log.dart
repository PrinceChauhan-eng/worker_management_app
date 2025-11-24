class AttendanceLog {
  final int? id;
  final int workerId;
  final String date;
  final String punchTime;
  final String punchType; // 'login' or 'logout'
  final double? locationLatitude;
  final double? locationLongitude;
  final String? locationAddress;
  final String createdAt;
  final String updatedAt;

  AttendanceLog({
    this.id,
    required this.workerId,
    required this.date,
    required this.punchTime,
    required this.punchType,
    this.locationLatitude,
    this.locationLongitude,
    this.locationAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'punch_time': punchTime,
      'punch_type': punchType,
      'location_latitude': locationLatitude,
      'location_longitude': locationLongitude,
      'location_address': locationAddress,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AttendanceLog.fromMap(Map<String, dynamic> map) {
    return AttendanceLog(
      id: map['id'],
      workerId: map['worker_id'] ?? map['workerId'],
      date: map['date'],
      punchTime: map['punch_time'] ?? map['punchTime'] ?? '',
      punchType: map['punch_type'] ?? map['punchType'] ?? '',
      locationLatitude: map['location_latitude'] ?? map['locationLatitude'],
      locationLongitude: map['location_longitude'] ?? map['locationLongitude'],
      locationAddress: map['location_address'] ?? map['locationAddress'],
      createdAt: map['created_at'] ?? map['createdAt'] ?? '',
      updatedAt: map['updated_at'] ?? map['updatedAt'] ?? '',
    );
  }
}