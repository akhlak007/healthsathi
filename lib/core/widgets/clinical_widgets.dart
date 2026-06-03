import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';

class MedicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double borderRadius;
  final BorderSide? borderSide;
  final List<BoxShadow>? boxShadow;

  const MedicalCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderRadius = 20.0,
    this.borderSide,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.fromBorderSide(
          borderSide ?? const BorderSide(color: Color(0x0F000000), width: 1.0),
        ),
        boxShadow: boxShadow ??
            [
              const BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(20.0),
          child: child,
        ),
      ),
    );
  }
}

class ClinicalButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final bool isFullWidth;
  final BorderSide? borderSide;

  const ClinicalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 54.0,
    this.isFullWidth = true,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.onPrimary,
      elevation: 0,
      minimumSize: isFullWidth ? Size.fromHeight(height) : null,
      padding: isFullWidth
          ? const EdgeInsets.symmetric(vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderSide ?? BorderSide.none,
      ),
    );

    if (icon != null) {
      return ElevatedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }

    return ElevatedButton(
      style: style,
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.onBackground,
                letterSpacing: -0.5,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              TextButton(
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(color: AppColors.outlineVariant.withOpacity(0.4), height: 1),
        ],
      ],
    );
  }
}

class ClinicalBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ClinicalBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory ClinicalBadge.success({required String label, IconData? icon}) {
    return ClinicalBadge(
      label: label,
      backgroundColor: const Color(0xFFE6F4EA),
      textColor: const Color(0xFF137333),
      icon: icon,
    );
  }

  factory ClinicalBadge.warning({required String label, IconData? icon}) {
    return ClinicalBadge(
      label: label,
      backgroundColor: const Color(0xFFFEF7E0),
      textColor: const Color(0xFFB06000),
      icon: icon,
    );
  }

  factory ClinicalBadge.error({required String label, IconData? icon}) {
    return ClinicalBadge(
      label: label,
      backgroundColor: const Color(0xFFFCE8E6),
      textColor: const Color(0xFFC5221F),
      icon: icon,
    );
  }

  factory ClinicalBadge.info({required String label, IconData? icon}) {
    return ClinicalBadge(
      label: label,
      backgroundColor: const Color(0xFFE8F0FE),
      textColor: const Color(0xFF1A73E8),
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int activeIndex;
  const AppBottomNavBar({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return Container(
      color: Colors.transparent,
      height: 96 + bottomPadding,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // White Bar Background
          Container(
            height: 72 + bottomPadding,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  iconOutline: Icons.home_outlined,
                  iconFilled: Icons.home_rounded,
                  label: 'Home',
                  route: '/home',
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  iconOutline: Icons.history_edu_outlined,
                  iconFilled: Icons.history_edu_rounded,
                  label: 'Timeline',
                  route: '/timeline',
                ),
                const Expanded(child: SizedBox()), // Space for center FAB
                _buildNavItem(
                  context,
                  index: 3,
                  iconOutline: Icons.search_outlined,
                  iconFilled: Icons.search_rounded,
                  label: 'Search',
                  route: '/search',
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  iconOutline: Icons.person_outline_rounded,
                  iconFilled: Icons.person_rounded,
                  label: 'Profile',
                  route: '/profile-setup',
                ),
              ],
            ),
          ),
          
          // Floating Center Button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () => context.go('/upload'),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF003D9B), // Deep Blue
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF003D9B).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required int index,
        required IconData iconOutline,
        required IconData iconFilled,
        required String label,
        required String route,
      }) {
    final bool isActive = activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isActive) return;
          context.go(route);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF69F0AE) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? iconFilled : iconOutline,
                  color: isActive ? const Color(0xFF00695C) : const Color(0xFF334155),
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? const Color(0xFF00695C) : const Color(0xFF334155),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

