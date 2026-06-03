import '../../domain/entities/family_profile.dart';
import '../../domain/repositories/family_repository.dart';
import '../datasources/family_remote_data_source.dart';
import '../models/family_profile_model.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  final FamilyRemoteDataSource remoteDataSource;

  FamilyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FamilyProfile>> getFamilyProfiles(String userId) async {
    return await remoteDataSource.getFamilyProfiles(userId);
  }

  @override
  Future<FamilyProfile> getFamilyProfile(String userId, String profileId) async {
    return await remoteDataSource.getFamilyProfile(userId, profileId);
  }

  @override
  Future<void> addFamilyProfile(String userId, FamilyProfile profile) async {
    final profileModel = FamilyProfileModel.fromEntity(profile);
    await remoteDataSource.addFamilyProfile(userId, profileModel);
  }

  @override
  Future<void> updateFamilyProfile(String userId, FamilyProfile profile) async {
    final profileModel = FamilyProfileModel.fromEntity(profile);
    await remoteDataSource.updateFamilyProfile(userId, profileModel);
  }

  @override
  Future<void> deleteFamilyProfile(String userId, String profileId) async {
    await remoteDataSource.deleteFamilyProfile(userId, profileId);
  }
}
