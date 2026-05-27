import 'package:cloud_firestore/cloud_firestore.dart';

class OcrRecord {
  final String id;
  final String recordType;
  final String doctorName;
  final String hospitalName;
  final DateTime date;
  final String ocrText;
  final String? imageUrl;
  final String? pdfUrl;
  final List<String> medicines;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool timelineVisible;
  final String userId;

  OcrRecord({
    required this.id,
    required this.recordType,
    required this.doctorName,
    required this.hospitalName,
    required this.date,
    required this.ocrText,
    this.imageUrl,
    this.pdfUrl,
    required this.medicines,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.timelineVisible,
    required this.userId,
  });

  factory OcrRecord.fromJson(Map<String, dynamic> json, String id) {
    final Timestamp createdTs = json['createdAt'] as Timestamp;
    final Timestamp updatedTs = json['updatedAt'] as Timestamp;
    return OcrRecord(
      id: id,
      recordType: json['recordType'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      hospitalName: json['hospitalName'] as String? ?? '',
      date: (json['date'] as Timestamp).toDate(),
      ocrText: json['ocrText'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      medicines: List<String>.from(json['medicines'] ?? []),
      notes: json['notes'] as String? ?? '',
      createdAt: createdTs.toDate(),
      updatedAt: updatedTs.toDate(),
      timelineVisible: json['timelineVisible'] as bool? ?? true,
      userId: json['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'recordType': recordType,
        'doctorName': doctorName,
        'hospitalName': hospitalName,
        'date': Timestamp.fromDate(date),
        'ocrText': ocrText,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (pdfUrl != null) 'pdfUrl': pdfUrl,
        'medicines': medicines,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'timelineVisible': timelineVisible,
        'userId': userId,
      };
}
