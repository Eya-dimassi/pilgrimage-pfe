import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_surfaces.dart';
import 'brand_frame.dart';

class RoleHomeTemplate extends StatelessWidget {
  const RoleHomeTemplate({
    super.key,
    required this.title,
    required this.subtitle,
    required this.roleLabel,
    required this.accentColor,
    required this.icon,
    required this.cards,
    required this.stats,
    this.headerExtra,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String roleLabel;
  final Color accentColor;
  final IconData icon;
  final List<InfoCardData> cards;
  final List<HomeStatData> stats;
  final Widget? headerExtra;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          radius: AppRadii.xl,
          gradient: LinearGradient(
            colors: [
              AppColors.card,
              accentColor.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadow: AppShadows.lifted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _RolePill(
                      label: roleLabel,
                      accentColor: accentColor,
                    ),
                  ),
                  AppIconBadge(
                    icon: icon,
                    size: 56,
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: AppColors.goldBright,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  height: 1.06,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              if (headerExtra != null) ...[
                const SizedBox(height: AppSpacing.l),
                headerExtra!,
              ],
              if (stats.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.l),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: stats
                      .map((stat) => _StatCard(stat: stat))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        if (cards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          const SectionTitle(
            'Highlights',
            subtitle:
                'Useful shortcuts and clearer mobile cards built around your live trip data.',
          ),
          ...cards.map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InfoCard(
                card: card,
                accentColor: accentColor,
              ),
            ),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 4),
          footer!,
        ],
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AppStatusChip(
      label: label,
      icon: Icons.auto_awesome_rounded,
      backgroundColor: accentColor.withValues(alpha: 0.12),
      foregroundColor: accentColor,
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.card,
    required this.accentColor,
  });

  final InfoCardData card;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final toneColor = card.toneColor ?? accentColor;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.lg,
      onTap: card.onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconBadge(
            icon: card.icon,
            size: 54,
            backgroundColor: toneColor.withValues(alpha: 0.12),
            foregroundColor: toneColor,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (card.tag != null) ...[
                  BrandPill(
                    label: card.tag!,
                    backgroundColor: toneColor.withValues(alpha: 0.10),
                    foregroundColor: toneColor,
                    dotColor: toneColor,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  card.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          if (card.onTap != null)
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: toneColor,
              size: 16,
            ),
        ],
      ),
    );
  }
}

class InfoCardData {
  const InfoCardData({
    required this.title,
    required this.description,
    required this.icon,
    this.tag,
    this.toneColor,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? tag;
  final Color? toneColor;
  final VoidCallback? onTap;
}

class HomeStatData {
  const HomeStatData({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.stat,
  });

  final HomeStatData stat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.sm,
      ),
      radius: AppRadii.md,
      backgroundColor: AppColors.section,
      borderColor: AppColors.border,
      shadow: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
