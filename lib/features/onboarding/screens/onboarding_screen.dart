import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { print('DEBUG: OnboardingScreen build called');
    final pageIndex = ref.watch(onboardingPageProvider);
    final textTheme = Theme.of(context).textTheme;
    final locale = ref.watch(languageProvider);
    final isBangla = locale.languageCode == 'bn';

    final onboards = [
      _OnboardData(
        title: isBangla ? 'সব রেকর্ড এক জায়গায়' : 'All Your Records in One Place',
        description: isBangla 
            ? 'আপনার প্রেসক্রিপশন, ল্যাব রিপোর্ট এবং চিকিৎসা ইতিহাস ক্লিনিকাল-গ্রেড এনক্রিপশনের সাথে সুরক্ষিতভাবে সংরক্ষণ এবং পরিচালনা করুন।'
            : 'Securely store and manage your prescriptions, lab reports, and medical history with clinical-grade encryption.',
      ),
      _OnboardData(
        title: isBangla ? 'তাৎক্ষণিক জীবনরক্ষাকারী অ্যাক্সেস' : 'Instant Life-Saving Access',
        description: isBangla
            ? 'আপনার জরুরি প্রোফাইল প্রতিটি সেকেন্ড গণনার সময় প্রথম সাড়াদানকারীদের দ্রুত কাজ করতে সহায়তা করে।'
            : 'Your emergency profile helps first responders act quickly when every second counts.',
      ),
      _OnboardData(
        title: isBangla ? 'স্মার্ট এআই স্ক্যানার' : 'Smart AI Scanner',
        description: isBangla
            ? 'আমাদের উন্নত এআই ওসিআর ইঞ্জিন ব্যবহার করে তাৎক্ষণিকভাবে হাতে লেখা প্রেসক্রিপশন এবং মেডিকেল রিপোর্ট ডিজিটাইজ করুন।'
            : 'Instantly digitize handwritten prescriptions and medical reports using our advanced AI OCR engine.',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                            color: const Color(0xFF006C4B).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.health_and_safety,
                              size: 18, color: Color(0xFF006C4B)),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HealthSathi',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF006C4B),
                            fontSize: 16,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    if (pageIndex < 2)
                      GestureDetector(
                        onTap: () async {
                          await ref
                              .read(onboardingNotifierProvider.notifier)
                              .markCompleted();
                          if (context.mounted) context.go('/login');
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 30),
                  ],
                ),

                const Spacer(),

                // Language Selector
                _LanguageSelector(isBangla: isBangla),

                const Spacer(),

                // Custom Visual Illustrations
                Center(
                  child: _buildIllustration(pageIndex),
                ),

                const Spacer(),

                // Title and Description Frame
                Text(
                  onboards[pageIndex].title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  onboards[pageIndex].description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Page Dot Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (idx) {
                    final active = pageIndex == idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF006C4B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const Spacer(),

                // Action Button
                ElevatedButton(
                  onPressed: () async {
                    if (pageIndex < 2) {
                      ref.read(onboardingPageProvider.notifier).state =
                          pageIndex + 1;
                    } else {
                      await ref
                          .read(onboardingNotifierProvider.notifier)
                          .markCompleted();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C4B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pageIndex == 2 ? (isBangla ? 'শুরু করুন' : 'Get Started') : (isBangla ? 'পরবর্তী' : 'Next'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
    );

  }

  Widget _buildIllustration(int index) {
    switch (index) {
      case 0:
        return _RecordsIllustration();
      case 1:
        return _EmergencyIllustration();
      case 2:
        return _ScannerIllustration();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Premium Illustration Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RecordsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cloud backdrop
          Positioned(
            bottom: 20,
            child: Icon(
              Icons.cloud_queue_rounded,
              size: 140,
              color: const Color(0xFF38BDF8).withOpacity(0.15),
            ),
          ),
          // Folder
          Positioned(
            bottom: 10,
            left: 40,
            child: Transform.rotate(
              angle: -0.1,
              child: Icon(
                Icons.folder_copy_rounded,
                size: 90,
                color: const Color(0xFF38BDF8).withOpacity(0.4),
              ),
            ),
          ),
          // Shield
          Positioned(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006C4B).withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 80,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
          // Cross inside shield
          const Positioned(
            child: Icon(
              Icons.add_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft pulse circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444).withOpacity(0.08),
            ),
          ),
          // Rotating medical card mockup
          Transform.rotate(
            angle: -0.15,
            child: Container(
              width: 170,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 6),
                      Container(
                        width: 80,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Mock lines
                  Container(width: 120, height: 6, color: Colors.grey[200]),
                  const SizedBox(height: 6),
                  Container(width: 80, height: 6, color: Colors.grey[200]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background sheet of paper
          Positioned(
            bottom: 10,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 110,
                height: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 50, height: 6, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Container(width: 80, height: 4, color: Colors.grey[100]),
                    const SizedBox(height: 6),
                    Container(width: 70, height: 4, color: Colors.grey[100]),
                    const SizedBox(height: 6),
                    Container(width: 60, height: 4, color: Colors.grey[100]),
                  ],
                ),
              ),
            ),
          ),
          // Overlay scanning phone
          Positioned(
            top: 20,
            right: 30,
            child: Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 75,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(4, 6),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF38BDF8),
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Selector Widget
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageSelector extends ConsumerWidget {
  final bool isBangla;
  const _LanguageSelector({required this.isBangla});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangButton(
            label: 'English',
            isSelected: !isBangla,
            onTap: () => ref.read(languageProvider.notifier).changeLanguage('en'),
          ),
          _LangButton(
            label: 'বাংলা',
            isSelected: isBangla,
            onTap: () => ref.read(languageProvider.notifier).changeLanguage('bn'),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardData {
  final String title;
  final String description;

  _OnboardData({
    required this.title,
    required this.description,
  });
}
