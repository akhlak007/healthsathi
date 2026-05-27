import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../upload/domain/entities/ocr_record.dart';

// ---------------------------------------------------------------------------
// Legacy MedicalRecord class – retained for backward compatibility with UI
// widgets that may still reference it. New code should prefer OcrRecord.
// ---------------------------------------------------------------------------

class MedicalRecord {
  final String id;
  final String date;
  final String title;
  final String doctorName;
  final String summary;
  final String category;
  final String? imageUrl;
  final String? pdfUrl;
  final String ocrText;
  final String recordType;
  final List<String> medicines;
  final String notes;

  MedicalRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.doctorName,
    required this.summary,
    required this.category,
    this.imageUrl,
    this.pdfUrl,
    this.ocrText = '',
    this.recordType = '',
    this.medicines = const [],
    this.notes = '',
  });

  /// Convenience factory to create a [MedicalRecord] from an [OcrRecord].
  factory MedicalRecord.fromOcrRecord(OcrRecord record) {
    final formattedDate =
        '${record.date.day.toString().padLeft(2, '0')} '
        '${_monthName(record.date.month)}, '
        '${record.date.year}';

    return MedicalRecord(
      id: record.id,
      date: formattedDate,
      title: record.recordType.isNotEmpty
          ? record.recordType
          : 'Medical Record',
      doctorName: record.doctorName.isNotEmpty
          ? record.doctorName
          : record.hospitalName,
      summary: record.notes.isNotEmpty ? record.notes : record.ocrText,
      category: record.recordType,
      imageUrl: record.imageUrl,
      pdfUrl: record.pdfUrl,
      ocrText: record.ocrText,
      recordType: record.recordType,
      medicines: record.medicines,
      notes: record.notes,
    );
  }

  static String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

// ---------------------------------------------------------------------------
// Real-time Firestore stream provider – replaces hardcoded mock data
// ---------------------------------------------------------------------------

final timelineRecordsProvider = StreamProvider<List<OcrRecord>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value(<OcrRecord>[]);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('records')
      .orderBy('createdAt', descending: true);

  return collectionRef.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => OcrRecord.fromJson(doc.data(), doc.id))
        .toList();
  });
});

// ---------------------------------------------------------------------------
// Convenience provider that maps OcrRecords to legacy MedicalRecord objects
// so existing timeline UI widgets continue to work without changes.
// ---------------------------------------------------------------------------

final medicalRecordsProvider = Provider<AsyncValue<List<MedicalRecord>>>((ref) {
  final asyncRecords = ref.watch(timelineRecordsProvider);
  return asyncRecords.whenData(
    (records) => records.map(MedicalRecord.fromOcrRecord).toList(),
  );
});
