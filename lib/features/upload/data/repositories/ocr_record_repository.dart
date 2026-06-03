import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/ocr_record.dart';

abstract class OcrRecordRepository {
  /// Upload image or PDF file to Firebase Storage and return its download URL.
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
    // Use the file name as storage reference.
    final parts = filePath.split('/')..removeWhere((e) => e.isEmpty);
    final baseName = parts.isNotEmpty ? parts.last : DateTime.now().millisecondsSinceEpoch.toString();
    
    final basePath = activeProfileId == 'self' 
        ? 'users/$userId/records'
        : 'users/$userId/familyProfiles/$activeProfileId/records';
        
    final ref = _storage.ref().child('$basePath/$baseName');
    final taskSnapshot = await ref.putFile(File(filePath));
    return await ref.getDownloadURL();
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
