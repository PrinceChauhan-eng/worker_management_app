class User {
  final int? id;
  final String name;
  final String phone;
  final String password;
  final String role; // admin or worker
  final double wage;
  final String joinDate;

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    required this.wage,
    required this.joinDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      'wage': wage,
      'joinDate': joinDate,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      password: map['password'],
      role: map['role'],
      wage: map['wage'],
      joinDate: map['joinDate'],
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? phone,
    String? password,
    String? role,
    double? wage,
    String? joinDate,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      wage: wage ?? this.wage,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}