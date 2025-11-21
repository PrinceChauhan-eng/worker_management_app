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
      'present': present, // Keep as boolean to match database column type
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    // Handle the present field which might be stored as int (1/0) or bool
    bool presentValue;
    final presentData = map['present'];
    
    if (presentData is int) {
      presentValue = presentData == 1;
    } else if (presentData is bool) {
      presentValue = presentData;
    } else {
      presentValue = false;
    }
    
    return Attendance(
      id: map['id'],
      workerId: map['worker_id'] ?? map['workerId'],
      date: map['date'],
      inTime: map['in_time'] ?? map['inTime'] ?? '',
      outTime: map['out_time'] ?? map['outTime'] ?? '',
      present: presentValue,
    );
  }
  
  // Add a named constructor for creating attendance objects
  Attendance.create({
    int? id,
    required int workerId,
    required String date,
    required String inTime,
    required String outTime,
    required bool present,
  }) : this(
          id: id,
          workerId: workerId,
          date: date,
          inTime: inTime,
          outTime: outTime,
          present: present,
        );
}