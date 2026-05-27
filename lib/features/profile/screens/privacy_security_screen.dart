import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/clinical_widgets.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = true;
  bool _dataSharingEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security', style: TextStyle(fontWeight: FontWeight.bold)),
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
            MedicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Security',
                    showDivider: true,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.fingerprint, color: AppColors.primary),
                    title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Use Face ID / Touch ID to login'),
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: (val) => setState(() => _biometricEnabled = val),
                      activeColor: AppColors.primary,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.password, color: AppColors.primary),
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password reset link sent to email.')),
                      );
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
                    title: 'Privacy',
                    showDivider: true,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.share, color: AppColors.primary),
                    title: const Text('Clinical Data Sharing', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Allow anonymized data for research'),
                    trailing: Switch(
                      value: _dataSharingEnabled,
                      onChanged: (val) => setState(() => _dataSharingEnabled = val),
                      activeColor: AppColors.primary,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
