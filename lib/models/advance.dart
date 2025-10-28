class Advance {
  final int? id;
  final int workerId;
  final double amount;
  final String date;

  Advance({
    this.id,
    required this.workerId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'amount': amount,
      'date': date,
    };
  }

  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['id'],
      workerId: map['workerId'],
      amount: map['amount'],
      date: map['date'],
    );
  }
}