import 'dart:convert';

enum NotificationType {
  medication,
  appointment,
  vaccination,
  login,
  upload,
  general;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'medication':
        return NotificationType.medication;
      case 'appointment':
        return NotificationType.appointment;
      case 'vaccination':
        return NotificationType.vaccination;
      case 'login':
        return NotificationType.login;
      case 'upload':
        return NotificationType.upload;
      default:
        return NotificationType.general;
    }
  }
}

class AppNotificationModel {
  final String id;
  final String title;
  final String content;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    return AppNotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: NotificationType.fromString(map['type'] ?? 'general'),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotificationModel.fromJson(String source) =>
      AppNotificationModel.fromMap(json.decode(source));
}
