import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/clinical_widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/providers/active_profile_provider.dart';

class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final activeProfileId = ref.watch(activeProfileProvider);

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final docRef = activeProfileId == 'self'
        ? FirebaseFirestore.instance.collection('users').doc(uid)
        : FirebaseFirestore.instance.collection('users').doc(uid).collection('familyProfiles').doc(activeProfileId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error loading medical data: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text('No medical data found. Please complete your profile.'),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final isSelf = activeProfileId == 'self';

        final patientName = data?['name'] ?? 'Patient Name Not Set';
        final bloodType = data?['bloodGroup'] ?? 'Not Set';
        
        final chronicData = data?['chronicDiseases'];
        final chronicConditions = chronicData is List ? chronicData.join(', ') : (chronicData?.toString() ?? 'No chronic conditions reported');
        
        final allergiesData = data?['allergies'];
        final drugReactions = allergiesData is List ? allergiesData.join(', ') : (allergiesData?.toString() ?? 'No known allergies');
        
        final emergencyContactName = isSelf ? (data?['emergencyContactName'] ?? 'No emergency contact') : (data?['emergencyContact'] ?? 'No emergency contact');
        final emergencyContactPhone = isSelf ? (data?['emergencyContactPhone'] ?? 'No phone number') : (data?['emergencyContact'] ?? 'No phone number');

        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Emergency Medical ID', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sos_rounded, size: 64, color: Color(0xFFDC2626)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Critical Shield Active',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: AppColors.onBackground,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your critical medical information is secured and accessible to emergency responders.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Medical Information Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x03000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Critical Medical Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMedicalInfoTile(
                        label: 'Patient Name',
                        value: patientName,
                        icon: Icons.person_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildMedicalInfoTile(
                        label: 'Blood Type',
                        value: bloodType,
                        icon: Icons.water_drop_rounded,
                        isHighlighted: true,
                      ),
                      const SizedBox(height: 16),
                      _buildMedicalInfoTile(
                        label: 'Chronic Conditions',
                        value: chronicConditions,
                        icon: Icons.medical_information_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildMedicalInfoTile(
                        label: 'Drug Reactions',
                        value: drugReactions,
                        icon: Icons.warning_rounded,
                        isAlert: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Emergency Responder Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.12)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x03000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Emergency Responder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildMedicalInfoTile(
                        label: 'Responder Name',
                        value: emergencyContactName,
                        icon: Icons.person_remove_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildMedicalInfoTile(
                        label: 'Phone Contact',
                        value: emergencyContactPhone,
                        icon: Icons.phone_rounded,
                        color: const Color(0xFFDC2626),
                      ),
                      const SizedBox(height: 24),
                      ClinicalButton(
                        label: 'Call Emergency Responder',
                        backgroundColor: const Color(0xFFDC2626),
                        icon: Icons.phone_forwarded_rounded,
                        onPressed: () => _makeEmergencyCall(
                          context: context,
                          contactName: emergencyContactName,
                          contactPhone: emergencyContactPhone,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tips Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TIPS FOR BEST RESULTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.outline,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTipRow(
                        icon: Icons.info_rounded,
                        text: 'Keep your medical information updated in your profile.',
                      ),
                      const SizedBox(height: 10),
                      _buildTipRow(
                        icon: Icons.info_rounded,
                        text: 'Verify that your emergency contact has been notified.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }


  // ─── Emergency Call Helper ────────────────────────────────────────────────
  /// Validates [contactPhone], shows a confirmation dialog, then launches the
  /// native phone dialer via url_launcher. Handles Android, iOS and Web
  /// gracefully.
  static Future<void> _makeEmergencyCall({
    required BuildContext context,
    required String contactName,
    required String contactPhone,
  }) async {
    // ── 1. Guard: no number stored ──────────────────────────────────────────
    final trimmed = contactPhone.trim();
    final isPlaceholder = trimmed.isEmpty ||
        trimmed == 'No phone number' ||
        trimmed == 'No emergency contact';

    if (isPlaceholder) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 8),
              Text('No Emergency Contact'),
            ],
          ),
          content: const Text(
            'No emergency contact found.\n'
            'Please add an emergency contact in Profile Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // ── 2. Guard: basic phone-number sanity check ───────────────────────────
    // Must contain at least 7 digits (allows +, spaces, dashes, parens).
    final digitCount = trimmed.replaceAll(RegExp(r'\D'), '').length;
    if (digitCount < 7) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The stored phone number appears to be invalid.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
      return;
    }

    // ── 3. Confirmation dialog ──────────────────────────────────────────────
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.phone_forwarded_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Emergency Call'),
          ],
        ),
        content: Text(
          'Are you sure you want to call\n$contactName?',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ── 4. Launch tel: URI ──────────────────────────────────────────────────
    // Build a clean URI: strip everything except digits and leading '+'.
    final digitsOnly = trimmed.startsWith('+')
        ? '+${trimmed.substring(1).replaceAll(RegExp(r'\D'), '')}'
        : trimmed.replaceAll(RegExp(r'\D'), '');

    final uri = Uri(scheme: 'tel', path: digitsOnly);

    if (!context.mounted) return;

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri);
      } else {
        // Web or restricted environments
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to launch phone dialer.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to launch phone dialer.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Widget _buildMedicalInfoTile({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlighted = false,
    bool isAlert = false,
    Color color = AppColors.primary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isAlert ? const Color(0xFFDC2626).withOpacity(0.1) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: isAlert ? const Color(0xFFDC2626) : color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.outline,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isAlert ? const Color(0xFFDC2626) : (isHighlighted ? AppColors.primary : Colors.black87),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
