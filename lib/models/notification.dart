class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String type; // 'salary', 'advance', 'attendance', 'system'
  final int userId; // Target user ID
  final String userRole; // 'admin' or 'worker'
  final bool isRead;
  final String createdAt;
  final String? relatedId; // ID of related entity (salary, advance, etc.)

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    required this.userRole,
    this.isRead = false,
    required this.createdAt,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'userId': userId,
      'userRole': userRole,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt,
      'relatedId': relatedId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: map['type'],
      userId: map['userId'],
      userRole: map['userRole'],
      isRead: map['isRead'] == 1,
      createdAt: map['createdAt'],
      relatedId: map['relatedId'],
    );
  }
}