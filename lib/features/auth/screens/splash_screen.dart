import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_auth_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Colour Palette
// ─────────────────────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF2563EB);
const _kSecondary = Color(0xFF06B6D4);
const _kAccent    = Color(0xFF3B82F6);
const _kBg        = Color(0xFFF8FBFF);

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen — keeps ALL existing business logic untouched
// ─────────────────────────────────────────────────────────────────────────────
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  // ── Existing logic controllers ─────────────────────────────────────────────
  late final AnimationController _controller;

  // ── DNA / background loop controller ──────────────────────────────────────
  late final AnimationController _dnaController;

  // ── Particle float controller ──────────────────────────────────────────────
  late final AnimationController _particleController;

  // ── Staged-entry animations ────────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _dnaFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _loadingFade;

  // ── Pulse controller for the loading ring ─────────────────────────────────
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // ── Existing entry controller (1500 ms) — preserved exactly ──────────────
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // ── Staged animations (all driven by _controller) ─────────────────────
    _bgFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.00, 0.25, curve: Curves.easeOut)));

    _dnaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.10, 0.40, curve: Curves.easeOut)));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.25, 0.60, curve: Curves.easeOut)));

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.25, 0.65, curve: Curves.elasticOut)));

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.45, 0.72, curve: Curves.easeOut)));

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.58, 0.82, curve: Curves.easeOut)));

    _loadingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller,
          curve: const Interval(0.72, 1.00, curve: Curves.easeOut)));

    // ── DNA infinite loop ──────────────────────────────────────────────────
    _dnaController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // ── Particle float loop ────────────────────────────────────────────────
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ── Pulse for loading ring ─────────────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _controller.forward();

    // ── PRESERVED: original business logic — timing, auth check, routing ──
    Future.delayed(const Duration(milliseconds: 2800), () { // DEBUG: SplashScreen timer fired
      if (mounted) { print('DEBUG: SplashScreen mounted check passed');
        // Reset onboarding flag to ensure onboarding screen is shown for debugging/first-time experience
        print('DEBUG: Reset onboarding flag');
        ref.read(onboardingNotifierProvider.notifier).state = false;
        final onboardingCompleted = ref.read(onboardingNotifierProvider);
        print('DEBUG: onboardingCompleted=$onboardingCompleted');
        if (!onboardingCompleted) {
          context.go('/onboarding');
          return;
        }
        final user = ref.read(firebaseAuthProvider).currentUser;
        print('DEBUG: user=$user');
        if (user != null) {
          print('DEBUG: Navigating to /home');
          // Ensure existing users have a Patient ID (fire-and-forget)
          ref.read(patientIdServiceProvider).ensurePatientId(user.uid);
          context.go('/home');
        } else {
          print('DEBUG: Navigating to /login');
          context.go('/login');
        }
      print('DEBUG: SplashScreen navigation block completed');
        }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dnaController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: AnimatedBuilder(
        animation: Listenable.merge(
            [_controller, _dnaController, _particleController, _pulseController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Background gradient ───────────────────────────────────
              Opacity(
                opacity: _bgFade.value,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEEF4FF), _kBg],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // ── 2. DNA network (CustomPainter) ───────────────────────────
              Opacity(
                opacity: _dnaFade.value,
                child: CustomPaint(
                  size: Size(size.width, size.height),
                  painter: _DnaNetworkPainter(
                    progress: _dnaController.value,
                    particleProgress: _particleController.value,
                  ),
                ),
              ),

              // ── 3. Floating healthcare icons ─────────────────────────────
              Opacity(
                opacity: (_dnaFade.value * 0.55).clamp(0.0, 1.0),
                child: _FloatingHealthIcons(
                  progress: _particleController.value,
                  screenSize: size,
                ),
              ),

              // ── 4. Centre content ────────────────────────────────────────
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Logo
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _LogoWidget(),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    Opacity(
                      opacity: _titleFade.value,
                      child: const Text(
                        'HealthSathi',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: _kPrimary,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    Opacity(
                      opacity: _subtitleFade.value,
                      child: const Text(
                        "Your Family's Digital Health Companion",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Loading section
                    Opacity(
                      opacity: _loadingFade.value,
                      child: Column(
                        children: [
                          Transform.scale(
                            scale: _pulse.value,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(_kAccent),
                                backgroundColor:
                                    _kAccent.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'PREPARING YOUR DASHBOARD',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo Widget — shield + cross mark
// ─────────────────────────────────────────────────────────────────────────────
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _kPrimary.withValues(alpha: 0.18),
            blurRadius: 36,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _kSecondary.withValues(alpha: 0.10),
            blurRadius: 60,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [_kPrimary, _kSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DNA Network Painter
// ─────────────────────────────────────────────────────────────────────────────
class _DnaNetworkPainter extends CustomPainter {
  final double progress;       // 0–1 looping (12 s)
  final double particleProgress; // 0–1 looping (8 s)

  const _DnaNetworkPainter({
    required this.progress,
    required this.particleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = math.Random(42); // deterministic seed → same layout every frame

    // ── Node positions (fixed layout, seeded) ───────────────────────────────
    final nodes = List.generate(22, (i) {
      return Offset(
        rng.nextDouble() * w,
        rng.nextDouble() * h,
      );
    });

    // ── Connection lines ────────────────────────────────────────────────────
    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < w * 0.35) {
          final alpha = (1.0 - dist / (w * 0.35)) * 0.12;
          final pulseFactor = 0.85 +
              0.15 *
                  math.sin(progress * math.pi * 2 + i * 0.7 + j * 0.4);
          linePaint.color = _kAccent.withValues(alpha: alpha * pulseFactor);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // ── DNA helix strands ───────────────────────────────────────────────────
    _drawDnaHelix(canvas, size, progress);

    // ── Floating particles ──────────────────────────────────────────────────
    _drawParticles(canvas, size, particleProgress, rng);

    // ── Nodes (circles) ─────────────────────────────────────────────────────
    for (int i = 0; i < nodes.length; i++) {
      final pulse = 0.7 + 0.3 * math.sin(progress * math.pi * 2 + i * 1.1);
      final radius = (2.5 + rng.nextDouble() * 2.5) * pulse;
      final alpha = 0.10 + 0.08 * math.sin(progress * math.pi * 2 + i);

      final nodePaint = Paint()
        ..color = (i.isEven ? _kPrimary : _kSecondary).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodes[i], radius, nodePaint);
    }
  }

  void _drawDnaHelix(Canvas canvas, Size size, double progress) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    final strand1 = Paint()
      ..color = _kPrimary.withValues(alpha: 0.07)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final strand2 = Paint()
      ..color = _kSecondary.withValues(alpha: 0.07)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rungs = Paint()
      ..color = _kAccent.withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    final path2 = Path();
    const amplitude = 55.0;
    const period = 180.0; // pixels per full wave
    final offset = progress * period; // scroll downward

    for (double y = -period; y < h + period; y += 2) {
      final angle = (y + offset) / period * math.pi * 2;
      final x1 = cx + amplitude * math.sin(angle);
      final x2 = cx - amplitude * math.sin(angle);

      if (y == -period) {
        path1.moveTo(x1, y);
        path2.moveTo(x2, y);
      } else {
        path1.lineTo(x1, y);
        path2.lineTo(x2, y);
      }

      // Draw rungs every ~30px
      if (y % 30 < 2) {
        final angle2 = (y + offset) / period * math.pi * 2;
        final rx1 = cx + amplitude * math.sin(angle2);
        final rx2 = cx - amplitude * math.sin(angle2);
        canvas.drawLine(Offset(rx1, y), Offset(rx2, y), rungs);
      }
    }

    canvas.drawPath(path1, strand1);
    canvas.drawPath(path2, strand2);
  }

  void _drawParticles(
      Canvas canvas, Size size, double progress, math.Random rng) {
    const count = 30;
    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;

      // Float upward: each particle has a different phase
      final phase = (progress + i / count) % 1.0;
      final x = baseX + 12 * math.sin(phase * math.pi * 2 + i);
      final y = baseY - phase * size.height * 0.18; // float up gently

      final radius = 1.5 + rng.nextDouble() * 2.0;
      final alpha = (0.06 + 0.06 * math.sin(phase * math.pi * 2)) *
          (1.0 - phase * 0.5); // fade out as they rise

      final paint = Paint()
        ..color = (i % 3 == 0 ? _kSecondary : _kAccent)
            .withValues(alpha: alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DnaNetworkPainter old) =>
      old.progress != progress || old.particleProgress != particleProgress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating Healthcare Icons
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingHealthIcons extends StatelessWidget {
  final double progress;
  final Size screenSize;

  const _FloatingHealthIcons({
    required this.progress,
    required this.screenSize,
  });

  static const _icons = [
    (Icons.favorite_rounded,          0.10,  0.15),
    (Icons.shield_rounded,            0.80,  0.22),
    (Icons.medication_rounded,        0.18,  0.70),
    (Icons.description_rounded,       0.82,  0.65),
    (Icons.add_circle_outline_rounded,0.50,  0.10),
    (Icons.local_hospital_rounded,    0.72,  0.82),
    (Icons.monitor_heart_rounded,     0.12,  0.48),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _icons.asMap().entries.map((entry) {
        final i = entry.key;
        final (icon, fx, fy) = entry.value;
        final phase = (progress + i * 0.14) % 1.0;
        final offsetY = -10 * math.sin(phase * math.pi * 2 + i);
        final alpha  =  0.06 + 0.04 * math.sin(phase * math.pi * 2);

        return Positioned(
          left: screenSize.width  * fx - 18,
          top:  screenSize.height * fy - 18 + offsetY,
          child: Icon(
            icon,
            size: 30,
            color: (i.isEven ? _kPrimary : _kSecondary)
                .withValues(alpha: alpha.clamp(0.0, 1.0)),
          ),
        );
      }).toList(),
    );
  }
}
