class Attendance {
  final int? id;
  final int workerId;
  final String date;
  final String inTime;
  final String outTime;
  final bool present;

  Attendance({
    this.id,
    required this.workerId,
    required this.date,
    required this.inTime,
    required this.outTime,
    required this.present,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date,
      'inTime': inTime,
      'outTime': outTime,
      'present': present ? 1 : 0,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      workerId: map['workerId'],
      date: map['date'],
      inTime: map['inTime'],
      outTime: map['outTime'],
      present: map['present'] == 1,
    );
  }
}