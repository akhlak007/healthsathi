import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/clinical_widgets.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../providers/active_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedBlood;
  String? _profileImageUrl;

  final _allergiesController = TextEditingController();
  final _chronicController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user != null) {
      final activeProfileId = ref.read(activeProfileProvider);
      final isSelf = activeProfileId == 'self';

      final docPath = isSelf
          ? ref.read(firestoreProvider).collection('users').doc(user.uid)
          : ref.read(firestoreProvider).collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId);

      final doc = await docPath.get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? data['fullName'] ?? '';
          _bioController.text = data['bio'] ?? (isSelf ? '' : data['relationship'] ?? '');
          _profileImageUrl = data['profileImage'] ?? data['photoUrl'];
          
          if (data['age'] != null) _ageController.text = data['age'];
          if (data['gender'] != null) _selectedGender = data['gender'];
          if (data['bloodGroup'] != null) _selectedBlood = data['bloodGroup'];
          
          if (data['allergies'] != null) {
            _allergiesController.text = data['allergies'] is List ? (data['allergies'] as List).join(', ') : data['allergies'];
          } else {
             _allergiesController.clear();
          }
          if (data['chronicDiseases'] != null) {
            _chronicController.text = data['chronicDiseases'] is List ? (data['chronicDiseases'] as List).join(', ') : data['chronicDiseases'];
          } else {
            _chronicController.clear();
          }
          
          if (data['emergencyContactName'] != null) _emergencyNameController.text = data['emergencyContactName'];
          if (data['emergencyContactPhone'] != null) _emergencyPhoneController.text = data['emergencyContactPhone'];
          
          if (!isSelf && data['emergencyContact'] != null) {
            _emergencyPhoneController.text = data['emergencyContact'];
            _emergencyNameController.clear();
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _profileImageUrl = 'data:image/jpeg;base64,$base64String';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeProfileProvider, (previous, next) {
      if (previous != next) {
        _loadExistingProfile();
      }
    });

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile photo upload area
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
                            boxShadow: [
                              const BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.background,
                            backgroundImage: _profileImageUrl != null && _profileImageUrl != 'default'
                                ? (_profileImageUrl!.startsWith('data:') 
                                    ? MemoryImage(base64Decode(_profileImageUrl!.split(',').last)) as ImageProvider
                                    : NetworkImage(_profileImageUrl!))
                                : null,
                            child: _profileImageUrl == null || _profileImageUrl == 'default' 
                                ? const Icon(Icons.person_rounded, size: 54, color: AppColors.primary)
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Patient Photo', 
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Card 1: Basic Information
            MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Basic Information',
                    showDivider: true,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('FULL NAME'),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('SHORT BIO'),
                  TextField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'A short description about yourself...',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24.0),
                        child: Icon(Icons.info_outline, size: 18),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('AGE (IN YEARS)'),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('GENDER'),
                  Row(
                    children: ['Male', 'Female', 'Other'].map((gender) {
                      final selected = _selectedGender == gender;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(gender, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                          selected: selected,
                          selectedColor: AppColors.primary.withOpacity(0.12),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
                          side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
                          onSelected: (val) {
                            if (val) setState(() => _selectedGender = gender);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 2: Clinical Details
            MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Medical Summary',
                    showDivider: true,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('BLOOD GROUP'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((blood) {
                      final selected = _selectedBlood == blood;
                      return ChoiceChip(
                        label: Text(blood, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                        selected: selected,
                        selectedColor: AppColors.primary.withOpacity(0.1),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
                        side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
                        onSelected: (val) {
                          if (val) setState(() => _selectedBlood = blood);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildInputLabel('ALLERGIES & DRUG SENSITIVITIES'),
                  TextField(
                    controller: _allergiesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Penicillin, Peanuts, Latex. Leave empty if none.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('CHRONIC DISEASES & COMPLETED SURGERIES'),
                  TextField(
                    controller: _chronicController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Hypertension, Diabetes Type 2, Asthma.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 3: Emergency Coordinates
            MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Emergency contact coordinates',
                    showDivider: true,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('CONTACT RESPONDER NAME'),
                  TextField(
                    controller: _emergencyNameController,
                    decoration: InputDecoration(
                      hintText: "Relationship & Full Name (e.g. Mother - Salma Ahmed)",
                      prefixIcon: const Icon(Icons.family_restroom_outlined, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('RESPONDER MOBILE PHONE'),
                  TextField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "017XXXXXXXX",
                      prefixIcon: const Icon(Icons.phone, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ClinicalButton(
              label: 'Save Profile',
              onPressed: () async {
                // Validate required fields
                if (_selectedGender == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your gender')),
                  );
                  return;
                }
                if (_selectedBlood == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your blood group')),
                  );
                  return;
                }
                if (_emergencyNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency contact name is required')),
                  );
                  return;
                }
                if (_emergencyPhoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency contact phone is required')),
                  );
                  return;
                }

                final user = ref.read(firebaseAuthProvider).currentUser;
                if (user != null) {
                  try {
                    final activeProfileId = ref.read(activeProfileProvider);
                    final isSelf = activeProfileId == 'self';

                    final docPath = isSelf
                        ? ref.read(firestoreProvider).collection('users').doc(user.uid)
                        : ref.read(firestoreProvider).collection('users').doc(user.uid).collection('familyProfiles').doc(activeProfileId);

                    Map<String, dynamic> updateData = {
                      'name': _nameController.text.trim(),
                      'fullName': _nameController.text.trim(),
                      'age': _ageController.text.trim(),
                      'gender': _selectedGender,
                      'bloodGroup': _selectedBlood,
                      'allergies': _allergiesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      'chronicDiseases': _chronicController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      'updatedAt': DateTime.now().toIso8601String(),
                    };
                    
                    if (isSelf) {
                       updateData['bio'] = _bioController.text.trim();
                       if (_profileImageUrl != null) updateData['profileImage'] = _profileImageUrl;
                       updateData['emergencyContactName'] = _emergencyNameController.text.trim();
                       updateData['emergencyContactPhone'] = _emergencyPhoneController.text.trim();
                    } else {
                       updateData['relationship'] = _bioController.text.trim();
                       if (_profileImageUrl != null) updateData['photoUrl'] = _profileImageUrl;
                       updateData['emergencyContact'] = _emergencyPhoneController.text.trim();
                       // Also save names if preferred, but AddFamilyMemberScreen uses emergencyContact.
                       updateData['emergencyContactName'] = _emergencyNameController.text.trim();
                       updateData['emergencyContactPhone'] = _emergencyPhoneController.text.trim();
                    }

                    await docPath.set(updateData, SetOptions(merge: true));
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully.')),
                      );
                      context.pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save profile: $e')),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
