import 'package:cloud_firestore/cloud_firestore.dart';

class OcrRecord {
  final String id;
  final String recordType;
  final String recordLabel;
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
  final String source;
  final String? hospitalId;
  final bool verifiedByHospital;

  OcrRecord({
    required this.id,
    required this.recordType,
    required this.recordLabel,
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
    this.source = 'patient',
    this.hospitalId,
    this.verifiedByHospital = false,
  });

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  factory OcrRecord.fromJson(Map<String, dynamic> json, String id) {
    return OcrRecord(
      id: id,
      recordType: json['recordType'] as String? ?? '',
      recordLabel: json['recordLabel'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      hospitalName: json['hospitalName'] as String? ?? '',
      date: _parseDate(json['date']),
      ocrText: json['ocrText'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      pdfUrl: json['pdfUrl'] as String?,
      medicines: List<String>.from(json['medicines'] ?? []),
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      timelineVisible: json['timelineVisible'] as bool? ?? true,
      userId: json['userId'] as String? ?? '',
      source: json['source'] as String? ?? 'patient',
      hospitalId: json['hospitalId'] as String?,
      verifiedByHospital: json['verifiedByHospital'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'recordType': recordType,
        'recordLabel': recordLabel,
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
        'source': source,
        if (hospitalId != null) 'hospitalId': hospitalId,
        'verifiedByHospital': verifiedByHospital,
      };
}
