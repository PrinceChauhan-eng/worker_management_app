class Salary {
  final int? id;
  final int workerId;
  final String month;          // "yyyy-MM" (e.g., "2025-11")
  final String? year;          // optional if you store separately
  final int? totalDays;
  final int? presentDays;
  final int? absentDays;
  final double? grossSalary;
  final double? totalAdvance;
  final double? netSalary;
  final double totalSalary;    // keep for legacy, same as netSalary
  final bool paid;
  final String? paidDate;      // ISO string or "yyyy-MM-dd"
  final String? pdfUrl;

  Salary({
    this.id,
    required this.workerId,
    required this.month,
    this.year,
    this.totalDays,
    this.presentDays,
    this.absentDays,
    this.grossSalary,
    this.totalAdvance,
    this.netSalary,
    required this.totalSalary,
    required this.paid,
    this.paidDate,
    this.pdfUrl,
  });

  factory Salary.fromMap(Map<String, dynamic> m) {
    double? toD(v) => v == null ? null : (v as num).toDouble();
    int? toI(v) => v == null ? null : (v as num).toInt();

    return Salary(
      id: m['id'] as int?,
      workerId: (m['worker_id'] as num).toInt(),
      month: m['month'] as String,
      year: m['year'] as String?,
      totalDays: toI(m['total_days']),
      presentDays: toI(m['present_days']),
      absentDays: toI(m['absent_days']),
      grossSalary: toD(m['gross_salary']),
      totalAdvance: toD(m['total_advance']),
      netSalary: toD(m['net_salary']),
      totalSalary: toD(m['total_salary']) ?? 0.0,
      paid: (m['paid'] == true || m['paid'] == 1),     // ✅ fix for bool/int
      paidDate: m['paid_date'] as String?,
      pdfUrl: m['pdf_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'worker_id': workerId,
      'month': month,
      if (year != null) 'year': year,
      if (totalDays != null) 'total_days': totalDays,
      if (presentDays != null) 'present_days': presentDays,
      if (absentDays != null) 'absent_days': absentDays,
      if (grossSalary != null) 'gross_salary': grossSalary,
      if (totalAdvance != null) 'total_advance': totalAdvance,
      if (netSalary != null) 'net_salary': netSalary,
      'total_salary': totalSalary,
      'paid': paid,
      if (paidDate != null) 'paid_date': paidDate,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
    };
  }

  Salary copyWith({
    int? id,
    int? workerId,
    String? month,
    String? year,
    int? totalDays,
    int? presentDays,
    int? absentDays,
    double? grossSalary,
    double? totalAdvance,
    double? netSalary,
    double? totalSalary,
    bool? paid,
    String? paidDate,
    String? pdfUrl,
  }) {
    return Salary(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      month: month ?? this.month,
      year: year ?? this.year,
      totalDays: totalDays ?? this.totalDays,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      grossSalary: grossSalary ?? this.grossSalary,
      totalAdvance: totalAdvance ?? this.totalAdvance,
      netSalary: netSalary ?? this.netSalary,
      totalSalary: totalSalary ?? this.totalSalary,
      paid: paid ?? this.paid,
      paidDate: paidDate ?? this.paidDate,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }
}
