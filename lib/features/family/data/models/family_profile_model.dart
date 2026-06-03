import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/family_profile.dart';

class FamilyProfileModel extends FamilyProfile {
  const FamilyProfileModel({
    required super.profileId,
    required super.name,
    required super.relationship,
    super.photoUrl,
    required super.gender,
    required super.dateOfBirth,
    required super.bloodGroup,
    required super.allergies,
    required super.chronicDiseases,
    required super.emergencyContact,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FamilyProfileModel.fromJson(Map<String, dynamic> json) {
    return FamilyProfileModel(
      profileId: json['profileId'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      photoUrl: json['photoUrl'] as String?,
      gender: json['gender'] as String,
      dateOfBirth: (json['dateOfBirth'] as Timestamp).toDate(),
      bloodGroup: json['bloodGroup'] as String,
      allergies: List<String>.from(json['allergies'] ?? []),
      chronicDiseases: List<String>.from(json['chronicDiseases'] ?? []),
      emergencyContact: json['emergencyContact'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory FamilyProfileModel.fromEntity(FamilyProfile entity) {
    return FamilyProfileModel(
      profileId: entity.profileId,
      name: entity.name,
      relationship: entity.relationship,
      photoUrl: entity.photoUrl,
      gender: entity.gender,
      dateOfBirth: entity.dateOfBirth,
      bloodGroup: entity.bloodGroup,
      allergies: entity.allergies,
      chronicDiseases: entity.chronicDiseases,
      emergencyContact: entity.emergencyContact,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'name': name,
      'relationship': relationship,
      'photoUrl': photoUrl,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'emergencyContact': emergencyContact,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
