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
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _chronicController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    try {
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
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 250,
      maxHeight: 250,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);
      if (!mounted) return;
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
    final name = _nameController.text.isNotEmpty ? _nameController.text : 'User';
    final rawImageUrl = _profileImageUrl;
    final displayImageUrl = rawImageUrl == 'default' || rawImageUrl == null || rawImageUrl.isEmpty
        ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=003D9B&color=fff'
        : rawImageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
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
            MedicalCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                              boxShadow: [
                                const BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: displayImageUrl.startsWith('data:')
                                  ? MemoryImage(base64Decode(displayImageUrl.split(',').last)) as ImageProvider
                                  : NetworkImage(displayImageUrl),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Upload Patient Photo',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  _buildInputLabel('SHORT BIO'),
                  TextField(
                      controller: _bioController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Short Bio',
                        hintText: 'A short description about yourself... ',
                        prefixIcon: const Icon(Icons.info_outline, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('AGE (IN YEARS)'),
                  TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Age',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
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
                         label: Text(blood, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                         selected: selected,
                         selectedColor: AppColors.primary.withOpacity(0.15),
                         checkmarkColor: AppColors.primary,
                         labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
                         side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant, width: 1),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        labelText: 'Allergies & Drug Sensitivities',
                        hintText: 'e.g. Penicillin, Peanuts, Latex',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('CHRONIC DISEASES & COMPLETED SURGERIES'),
                  TextField(
                      controller: _chronicController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Chronic Diseases & Surgeries',
                        hintText: 'e.g. Hypertension, Diabetes Type 2, Asthma',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
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
                        labelText: 'Contact Responder Name',
                        hintText: "Relationship & Full Name (e.g. Mother - Salma Ahmed)",
                        prefixIcon: const Icon(Icons.family_restroom_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  _buildInputLabel('RESPONDER MOBILE PHONE'),
                  TextField(
                      controller: _emergencyPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Responder Mobile Phone',
                        hintText: "017XXXXXXXX",
                        prefixIcon: const Icon(Icons.phone, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
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

                    await docPath.set(updateData, SetOptions(merge: true))
                        .timeout(const Duration(seconds: 15), onTimeout: () {
                          throw Exception('Connection timed out. Please check your internet connection.');
                        });
                    
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
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 10.5,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
