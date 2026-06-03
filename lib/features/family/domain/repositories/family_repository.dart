import '../entities/family_profile.dart';

abstract class FamilyRepository {
  Future<List<FamilyProfile>> getFamilyProfiles(String userId);
  Future<FamilyProfile> getFamilyProfile(String userId, String profileId);
  Future<void> addFamilyProfile(String userId, FamilyProfile profile);
  Future<void> updateFamilyProfile(String userId, FamilyProfile profile);
  Future<void> deleteFamilyProfile(String userId, String profileId);
}
