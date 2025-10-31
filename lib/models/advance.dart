class Advance {
  final int? id;
  final int workerId;
  final double amount;
  final String date;
  final String? purpose; // Medical, Personal, Emergency, Family, Education, Other
  final String? note; // Detailed explanation
  final String status; // pending, approved, rejected, deducted
  final int? deductedFromSalaryId; // Link to salary record when deducted
  final int? approvedBy; // Admin ID who approved
  final String? approvedDate; // Timestamp of approval

  Advance({
    this.id,
    required this.workerId,
    required this.amount,
    required this.date,
    this.purpose,
    this.note,
    this.status = 'pending',
    this.deductedFromSalaryId,
    this.approvedBy,
    this.approvedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'amount': amount,
      'date': date,
      'purpose': purpose,
      'note': note,
      'status': status,
      'deductedFromSalaryId': deductedFromSalaryId,
      'approvedBy': approvedBy,
      'approvedDate': approvedDate,
    };
  }

  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['id'],
      workerId: map['workerId'],
      amount: map['amount'],
      date: map['date'],
      purpose: map['purpose'],
      note: map['note'],
      status: map['status'] ?? 'pending',
      deductedFromSalaryId: map['deductedFromSalaryId'],
      approvedBy: map['approvedBy'],
      approvedDate: map['approvedDate'],
    );
  }

  // Helper method to check if advance is pending
  bool get isPending => status == 'pending';
  
  // Helper method to check if advance is approved
  bool get isApproved => status == 'approved';
  
  // Helper method to check if advance is deducted
  bool get isDeducted => status == 'deducted';
  
  // Helper method to check if advance is rejected
  bool get isRejected => status == 'rejected';
}