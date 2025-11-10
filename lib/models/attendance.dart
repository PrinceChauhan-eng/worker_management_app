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
      'worker_id': workerId,
      'date': date,
      'in_time': inTime,
      'out_time': outTime,
      'present': present ? 1 : 0,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      workerId: map['worker_id'] ?? map['workerId'],
      date: map['date'],
      inTime: map['in_time'] ?? map['inTime'],
      outTime: map['out_time'] ?? map['outTime'],
      present: (map['present'] ?? map['present']) == 1,
    );
  }
}