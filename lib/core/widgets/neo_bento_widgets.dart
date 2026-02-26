import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: Stack(
        children: [
          // Animated Blobs
          _PositionedBlob(
            top: -60,
            left: -40,
            color: AppColors.bentoLilac.withValues(alpha: isDark ? 0.3 : 0.6),
            size: 240,
            duration: 6.seconds,
          ),
          _PositionedBlob(
            top: 200,
            right: -80,
            color: AppColors.bentoMint.withValues(alpha: isDark ? 0.2 : 0.5),
            size: 280,
            duration: 8.seconds,
            beginOffset: const Offset(20, -20),
          ),
          _PositionedBlob(
            bottom: -100,
            left: 20,
            color: AppColors.bentoSalmon.withValues(alpha: isDark ? 0.25 : 0.55),
            size: 300,
            duration: 7.seconds,
            beginOffset: const Offset(-30, 30),
          ),

          // Content
          child,
        ],
      ),
    );
  }
}

class _PositionedBlob extends StatelessWidget {
  const _PositionedBlob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
    required this.duration,
    this.beginOffset = const Offset(-20, 20),
  });

  final double? top, left, right, bottom;
  final Color color;
  final double size;
  final Duration duration;
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .move(begin: beginOffset, end: Offset.zero, duration: duration, curve: Curves.easeInOut)
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: duration, curve: Curves.easeInOut)
          .blur(begin: const Offset(40, 40), end: const Offset(60, 60)),
    );
  }
}

/// A high-end glassmorphic card for bento layouts.
class NeoBentoCard extends StatelessWidget {
  const NeoBentoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.color,
    this.delay = Duration.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        decoration: BoxDecoration(
          color: (color ?? (isDark ? Colors.white : Colors.black)).withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 3.seconds, curve: Curves.easeInOut, delay: delay)
          .animate()
          .fadeIn(delay: delay, duration: 600.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
    );
  }
}

/// Simple squishy card for auth screens.
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
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.outlineSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: padding,
      child: child,
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

/// Squishy button with haptics.
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

    return ElevatedButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed?.call();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : theme.colorScheme.surface,
        foregroundColor: isPrimary ? Colors.white : theme.colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        side: isPrimary ? BorderSide.none : const BorderSide(color: AppColors.outlineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Text(label, style: theme.textTheme.labelLarge?.copyWith(color: isPrimary ? Colors.white : null)),
        ],
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
  }
}

/// Glassmorphic bottom sheet.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
