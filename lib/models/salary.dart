class Salary {
  final int? id;
  final int workerId;
  final String month;
  final String? year;
  final int totalDays;
  final int? presentDays;
  final int? absentDays;
  final double? grossSalary;
  final double? totalAdvance;
  final double? netSalary;
  final double totalSalary; // For backward compatibility
  final bool paid;
  final String? paidDate;

  Salary({
    this.id,
    required this.workerId,
    required this.month,
    this.year,
    required this.totalDays,
    this.presentDays,
    this.absentDays,
    this.grossSalary,
    this.totalAdvance,
    this.netSalary,
    double? totalSalary,
    required this.paid,
    this.paidDate,
  }) : totalSalary = totalSalary ?? netSalary ?? 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'month': month,
      'year': year,
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'grossSalary': grossSalary,
      'totalAdvance': totalAdvance,
      'netSalary': netSalary,
      'totalSalary': totalSalary,
      'paid': paid ? 1 : 0,
      'paidDate': paidDate,
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'],
      workerId: map['workerId'],
      month: map['month'],
      year: map['year'],
      totalDays: map['totalDays'],
      presentDays: map['presentDays'],
      absentDays: map['absentDays'],
      grossSalary: map['grossSalary'],
      totalAdvance: map['totalAdvance'],
      netSalary: map['netSalary'],
      totalSalary: map['totalSalary'],
      paid: map['paid'] == 1,
      paidDate: map['paidDate'],
    );
  }
}