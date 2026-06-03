import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_profile_model.dart';

abstract class FamilyRemoteDataSource {
  Future<List<FamilyProfileModel>> getFamilyProfiles(String userId);
  Future<FamilyProfileModel> getFamilyProfile(String userId, String profileId);
  Future<void> addFamilyProfile(String userId, FamilyProfileModel profile);
  Future<void> updateFamilyProfile(String userId, FamilyProfileModel profile);
  Future<void> deleteFamilyProfile(String userId, String profileId);
}

class FamilyRemoteDataSourceImpl implements FamilyRemoteDataSource {
  final FirebaseFirestore firestore;

  FamilyRemoteDataSourceImpl({required this.firestore});

  @override
  Future<List<FamilyProfileModel>> getFamilyProfiles(String userId) async {
    final querySnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('familyProfiles')
        .get();

    return querySnapshot.docs
        .map((doc) => FamilyProfileModel.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<FamilyProfileModel> getFamilyProfile(String userId, String profileId) async {
    final docSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('familyProfiles')
        .doc(profileId)
        .get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return FamilyProfileModel.fromJson(docSnapshot.data()!);
    } else {
      throw Exception('Family profile not found');
    }
  }

  @override
  Future<void> addFamilyProfile(String userId, FamilyProfileModel profile) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('familyProfiles')
        .doc(profile.profileId)
        .set(profile.toJson());
  }

  @override
  Future<void> updateFamilyProfile(String userId, FamilyProfileModel profile) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('familyProfiles')
        .doc(profile.profileId)
        .update(profile.toJson());
  }

  @override
  Future<void> deleteFamilyProfile(String userId, String profileId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('familyProfiles')
        .doc(profileId)
        .delete();
  }
}
