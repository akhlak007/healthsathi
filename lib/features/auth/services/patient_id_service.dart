import 'package:cloud_firestore/cloud_firestore.dart';

/// Service responsible for generating and assigning unique Patient IDs.
///
/// ID Format: HS-{YEAR}-{6-DIGIT-SEQ}  e.g. HS-2026-000001
///
/// Uses a Firestore counter document (`counters/patientId`) with a transaction
/// to guarantee uniqueness even under concurrent sign-ups.
class PatientIdService {
  final FirebaseFirestore _firestore;

  PatientIdService(this._firestore);

  static const _counterDoc = 'counters/patientId';

  /// Ensures the user at [uid] has a `patientId`.
  /// If one already exists, this is a no-op.
  /// If not, atomically generates a new one and writes it.
  Future<String> ensurePatientId(String uid) async {
    // 1. Fast path — already has an ID
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final existing = userDoc.data()?['patientId'] as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // 2. Generate a new ID via counter transaction
    final newId = await _generateNextId();

    // 3. Write to user document (merge to avoid overwriting other fields)
    await _firestore.collection('users').doc(uid).set(
      {'patientId': newId},
      SetOptions(merge: true),
    );

    return newId;
  }

  /// Atomically increments the counter and returns the formatted Patient ID.
  Future<String> _generateNextId() async {
    final counterRef = _firestore.doc(_counterDoc);
    final year = DateTime.now().year;

    final newSeq = await _firestore.runTransaction<int>((txn) async {
      final snap = await txn.get(counterRef);
      final current = snap.exists ? (snap.data()?['seq'] as int? ?? 0) : 0;
      final next = current + 1;
      txn.set(counterRef, {'seq': next, 'updatedAt': FieldValue.serverTimestamp()});
      return next;
    });

    final seqStr = newSeq.toString().padLeft(6, '0');
    return 'HS-$year-$seqStr';
  }
}
