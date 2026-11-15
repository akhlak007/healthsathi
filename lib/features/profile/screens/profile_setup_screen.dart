import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/clinical_widgets.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../providers/active_profile_provider.dart';
import '../widgets/profile_switcher_bottom_sheet.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
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

  List<Map<String, dynamic>> _familyProfiles = [];
  Map<String, dynamic>? _selfProfile;
  String _patientId = 'Generating...';

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

      final selfDoc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
      if (selfDoc.exists && mounted) {
        final selfData = selfDoc.data()!;
        final fetchedId = selfData['patientId'] as String?;
        setState(() {
          _selfProfile = {
            'name': selfData['name'] ?? selfData['fullName'] ?? 'Self',
            'imageUrl': selfData['profileImage'] ?? selfData['photoUrl'],
          };
          if (fetchedId != null && fetchedId.isNotEmpty) {
            _patientId = fetchedId;
          } else {
            _patientId = 'Generating...';
          }
        });

        if (fetchedId == null || fetchedId.isEmpty) {
          try {
            final generatedId = await ref.read(patientIdServiceProvider).ensurePatientId(user.uid);
            if (mounted) {
              setState(() {
                _patientId = generatedId;
              });
            }
          } catch (e) {
            debugPrint('Error ensuring patient ID: $e');
          }
        }
      }

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

      final familySnapshot = await ref.read(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .collection('familyProfiles')
          .get();

      if (mounted) {
        setState(() {
          _familyProfiles = familySnapshot.docs.map((d) {
            final fData = d.data();
            return {
              'id': d.id,
              'name': fData['name'] ?? fData['fullName'],
              'relation': fData['relationship'],
              'imageUrl': fData['photoUrl'] ?? fData['profileImage'],
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading existing profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeProfileProvider, (previous, next) {
      if (previous != next) {
        _loadExistingProfile();
      }
    });

    final activeProfileId = ref.watch(activeProfileProvider);
    final isSelf = activeProfileId == 'self';
    final name = _nameController.text.isNotEmpty ? _nameController.text : (isSelf ? 'Arif Ahmed' : 'Family Member');
    final bloodGroup = _selectedBlood ?? 'O+';
    final patientId = _patientId;

    final rawImageUrl = _profileImageUrl;
    final displayImageUrl = rawImageUrl == 'default' || rawImageUrl == null || rawImageUrl.isEmpty
        ? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=003D9B&color=fff'
        : rawImageUrl;

    final userInitials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

    List<String> alerts = [];
    if (_allergiesController.text.isNotEmpty || _chronicController.text.isNotEmpty) {
      if (_allergiesController.text.isNotEmpty) alerts.addAll(_allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      if (_chronicController.text.isNotEmpty) alerts.addAll(_chronicController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    } else {
      alerts = ['Penicillin Allergy', 'Hypertension', 'Lactose Intolerance'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        toolbarHeight: 68,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'HealthSathi',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003D9B),
                    letterSpacing: -0.6,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Your Personal Health Hub',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => showProfileSwitcher(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF003D9B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  userInitials.isNotEmpty ? userInitials : 'AJ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // User Hero Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 12,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: () => showProfileSwitcher(context),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF003D9B), width: 2.5),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: const Color(0xFFE5EDFF),
                            backgroundImage: displayImageUrl.startsWith('data:')
                                ? MemoryImage(base64Decode(displayImageUrl.split(',').last)) as ImageProvider
                                : NetworkImage(displayImageUrl),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/edit-profile').then((_) => _loadExistingProfile()),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003D9B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x20003D9B),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSelf ? 'Patient ID: ' : 'Relation: ',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        Text(
                          isSelf ? patientId : _bioController.text,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF003D9B),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isSelf && patientId.isNotEmpty && patientId != 'Generating...') ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: patientId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Patient ID copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Color(0xFF003D9B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Health Info
            _buildSectionHeader('My Health Info', actionText: 'Edit', onActionTap: () => context.push('/edit-profile').then((_) => _loadExistingProfile())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F172A),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: Color(0xFF003D9B), size: 20),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Blood Group',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bloodGroup,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF003D9B)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F172A),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.monitor_heart_rounded, color: Color(0xFF059669), size: 20),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Vitals',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Normal',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Active Alerts
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Active Alerts',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: alerts.map((alert) {
                      Color bgColor = const Color(0xFFEFF6FF);
                      Color textColor = const Color(0xFF1D4ED8);
                      Color borderColor = const Color(0xFFDBEAFE);
                      if (alert.toLowerCase().contains('allergy')) {
                        bgColor = const Color(0xFFFEF2F2);
                        textColor = const Color(0xFFDC2626);
                        borderColor = const Color(0xFFFECDD3);
                      } else if (alert.toLowerCase().contains('intolerance') || alert.toLowerCase().contains('diabetes')) {
                        bgColor = const Color(0xFFFFFBEB);
                        textColor = const Color(0xFFB45309);
                        borderColor = const Color(0xFFFDE68A);
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          alert,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Family Profiles
            _buildSectionHeader('Family Profiles', actionText: 'View All', onActionTap: () => context.push('/family-profiles')),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/add-family-member').then((_) => _loadExistingProfile()),
                    child: _buildAddFamilyCard(),
                  ),
                  const SizedBox(width: 12),
                  if (_selfProfile != null) ...[
                    InkWell(
                      onTap: () {
                        ref.read(activeProfileProvider.notifier).setActiveProfile('self');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: _buildFamilyCard(
                        _selfProfile!['name'] ?? 'Self',
                        'Me',
                        _selfProfile!['imageUrl'],
                        isActive: activeProfileId == 'self',
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ..._familyProfiles.map((member) {
                    final isMemberActive = activeProfileId == member['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(activeProfileProvider.notifier).setActiveProfile(member['id']);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: _buildFamilyCard(
                          member['name'] ?? '',
                          member['relation'] ?? '',
                          member['imageUrl'],
                          isActive: isMemberActive,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Medical Documents Vault Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF003D9B),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24003D9B),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical Documents Vault',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'View all your prescriptions, lab reports, and records in one secure vault.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.88),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/timeline'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF003D9B),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Explore Vault',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_shared_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Family Members Section
            _buildSectionHeader('Family Members'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => context.push('/family-profiles'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF003D9B), size: 22),
                ),
                title: const Text(
                  'Family Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
              ),
            ),
            const SizedBox(height: 26),

            // Account Settings Section
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildGroupedSettingTile(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Personal Information',
                    onTap: () => context.push('/edit-profile').then((_) => _loadExistingProfile()),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 70),
                  _buildGroupedSettingTile(
                    icon: Icons.security_rounded,
                    title: 'Privacy & Security',
                    onTap: () => context.push('/privacy-security'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9), indent: 70),
                  _buildGroupedSettingTile(
                    icon: Icons.settings_outlined,
                    title: 'Preferences',
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Log Out Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
              ),
              child: ListTile(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
                      content: const Text('Are you sure you want to log out of your account?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref.read(firebaseAuthProvider).signOut();
                      if (context.mounted) context.go('/login');
                    } catch (e) {
                      debugPrint('Logout error: $e');
                    }
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFFDC2626),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFDC2626), size: 22),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 4),
    );
  }

  Widget _buildGroupedSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF003D9B), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        if (actionText != null)
          InkWell(
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF003D9B),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddFamilyCard() {
    return Container(
      width: 110,
      height: 136,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_circle_outline_rounded, color: Color(0xFF64748B), size: 28),
          SizedBox(height: 6),
          Text(
            'Add New',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCard(String name, String relation, String? imageUrl, {bool isActive = false}) {
    ImageProvider? imageProvider;
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'default') {
      if (imageUrl.startsWith('data:')) {
        imageProvider = MemoryImage(base64Decode(imageUrl.split(',').last));
      } else {
        imageProvider = NetworkImage(imageUrl);
      }
    } else {
      imageProvider = NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=${isActive ? "fff&color=003D9B" : "003D9B&color=fff"}');
    }

    return Container(
      width: 110,
      height: 136,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF003D9B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF003D9B) : const Color(0xFFF1F5F9),
          width: isActive ? 2 : 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF003D9B).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: imageProvider,
            backgroundColor: isActive ? Colors.white24 : const Color(0xFFEFF6FF),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            relation,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white.withOpacity(0.85) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
