import 'dart:convert';
import 'package:flutter/material.dart';
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
  String _patientId = 'e S-8821';

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

      // Always load the main user's basic profile details (for "Self" card and patient ID)
      final selfDoc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
      if (selfDoc.exists && mounted) {
        final selfData = selfDoc.data()!;
        setState(() {
          _selfProfile = {
            'name': selfData['name'] ?? selfData['fullName'] ?? 'Self',
            'imageUrl': selfData['profileImage'] ?? selfData['photoUrl'],
          };
          _patientId = selfData['patientId'] ?? 'e S-8821';
        });
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

      // Fetch family profiles for the horizontal list
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

    List<String> alerts = [];
    if (_allergiesController.text.isNotEmpty || _chronicController.text.isNotEmpty) {
      if (_allergiesController.text.isNotEmpty) alerts.addAll(_allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
      if (_chronicController.text.isNotEmpty) alerts.addAll(_chronicController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    } else {
      alerts = ['Penicillin Allergy', 'Chronic Hypertension', 'Lactose Intolerance'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Text(
              ' HealthSathi',
              //
              style: TextStyle(
                color: Color(0xFF003D9B),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF003D9B)),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => showProfileSwitcher(context),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: displayImageUrl.startsWith('data:') 
                    ? MemoryImage(base64Decode(displayImageUrl.split(',').last)) as ImageProvider
                    : NetworkImage(displayImageUrl),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                        GestureDetector(
                          onTap: () => showProfileSwitcher(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF003D9B), width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFFD6E4FF),
                              backgroundImage: displayImageUrl.startsWith('data:') 
                                  ? MemoryImage(base64Decode(displayImageUrl.split(',').last)) as ImageProvider
                                  : NetworkImage(displayImageUrl),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => context.push('/edit-profile').then((_) => _loadExistingProfile()),
                        child: Container(
                          margin: const EdgeInsets.only(right: 2, bottom: 2),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003D9B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSelf ? 'Patient ID: ' : 'Relationship: ',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text(
                        isSelf ? patientId : _bioController.text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF003D9B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // My eHealth Info
            _buildSectionHeader('My Health Info', actionText: 'Edit', onActionTap: () => context.push('/edit-profile').then((_) => _loadExistingProfile())),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5EDFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.water_drop_outlined, color: Color(0xFF1E3A8A), size: 28),
                        const SizedBox(height: 16),
                        const Text('Blood Group', style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          bloodGroup,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E3A8A),
                          ),
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
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.monitor_heart_outlined, color: Color(0xFF065F46), size: 28),
                        const SizedBox(height: 16),
                        const Text('Vitals', style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        const Text(
                          'Normal',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Active Alerts
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Active Alerts',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: alerts.map((alert) {
                      // Color coding based on common keywords for visual variety like the screenshot
                      Color bgColor = const Color(0xFFDBEAFE);
                      Color textColor = const Color(0xFF1E40AF);
                      if (alert.toLowerCase().contains('allergy')) {
                        bgColor = const Color(0xFFFFEDD5);
                        textColor = const Color(0xFF9A3412);
                      } else if (alert.toLowerCase().contains('intolerance') || alert.toLowerCase().contains('diabetes')) {
                        bgColor = const Color(0xFF6EE7B7);
                        textColor = const Color(0xFF065F46);
                      }
                      return _buildAlertPill(alert, bgColor, textColor);
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Family Profiles
            _buildSectionHeader('Family Profiles', actionText: 'View All', onActionTap: () => context.push('/family-profiles')),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.push('/add-family-member').then((_) => _loadExistingProfile()),
                    child: _buildAddFamilyCard(),
                  ),
                  const SizedBox(width: 12),
                  // Self profile card
                  if (_selfProfile != null) ...[
                    InkWell(
                      onTap: () {
                        ref.read(activeProfileProvider.notifier).setActiveProfile('self');
                      },
                      borderRadius: BorderRadius.circular(24),
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
                        borderRadius: BorderRadius.circular(24),
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
            const SizedBox(height: 32),

            // Medical Documents Vault
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF273240),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'View your prescriptions and lab reports.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Explore Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Family Members
            _buildSectionHeader('Family Members'),
            const SizedBox(height: 16),
            _buildSettingsTile(Icons.family_restroom, 'Family Members', onTap: () => context.push('/family-profiles')),
            const SizedBox(height: 32),

            // Account Settings
            _buildSectionHeader('Account Settings'),
            const SizedBox(height: 16),
            _buildSettingsTile(Icons.assignment_ind_outlined, 'Personal Information', onTap: () => context.push('/edit-profile').then((_) => _loadExistingProfile())),
            const SizedBox(height: 8),
            _buildSettingsTile(Icons.security_rounded, 'Privacy & Security', onTap: () => context.push('/privacy-security')),
            const SizedBox(height: 8),
            _buildSettingsTile(Icons.settings_outlined, 'Preferences', onTap: () {
               context.push('/settings');
            }),
            const SizedBox(height: 8),
            _buildSettingsTile(
              Icons.logout_rounded,
              'Log Out',
              iconColor: const Color(0xFFDC2626),
              textColor: const Color(0xFFDC2626),
              onTap: () async {
                await ref.read(firebaseAuthProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(activeIndex: 4),
    );
  }

  Widget _buildSectionHeader(String title, {String? actionText, VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF003D9B),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertPill(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildAddFamilyCard() {
    return Container(
      width: 116,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
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
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
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
      width: 116,
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF003D9B) : const Color(0xFFE5EDFF),
        borderRadius: BorderRadius.circular(24),
        border: isActive ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF003D9B).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: imageProvider,
            backgroundColor: isActive ? Colors.white24 : const Color(0xFFD6E4FF),
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
              color: isActive ? Colors.white : const Color(0xFF1E293B),
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
              color: isActive ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {Color? iconColor, Color? textColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFF003D9B), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? const Color(0xFF1E293B),
                ),
              ),
            ),
            if (textColor == null)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}
