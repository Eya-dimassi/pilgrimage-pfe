import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_frame.dart';

class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.homeChild,
    required this.profileChild,
    this.planningChild,
    this.initialIndex = 0,
  });

  final Widget homeChild;
  final Widget profileChild;
  final Widget? planningChild;
  final int initialIndex;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant RoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialIndex.clamp(0, 3);
    if (oldWidget.initialIndex != widget.initialIndex &&
        _currentIndex != nextIndex) {
      _currentIndex = nextIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      widget.homeChild,
      widget.planningChild ??
          const _FeaturePlaceholder(
            icon: Icons.calendar_month_outlined,
            title: 'Planning',
            description:
                'Le planning quotidien, les reperes du groupe et les prochaines etapes apparaitront ici.',
          ),
      const _FeaturePlaceholder(
        icon: Icons.notifications_none_rounded,
        title: 'Alertes',
        description:
            'Les notifications importantes, rappels et alertes de suivi seront centralisees dans cet espace.',
      ),
      widget.profileChild,
    ];

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.98),
          border: const Border(
            top: BorderSide(color: AppColors.borderSoft),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Accueil',
                active: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _BottomNavItem(
                icon: Icons.calendar_today_outlined,
                label: 'Planning',
                active: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _BottomNavItem(
                icon: Icons.notifications_none_rounded,
                label: 'Alertes',
                active: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _BottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                active: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.gold : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.goldSoft.withValues(alpha: 0.65) : Colors.transparent,
            border: active
                ? const Border(
                    top: BorderSide(
                      color: AppColors.gold,
                      width: 2,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  const _FeaturePlaceholder({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.gold),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
