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
  final String? reportId;
  final String? pdfUrl;
  final String? hospitalName;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.reportId,
    this.pdfUrl,
    this.hospitalName,
  });

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? content,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    String? reportId,
    String? pdfUrl,
    String? hospitalName,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      reportId: reportId ?? this.reportId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      hospitalName: hospitalName ?? this.hospitalName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'message': content,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (reportId != null) 'reportId': reportId,
      if (pdfUrl != null) 'pdfUrl': pdfUrl,
      if (hospitalName != null) 'hospitalName': hospitalName,
    };
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawDate = map['createdAt'];
    DateTime date;
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate != null &&
        rawDate.runtimeType.toString().contains('Timestamp')) {
      date = (rawDate as dynamic).toDate();
    } else {
      date = DateTime.now();
    }

    return AppNotificationModel(
      id: docId ?? (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? map['message'] ?? '').toString(),
      type: NotificationType.fromString((map['type'] ?? 'general').toString()),
      createdAt: date,
      isRead: map['isRead'] ?? false,
      reportId: map['reportId']?.toString(),
      pdfUrl: map['pdfUrl']?.toString(),
      hospitalName: map['hospitalName']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppNotificationModel.fromJson(String source) =>
      AppNotificationModel.fromMap(json.decode(source));
}
