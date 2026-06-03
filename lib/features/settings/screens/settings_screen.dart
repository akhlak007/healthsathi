import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';
import '../../auth/providers/local_auth_provider.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/active_profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localAuthState = ref.watch(localAuthProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final activeProfileId = ref.watch(activeProfileProvider);
    final isSelf = activeProfileId == 'self';

    final userDocStream = uid != null
        ? (isSelf
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : FirebaseFirestore.instance.collection('users').doc(uid).collection('familyProfiles').doc(activeProfileId).snapshots())
        : Stream<DocumentSnapshot>.empty();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: userDocStream,
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final profileImage = (data?['profileImage'] ?? data?['photoUrl']) as String?;
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: profileImage == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Section
            _buildUserProfileSection(userDocStream, isSelf),
            const SizedBox(height: 24),

            // PREFERENCES Section
            _buildSettingsSection(
              title: 'PREFERENCES',
              children: [
                _buildListTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Language',
                  subtitle: 'English / Bangla',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language settings')),
                    );
                  },
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F47A1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('English', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: const Text('Bangla', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Notification Settings',
                  subtitle: 'Manage alerts and reminders',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SECURITY Section
            _buildSettingsSection(
              title: 'SECURITY',
              children: [
                _buildListTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Biometric Lock',
                  subtitle: 'Secure access with fingerprint or\nface',
                  onTap: () {},
                  trailing: Switch(
                    value: localAuthState.isBiometricAvailable,
                    onChanged: (bool value) {
                      if (value) {
                        ref.read(localAuthProvider.notifier).checkBiometrics();
                      } else {
                        ref.read(localAuthProvider.notifier).lockApp();
                      }
                    },
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF0F47A1),
                  ),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.lock_rounded,
                  iconColor: const Color(0xFF4B5563),
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.shield_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Privacy Controls',
                  subtitle: 'Manage data sharing and visibility',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy controls')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SUPPORT & ACCOUNT Section
            _buildSettingsSection(
              title: 'SUPPORT & ACCOUNT',
              children: [
                _buildListTile(
                  icon: Icons.help_rounded,
                  iconColor: const Color(0xFF6B7280),
                  title: 'Help & Support',
                  subtitle: 'FAQs, chat support, and user guides',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & support')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Logout',
                  subtitle: 'Sign out of your session',
                  titleColor: const Color(0xFFDC2626),
                  onTap: () async {
                    try {
                      await ref.read(authNotifierProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout failed: $e')),
                        );
                      }
                    }
                  },
                  showTrailing: false,
                ),
              ],
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'eHealthSathi version 2.4.1 [Build 882]\n© 2024 eHealthSathi Bangladesh Ltd.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(Stream<DocumentSnapshot> userDocStream, bool isSelf) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StreamBuilder<DocumentSnapshot>(
        stream: userDocStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final name = data?['name'] ?? data?['fullName'] ?? 'User Name';
          final patientId = data?['patientId'] ?? 'Not Set';
          final membershipStatus = data?['membershipStatus'] ?? (isSelf ? 'Standard Member' : 'Family Member');
          final profileImage = (data?['profileImage'] ?? data?['photoUrl']) as String?;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
                  backgroundColor: const Color(0xFFD6E4FF),
                  child: profileImage == null ? const Icon(Icons.person, size: 32, color: Color(0xFF0F47A1)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient ID: $patientId',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        membershipStatus,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showTrailing = true,
    Color? titleColor,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: trailing ?? (showTrailing ? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey) : null),
      onTap: onTap,
    );
  }
}
