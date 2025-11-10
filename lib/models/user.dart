class User {
  final int? id;
  final String name;
  final String phone;
  final String password;
  final String role; // admin or worker
  final double wage;
  final String joinDate;
  final double? workLocationLatitude; // GPS latitude of work location
  final double? workLocationLongitude; // GPS longitude of work location
  final String? workLocationAddress; // Human-readable address
  final double? locationRadius; // Allowed radius in meters (default: 100)
  final String? profilePhoto; // Path to profile photo
  final String? idProof; // Path to ID proof
  final String? address; // Full address
  final String? email; // Email address
  final bool? emailVerified; // Email verification status
  final String? emailVerificationCode; // Temporary OTP code
  final String? designation; // Worker's designation/role

  User({
    this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    required this.wage,
    required this.joinDate,
    this.workLocationLatitude,
    this.workLocationLongitude,
    this.workLocationAddress,
    this.locationRadius = 100.0,
    this.profilePhoto,
    this.idProof,
    this.address,
    this.email,
    this.emailVerified = false,
    this.emailVerificationCode,
    this.designation, // Add designation parameter
  });

  // Profile completion percentage
  int get profileCompletionPercentage {
    int totalFields = 11; // Updated total to include designation
    int completedFields = 3; // name, phone, role always present
    
    if (profilePhoto != null && profilePhoto!.isNotEmpty) completedFields++;
    if (idProof != null && idProof!.isNotEmpty) completedFields++;
    if (address != null && address!.isNotEmpty) completedFields++;
    if (email != null && email!.isNotEmpty) completedFields++;
    if (emailVerified == true) completedFields++; // Bonus for verification
    if (workLocationAddress != null && workLocationAddress!.isNotEmpty) completedFields++;
    if (wage > 0) completedFields++;
    if (designation != null && designation!.isNotEmpty) completedFields++; // Add designation
    
    return ((completedFields / totalFields) * 100).round();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
      'wage': wage,
      'join_date': joinDate,
      'work_location_latitude': workLocationLatitude,
      'work_location_longitude': workLocationLongitude,
      'work_location_address': workLocationAddress,
      'location_radius': locationRadius,
      'profile_photo': profilePhoto,
      'id_proof': idProof,
      'address': address,
      'email': email,
      'email_verified': emailVerified == true ? 1 : 0,
      'email_verification_code': emailVerificationCode,
      'designation': designation, // Add designation to map
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
      joinDate: map['join_date'] ?? map['joinDate'],
      workLocationLatitude: map['work_location_latitude'] ?? map['workLocationLatitude'],
      workLocationLongitude: map['work_location_longitude'] ?? map['workLocationLongitude'],
      workLocationAddress: map['work_location_address'] ?? map['workLocationAddress'],
      locationRadius: map['location_radius'] ?? map['locationRadius'] ?? 100.0,
      profilePhoto: map['profile_photo'] ?? map['profilePhoto'],
      idProof: map['id_proof'] ?? map['idProof'],
      address: map['address'],
      email: map['email'],
      emailVerified: (map['email_verified'] ?? map['emailVerified']) == 1,
      emailVerificationCode: map['email_verification_code'] ?? map['emailVerificationCode'],
      designation: map['designation'], // Add designation from map
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
    double? workLocationLatitude,
    double? workLocationLongitude,
    String? workLocationAddress,
    double? locationRadius,
    String? profilePhoto,
    String? idProof,
    String? address,
    String? email,
    bool? emailVerified,
    String? emailVerificationCode,
    String? designation, // Add designation parameter
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      wage: wage ?? this.wage,
      joinDate: joinDate ?? this.joinDate,
      workLocationLatitude: workLocationLatitude ?? this.workLocationLatitude,
      workLocationLongitude: workLocationLongitude ?? this.workLocationLongitude,
      workLocationAddress: workLocationAddress ?? this.workLocationAddress,
      locationRadius: locationRadius ?? this.locationRadius,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      idProof: idProof ?? this.idProof,
      address: address ?? this.address,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      emailVerificationCode: emailVerificationCode ?? this.emailVerificationCode,
      designation: designation ?? this.designation, // Add designation parameter
    );
  }
}