import 'package:flutter/material.dart';

/// HealthSathi Brand Logo Animated Loader
/// Displays the official app logo with an animated pulsing effect
/// and a circular spinner ring.
class AppLogoLoader extends StatefulWidget {
  final double size;
  final String? message;
  final Color? spinnerColor;
  final bool showBackgroundCard;

  const AppLogoLoader({
    super.key,
    this.size = 64.0,
    this.message,
    this.spinnerColor,
    this.showBackgroundCard = true,
  });

  @override
  State<AppLogoLoader> createState() => _AppLogoLoaderState();
}

class _AppLogoLoaderState extends State<AppLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSpinnerColor = widget.spinnerColor ?? const Color(0xFF003D9B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Spinning Ring
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveSpinnerColor),
                  backgroundColor: effectiveSpinnerColor.withOpacity(0.12),
                ),
              ),
              // Inner Logo Container with gentle pulse
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size * 0.70,
                  height: widget.size * 0.70,
                  decoration: widget.showBackgroundCard
                      ? BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: effectiveSpinnerColor.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        )
                      : null,
                  padding: EdgeInsets.all(widget.size * 0.08),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            widget.message!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
