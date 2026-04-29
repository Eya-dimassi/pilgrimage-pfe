import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -70,
              child: _GlowOrb(
                size: 280,
                color: AppColors.goldSoft,
              ),
            ),
            Positioned(
              top: 220,
              left: -90,
              child: _GlowOrb(
                size: 240,
                color: const Color(0xFFE8F4EE),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -60,
              child: _GlowOrb(
                size: 260,
                color: const Color(0xFFF7F1E2),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.caption,
    this.markSize = 42,
    this.titleSize = 20,
  });

  final String? caption;
  final double markSize;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(markSize * 0.34),
            boxShadow: AppShadows.soft,
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.mosque_rounded,
                size: markSize * 0.42,
                color: AppColors.goldBright,
              ),
              Positioned(
                top: markSize * 0.18,
                right: markSize * 0.2,
                child: Container(
                  width: markSize * 0.12,
                  height: markSize * 0.12,
                  decoration: const BoxDecoration(
                    color: AppColors.goldBright,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sacred Journey Hub',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.syne(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              if (caption != null)
                Text(
                  caption!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class BrandPill extends StatelessWidget {
  const BrandPill({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.goldSoft,
    this.foregroundColor = AppColors.gold,
    this.dotColor = AppColors.gold,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.72),
              color.withValues(alpha: 0.12),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
