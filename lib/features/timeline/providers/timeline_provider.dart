import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../upload/domain/entities/ocr_record.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/active_profile_provider.dart';

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

final timelineRecordsProvider = StreamProvider<List<OcrRecord>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  final activeProfileId = ref.watch(activeProfileProvider);

  if (authState.isLoading) {
    yield <OcrRecord>[];
    return;
  }

  if (user == null) {
    yield <OcrRecord>[];
    return;
  }

  final collectionRef = activeProfileId == 'self'
      ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('records')
      : FirebaseFirestore.instance.collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId).collection('records');

  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      await for (final snapshot
          in collectionRef.orderBy('createdAt', descending: true).snapshots()) {
        yield snapshot.docs
            .map((doc) => OcrRecord.fromJson(doc.data(), doc.id))
            .toList();
      }
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || attempt == 2) {
        yield <OcrRecord>[];
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
  }
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
