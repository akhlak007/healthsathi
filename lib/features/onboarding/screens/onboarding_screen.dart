import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/clinical_widgets.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = ref.watch(onboardingPageProvider);
    final textTheme = Theme.of(context).textTheme;

    final onboards = [
      _OnboardData(
        title: 'Store Health Records Securely',
        description: 'Digitize and manage all of your diagnostics, medical prescriptions, and health summaries in a single clinical ledger with offline safety.',
        icon: Icons.shield_outlined,
        color: AppColors.primary,
        illustrationBadge: 'CLINICAL GRADE SHIELD',
      ),
      _OnboardData(
        title: 'Automated AI Prescription Parser',
        description: 'Simply capture your paper records using your mobile camera. Our instant AI OCR extracts dosages, advice, and clinician info in seconds.',
        icon: Icons.document_scanner_outlined,
        color: AppColors.secondary,
        illustrationBadge: 'SMART PARSER ACTIVE',
      ),
      _OnboardData(
        title: 'Instant Life-Saving Medical ID',
        description: 'Store non-allergic profiles, drug-interaction sensitivities, and primary family contact responders for immediate SOS scans.',
        icon: Icons.emergency_share_outlined,
        color: AppColors.error,
        illustrationBadge: 'EMERGENCY COMPASS',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Top Actions: Header skip indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.health_and_safety, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'HealthSathi',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.outline,
                    ),
                    child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              const Spacer(),

              // Premium Illustration Area mimicking Figma layout
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer decorative rings
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onboards[pageIndex].color.withOpacity(0.03),
                      ),
                    ),
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: onboards[pageIndex].color.withOpacity(0.06),
                      ),
                    ),
                    
                    // Central medical core icon
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: onboards[pageIndex].color.withOpacity(0.1),
                      child: Icon(
                        onboards[pageIndex].icon,
                        size: 54,
                        color: onboards[pageIndex].color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Soft styled technology state pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: onboards[pageIndex].color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  onboards[pageIndex].illustrationBadge.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: onboards[pageIndex].color,
                  ),
                ),
              ),

              const Spacer(),

              // Title and Description Frame
              Text(
                onboards[pageIndex].title,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  onboards[pageIndex].description,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Page Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (idx) {
                  final active = pageIndex == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.outlineVariant.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Primary Actions
              ClinicalButton(
                label: pageIndex == 2 ? 'Get Started' : 'Continue',
                backgroundColor: onboards[pageIndex].color,
                onPressed: () {
                  if (pageIndex < 2) {
                    ref.read(onboardingPageProvider.notifier).state = pageIndex + 1;
                  } else {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String illustrationBadge;

  _OnboardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.illustrationBadge,
  });
}
