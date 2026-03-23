import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          right: -80,
          child: _GlowOrb(
            size: 260,
            color: AppColors.goldSoft,
          ),
        ),
        Positioned(
          top: 190,
          left: -90,
          child: _GlowOrb(
            size: 220,
            color: AppColors.greenSoft,
          ),
        ),
        Positioned(
          bottom: -110,
          right: -70,
          child: _GlowOrb(
            size: 250,
            color: AppColors.blueSoft,
          ),
        ),
        child,
      ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            color: AppColors.text,
            borderRadius: BorderRadius.circular(markSize * 0.34),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.lock_outline_rounded,
            size: markSize * 0.42,
            color: AppColors.background,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SmartHajj',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: AppColors.text,
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
          ],
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
          color: color,
        ),
      ),
    );
  }
}
