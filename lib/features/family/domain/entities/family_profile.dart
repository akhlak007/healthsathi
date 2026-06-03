class FamilyProfile {
  final String profileId;
  final String name;
  final String relationship;
  final String? photoUrl;
  final String gender;
  final DateTime dateOfBirth;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicDiseases;
  final String emergencyContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyProfile({
    required this.profileId,
    required this.name,
    required this.relationship,
    this.photoUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicDiseases,
    required this.emergencyContact,
    required this.createdAt,
    required this.updatedAt,
  });
}
