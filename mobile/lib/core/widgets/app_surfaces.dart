import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadii.lg,
    this.backgroundColor = AppColors.card,
    this.borderColor = AppColors.borderSoft,
    this.gradient,
    this.onTap,
    this.shadow = AppShadows.soft,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.titleStyle,
    this.bottomPadding = AppSpacing.m,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      titleStyle ??
                      const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppColors.textPrimary,
                      ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.m),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.size = 52,
    this.backgroundColor = AppColors.section,
    this.foregroundColor = AppColors.primary,
  });

  final IconData icon;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, color: foregroundColor, size: size * 0.44),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = AppColors.successSoft,
    this.foregroundColor = AppColors.success,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 14, color: foregroundColor),
            SizedBox(width: compact ? 5 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AppListTileCard extends StatelessWidget {
  const AppListTileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconTone = AppColors.primary,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconTone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.m,
      ),
      onTap: onTap,
      child: Row(
        children: [
          AppIconBadge(
            icon: icon,
            size: 44,
            backgroundColor: iconTone.withValues(alpha: 0.10),
            foregroundColor: iconTone,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withValues(alpha: 0.8),
              ),
        ],
      ),
    );
  }
}

class AppMosqueIllustration extends StatelessWidget {
  const AppMosqueIllustration({
    super.key,
    this.width = 150,
    this.height = 120,
    this.soft = false,
  });

  final double width;
  final double height;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final domeColor = soft
        ? const Color(0xFF7CA77A).withValues(alpha: 0.72)
        : const Color(0xFF6E9E5E);
    final minaretColor = soft
        ? const Color(0xFFE9D8B4).withValues(alpha: 0.82)
        : const Color(0xFFE3C893);
    final baseColor = soft
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFFF7F1E7);

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 6,
            child: Container(
              width: width * 0.16,
              height: height * 0.88,
              decoration: BoxDecoration(
                color: minaretColor,
                borderRadius: BorderRadius.circular(width * 0.08),
              ),
            ),
          ),
          Positioned(
            right: width * 0.015,
            top: 0,
            child: Container(
              width: width * 0.13,
              height: height * 0.10,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A54C).withValues(
                  alpha: soft ? 0.72 : 1,
                ),
                borderRadius: BorderRadius.circular(width * 0.08),
              ),
            ),
          ),
          Positioned(
            right: width * 0.08,
            bottom: 0,
            child: Container(
              width: width * 0.56,
              height: height * 0.42,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(width * 0.12),
              ),
            ),
          ),
          Positioned(
            right: width * 0.13,
            bottom: height * 0.26,
            child: Container(
              width: width * 0.42,
              height: height * 0.34,
              decoration: BoxDecoration(
                color: domeColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(width * 0.25),
                ),
              ),
            ),
          ),
          Positioned(
            right: width * 0.285,
            bottom: height * 0.55,
            child: Container(
              width: width * 0.02,
              height: height * 0.08,
              color: const Color(0xFFC9A54C).withValues(
                alpha: soft ? 0.65 : 1,
              ),
            ),
          ),
          Positioned(
            right: width * 0.26,
            bottom: height * 0.62,
            child: Container(
              width: width * 0.08,
              height: height * 0.08,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A54C).withValues(
                  alpha: soft ? 0.65 : 1,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: width * 0.17,
            bottom: height * 0.06,
            child: Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : width * 0.03),
                  width: width * 0.05,
                  height: width * 0.05,
                  decoration: BoxDecoration(
                    color: domeColor.withValues(alpha: 0.86),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppHeroAsset extends StatelessWidget {
  const AppHeroAsset({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.scale = 1.0,
    this.alignment = Alignment.bottomRight,
  });

  final String assetPath;
  final double width;
  final double height;
  final double scale;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: alignment,
          maxWidth: scaledWidth,
          maxHeight: scaledHeight,
          child: Image.asset(
            assetPath,
            width: scaledWidth,
            height: scaledHeight,
            fit: BoxFit.cover,
            alignment: alignment,
          ),
        ),
      ),
    );
  }
}
