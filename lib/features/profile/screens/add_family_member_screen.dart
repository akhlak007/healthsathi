import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/clinical_widgets.dart';

class AddFamilyMemberScreen extends ConsumerStatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  ConsumerState<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends ConsumerState<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _dobController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicController = TextEditingController();
  final _emergencyController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedBlood;
  Uint8List? _profileImageBytes;
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)), // default to 10 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveFamilyMember() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a gender')));
      return;
    }
    if (_selectedBlood == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a blood group')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date of birth')));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileId = FirebaseFirestore.instance.collection('users').doc().id; // generate ID
      String? photoUrl;

      // Encode image as base64 data URL (avoids Firebase Storage CORS issues on web)
      if (_profileImageBytes != null) {
        final base64Str = base64Encode(_profileImageBytes!);
        photoUrl = 'data:image/jpeg;base64,$base64Str';
      }

      // Save to Firestore subcollection
      final newMemberData = {
        'profileId': profileId,
        'name': _nameController.text.trim(),
        'relationship': _relationController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': Timestamp.fromDate(_selectedDate!),
        'bloodGroup': _selectedBlood,
        'allergies': _allergiesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'chronicDiseases': _chronicController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'emergencyContact': _emergencyController.text.trim(),
        'photoUrl': photoUrl,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('familyProfiles')
          .doc(profileId)
          .set(newMemberData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family member added successfully.')),
        );
        context.pop(); // Return to Family Members Screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add member: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Family Member', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                    backgroundImage: _profileImageBytes != null
                                        ? MemoryImage(_profileImageBytes!)
                                        : null,
                                    child: _profileImageBytes == null
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
                          const Text(
                            'Upload Photo', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Member Details',
                            showDivider: true,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputLabel('FULL NAME'),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'e.g. John Doe',
                              prefixIcon: const Icon(Icons.person_outline, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Full Name is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildInputLabel('RELATIONSHIP'),
                          TextFormField(
                            controller: _relationController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Spouse, Child, Parent',
                              prefixIcon: const Icon(Icons.family_restroom, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Relationship is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputLabel('GENDER'),
                          Wrap(
                            spacing: 8,
                            children: ['Male', 'Female', 'Other'].map((gender) {
                              final selected = _selectedGender == gender;
                              return ChoiceChip(
                                label: Text(gender, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                                selected: selected,
                                selectedColor: AppColors.primary.withOpacity(0.12),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.onSurfaceVariant),
                                side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedGender = gender);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputLabel('DATE OF BIRTH'),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              hintText: 'YYYY-MM-DD',
                              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Date of Birth is required';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Medical Information',
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
                          
                          _buildInputLabel('ALLERGIES'),
                          TextFormField(
                            controller: _allergiesController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Comma separated e.g. Peanuts, Penicillin',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputLabel('CHRONIC DISEASES'),
                          TextFormField(
                            controller: _chronicController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Comma separated e.g. Asthma, Diabetes',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    MedicalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Emergency Contact',
                            showDivider: true,
                          ),
                          const SizedBox(height: 16),
                          
                          _buildInputLabel('EMERGENCY CONTACT PHONE'),
                          TextFormField(
                            controller: _emergencyController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '017XXXXXXXX',
                              prefixIcon: const Icon(Icons.phone, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Emergency Contact is required';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ClinicalButton(
                      label: 'Save Family Member',
                      onPressed: _saveFamilyMember,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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
