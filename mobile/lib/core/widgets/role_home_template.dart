import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
  });

  final String title;
  final String subtitle;
  final String roleLabel;
  final Color accentColor;
  final IconData icon;
  final List<InfoCardData> cards;
  final List<HomeStatData> stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.card,
                accentColor.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
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
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.text,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.background,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.06,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: stats
                    .map((stat) => _StatCard(stat: stat))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Fonctionnalites clefs',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Des cartes plus claires, une palette plus douce et un langage visuel plus coherent sur mobile.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        ...cards.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoCard(
              card: card,
              accentColor: accentColor,
            ),
          ),
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
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
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: accentColor,
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(card.icon, color: toneColor),
          ),
          const SizedBox(width: 16),
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
                  const SizedBox(height: 12),
                ],
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
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
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_outward_rounded,
            color: toneColor,
            size: 18,
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
  });

  final String title;
  final String description;
  final IconData icon;
  final String? tag;
  final Color? toneColor;
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
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
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
