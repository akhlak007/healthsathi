import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/ocr_record.dart';
import '../../../../core/services/cloudinary_service.dart';

abstract class OcrRecordRepository {
  /// Upload image or PDF file to Cloudinary and return its secure URL.
  Future<String> uploadFile({
    required String userId,
    required String activeProfileId,
    Uint8List? fileBytes,
    String? filePath,
    String? fileName,
    required bool isPdf,
  });

  /// Save OCR record data to Firestore.
  Future<void> saveRecord({
    required String userId,
    required String activeProfileId,
    required OcrRecord record,
  });

  /// Stream real‑time records for a user/profile.
  Stream<List<OcrRecord>> watchRecords({
    required String userId,
    required String activeProfileId,
  });
}

class CloudinaryOcrRecordRepository implements OcrRecordRepository {
  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  CloudinaryOcrRecordRepository({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinary,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cloudinary = cloudinary ?? CloudinaryService();

  @override
  Future<String> uploadFile({
    required String userId,
    required String activeProfileId,
    Uint8List? fileBytes,
    String? filePath,
    String? fileName,
    required bool isPdf,
  }) async {
    Uint8List? finalBytes = fileBytes;

    if (finalBytes == null && filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          finalBytes = await file.readAsBytes();
        }
      } catch (e) {
        print('[Cloudinary] Could not read file from path: $e');
      }
    }

    if (finalBytes == null) {
      throw Exception('Could not read file data. Please try selecting the file again.');
    }

    final ext = isPdf
        ? 'pdf'
        : (fileName?.split('.').last.toLowerCase()
                ?? filePath?.split('.').last.toLowerCase()
                ?? 'jpg');

    String rawName = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final sanitizedName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');

    try {
      print('[Cloudinary] Preparing to upload record: user=$userId profile=$activeProfileId file=$sanitizedName');
      final uploadUrl = await _cloudinary.uploadFile(
        bytes: finalBytes,
        fileName: sanitizedName,
        isPdf: isPdf,
      );
      print('[Cloudinary] Upload completed successfully. URL: $uploadUrl');
      return uploadUrl;
    } catch (e) {
      print('[Cloudinary Error] Failed to upload record: $e');
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  @override
  Future<void> saveRecord({
    required String userId,
    required String activeProfileId,
    required OcrRecord record,
  }) async {
    final colRef = activeProfileId == 'self'
        ? _firestore.collection('users').doc(userId).collection('records')
        : _firestore
            .collection('users')
            .doc(userId)
            .collection('familyProfiles')
            .doc(activeProfileId)
            .collection('records');
    await colRef.doc(record.id).set(record.toJson());
  }

  @override
  Stream<List<OcrRecord>> watchRecords({
    required String userId,
    required String activeProfileId,
  }) {
    final colRef = activeProfileId == 'self'
        ? _firestore.collection('users').doc(userId).collection('records')
        : _firestore
            .collection('users')
            .doc(userId)
            .collection('familyProfiles')
            .doc(activeProfileId)
            .collection('records');

    final query = colRef.orderBy('createdAt', descending: true);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OcrRecord.fromJson(doc.data(), doc.id)).toList());
  }
}
