import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Soft pastel background with floating blobs.
class NeoBentoBackground extends StatelessWidget {
  const NeoBentoBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.backgroundDark,
                  AppColors.surfaceDarkElevated,
                ]
              : const [
                  AppColors.backgroundLight,
                  AppColors.primarySoft,
                ],
        ),
      ),
      child: Stack(
        children: [
          // Blobs
          Positioned(
            top: -40,
            left: -30,
            child: _Blob(
              color: (isDark ? AppColors.accentPink : AppColors.accentPink)
                  .withValues(alpha: isDark ? 0.18 : 0.55),
              size: 160,
            ),
          ),
          Positioned(
            top: 120,
            right: -60,
            child: _Blob(
              color: (isDark ? AppColors.accentMint : AppColors.accentMint)
                  .withValues(alpha: isDark ? 0.16 : 0.5),
              size: 200,
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _Blob(
              color: (isDark ? AppColors.accentBlue : AppColors.accentBlue)
                  .withValues(alpha: isDark ? 0.14 : 0.45),
              size: 180,
            ),
          ),

          // Content
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size),
          ),
        ),
      ),
    );
  }
}

/// Rounded, slightly elevated card used for auth and bento surfaces.
class SquishyCard extends StatelessWidget {
  const SquishyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.outlineSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: padding,
      child: child,
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0);
  }
}

/// Button with a subtle press animation.
class SquishyButton extends StatelessWidget {
  const SquishyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final base = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? theme.colorScheme.primary : theme.colorScheme.surface,
        foregroundColor:
            isPrimary ? theme.colorScheme.onPrimary : onSurface,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        elevation: 0,
        side: isPrimary
            ? BorderSide.none
            : BorderSide(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppColors.outlineSoft,
                width: 1.2,
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isPrimary
                  ? theme.colorScheme.onPrimary
                  : onSurface,
            ),
          ),
        ],
      ),
    );

    return base
        .animate()
        .scale(
          duration: 320.ms,
          curve: Curves.elasticOut,
        );
  }
}
