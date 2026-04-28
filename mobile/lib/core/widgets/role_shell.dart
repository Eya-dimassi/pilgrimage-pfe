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
    const destinations = [
      _ShellDestination(
        label: 'Accueil',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _ShellDestination(
        label: 'Planning',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      _ShellDestination(
        label: 'Alertes',
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
      ),
      _ShellDestination(
        label: 'Profil',
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

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
      bottomNavigationBar: _MagicBottomNavigation(
        items: destinations,
        currentIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _MagicBottomNavigation extends StatelessWidget {
  const _MagicBottomNavigation({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<_ShellDestination> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / items.length;
          const bubbleSize = 56.0;
          final bubbleLeft =
              (slotWidth * currentIndex) + ((slotWidth - bubbleSize) / 2);

          return SizedBox(
            height: 78,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderSoft),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final destination = items[index];
                        final active = index == currentIndex;

                        return Expanded(
                          child: Tooltip(
                            message: destination.label,
                            child: Semantics(
                              button: true,
                              selected: active,
                              label: destination.label,
                              child: InkWell(
                                onTap: () => onSelected(index),
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    opacity: active ? 0.0 : 1.0,
                                    child: Icon(
                                      destination.icon,
                                      size: 22,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: bubbleLeft,
                  top: 0,
                  child: _ActiveNavBubble(
                    icon: items[currentIndex].activeIcon,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActiveNavBubble extends StatelessWidget {
  const _ActiveNavBubble({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color.fromARGB(255, 0, 0, 0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x32000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: 1.6,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.text,
          size: 24,
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
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
