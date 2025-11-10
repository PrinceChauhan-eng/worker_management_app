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
  final String? pdfUrl;

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
    this.pdfUrl,
  }) : totalSalary = totalSalary ?? netSalary ?? 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'month': month,
      'year': year,
      'total_days': totalDays,
      'present_days': presentDays,
      'absent_days': absentDays,
      'gross_salary': grossSalary,
      'total_advance': totalAdvance,
      'net_salary': netSalary,
      'total_salary': totalSalary,
      'paid': paid ? 1 : 0,
      'paid_date': paidDate,
      'pdf_url': pdfUrl,
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'],
      workerId: map['worker_id'] ?? map['workerId'],
      month: map['month'],
      year: map['year'],
      totalDays: map['total_days'] ?? map['totalDays'],
      presentDays: map['present_days'] ?? map['presentDays'],
      absentDays: map['absent_days'] ?? map['absentDays'],
      grossSalary: map['gross_salary'] ?? map['grossSalary'],
      totalAdvance: map['total_advance'] ?? map['totalAdvance'],
      netSalary: map['net_salary'] ?? map['netSalary'],
      totalSalary: map['total_salary'] ?? map['totalSalary'],
      paid: (map['paid'] ?? map['paid']) == 1,
      paidDate: map['paid_date'] ?? map['paidDate'],
      pdfUrl: map['pdf_url'] ?? map['pdfUrl'],
    );
  }
}