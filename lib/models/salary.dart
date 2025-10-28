class Salary {
  final int? id;
  final int workerId;
  final String month;
  final int totalDays;
  final double totalSalary;
  final bool paid;

  Salary({
    this.id,
    required this.workerId,
    required this.month,
    required this.totalDays,
    required this.totalSalary,
    required this.paid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'month': month,
      'totalDays': totalDays,
      'totalSalary': totalSalary,
      'paid': paid ? 1 : 0,
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'],
      workerId: map['workerId'],
      month: map['month'],
      totalDays: map['totalDays'],
      totalSalary: map['totalSalary'],
      paid: map['paid'] == 1,
    );
  }
}