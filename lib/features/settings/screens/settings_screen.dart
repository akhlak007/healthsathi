import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/providers/firebase_auth_provider.dart';
import '../../profile/providers/active_profile_provider.dart';
import '../../../../core/providers/language_provider.dart';
import 'package:health_sathi/l10n/app_localizations.dart';
import '../../medicine_reminders/providers/medicine_reminder_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
              title: AppLocalizations.of(context)!.preferences,
              children: [
                Consumer(builder: (context, ref, child) {
                  final locale = ref.watch(languageProvider);
                  final isEnglish = locale.languageCode == 'en';
                  final l10n = AppLocalizations.of(context)!;
                  
                  return _buildListTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: l10n.language,
                    subtitle: l10n.englishBangla,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.language,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ListTile(
                                  leading: const Icon(Icons.language),
                                  title: const Text('English'),
                                  trailing: isEnglish ? const Icon(Icons.check, color: AppColors.primary) : null,
                                  onTap: () {
                                    ref.read(languageProvider.notifier).changeLanguage('en');
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.language),
                                  title: const Text('বাংলা'),
                                  trailing: !isEnglish ? const Icon(Icons.check, color: AppColors.primary) : null,
                                  onTap: () {
                                    ref.read(languageProvider.notifier).changeLanguage('bn');
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
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
                              color: isEnglish ? const Color(0xFF0F47A1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(l10n.english, style: TextStyle(color: isEnglish ? Colors.white : Colors.grey, fontSize: 12, fontWeight: isEnglish ? FontWeight.bold : FontWeight.normal)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: !isEnglish ? const Color(0xFF0F47A1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(l10n.bangla, style: TextStyle(color: !isEnglish ? Colors.white : Colors.grey, fontSize: 12, fontWeight: !isEnglish ? FontWeight.bold : FontWeight.normal)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFFEA580C),
                  title: 'Notification Settings',
                  subtitle: 'Manage alerts and reminders',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => Consumer(
                        builder: (context, ref, child) {
                          final settings = ref.watch(notificationSettingsProvider);
                          return SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Center(
                                    child: Text(
                                      'Notification Settings',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SwitchListTile(
                                    title: const Text('Notification Sound', style: TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: const Text('Play sound on reminders'),
                                    value: settings.soundEnabled,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      ref.read(notificationSettingsProvider.notifier).toggleSound(val);
                                    },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Vibration', style: TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: const Text('Vibrate device on reminders'),
                                    value: settings.vibrationEnabled,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      ref.read(notificationSettingsProvider.notifier).toggleVibration(val);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SECURITY Section
            _buildSettingsSection(
              title: AppLocalizations.of(context)!.security,
              children: [
                _buildListTile(
                  icon: Icons.shield_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: AppLocalizations.of(context)!.privacyControls,
                  subtitle: AppLocalizations.of(context)!.privacyControlsSubtitle,
                  onTap: () {
                    context.push('/privacy-security');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SUPPORT & ACCOUNT Section
            _buildSettingsSection(
              title: AppLocalizations.of(context)!.supportAndAccount,
              children: [
                _buildListTile(
                  icon: Icons.help_rounded,
                  iconColor: const Color(0xFF6B7280),
                  title: AppLocalizations.of(context)!.helpAndSupport,
                  subtitle: AppLocalizations.of(context)!.helpAndSupportSubtitle,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.helpAndSupport,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Icon(Icons.support_agent_rounded, size: 64, color: AppColors.primary),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.helpAndSupportSubtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => context.pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Close'),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.lock_rounded,
                  iconColor: const Color(0xFF4B5563),
                  title: AppLocalizations.of(context)!.changePassword,
                  subtitle: 'Update your account password',
                  onTap: () {
                    context.push('/change-password');
                  },
                ),
                const Divider(height: 1, indent: 56, endIndent: 16),
                _buildListTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFDC2626),
                  title: AppLocalizations.of(context)!.logout,
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
                      Row(
                        children: [
                          Text(
                            'Patient ID: $patientId',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (patientId != 'Not Set' && patientId != 'Generating...' && patientId.isNotEmpty) ...[
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
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
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
