import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/ocr_record.dart';

abstract class OcrRecordRepository {
  /// Upload image or PDF file to an external storage provider and return its secure URL.
  Future<String> uploadFile({required String userId, required String activeProfileId, required String filePath, required bool isPdf});

  /// Save OCR record data to Firestore.
  Future<void> saveRecord({required String userId, required String activeProfileId, required OcrRecord record});

  /// Stream real‑time records for a user/profile.
  Stream<List<OcrRecord>> watchRecords({required String userId, required String activeProfileId});
}

class FirebaseOcrRecordRepository implements OcrRecordRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseOcrRecordRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadFile({required String userId, required String activeProfileId, required String filePath, required bool isPdf}) async {
    // 1. Verify the source file actually exists before attempting upload.
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception(
        'The selected file no longer exists at "$filePath". '
        'Please pick the image or PDF again.',
      );
    }

    // 2. Upload the prescription image or PDF to Cloudinary.
    final secureUrl = await uploadPrescriptionFile(file);
    if (secureUrl == null) {
      throw Exception(
        'The file upload failed. Please check your internet connection and try again.',
      );
    }

    return secureUrl;
  }

  Future<String?> uploadPrescriptionFile(File file) async {
    const cloudinaryUrl = 'https://api.cloudinary.com/v1_1/dyo018nvq/auto/upload';
    const uploadPreset = 'healthsathi';

    try {
      final uri = Uri.parse(cloudinaryUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final secureUrl = body['secure_url'] as String?;
      return secureUrl;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRecord({required String userId, required String activeProfileId, required OcrRecord record}) async {
    final colRef = activeProfileId == 'self'
        ? _firestore.collection('users').doc(userId).collection('records')
        : _firestore.collection('users').doc(userId).collection('familyProfiles').doc(activeProfileId).collection('records');
    await colRef.doc(record.id).set(record.toJson());
  }

  @override
  Stream<List<OcrRecord>> watchRecords({required String userId, required String activeProfileId}) {
    final colRef = activeProfileId == 'self'
        ? _firestore.collection('users').doc(userId).collection('records')
        : _firestore.collection('users').doc(userId).collection('familyProfiles').doc(activeProfileId).collection('records');
        
    final query = colRef.orderBy('createdAt', descending: true);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OcrRecord.fromJson(doc.data(), doc.id)).toList());
  }
}
