import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/providers/mobile_notifications_provider.dart';
import '../theme/app_theme.dart';
import 'app_surfaces.dart';
import 'brand_frame.dart';

class RoleShell extends ConsumerStatefulWidget {
  const RoleShell({
    super.key,
    required this.homeChild,
    required this.profileChild,
    this.planningChild,
    this.alertsChild,
    this.initialIndex = 0,
  });

  final Widget homeChild;
  final Widget profileChild;
  final Widget? planningChild;
  final Widget? alertsChild;
  final int initialIndex;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
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
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final destinations = [
      const _ShellDestination(
        label: 'Accueil',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      const _ShellDestination(
        label: 'Planning',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_month_rounded,
      ),
      _ShellDestination(
        label: 'Alertes',
        icon: Icons.notifications_none_rounded,
        activeIcon: Icons.notifications_rounded,
        badgeCount: unreadCount,
      ),
      const _ShellDestination(
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
      widget.alertsChild ??
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
      minimum: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / items.length;
          const bubbleSize = 54.0;
          final bubbleLeft =
              (slotWidth * currentIndex) + ((slotWidth - bubbleSize) / 2);

          return SizedBox(
            height: 82,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 62,
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderSoft),
                      boxShadow: AppShadows.lifted,
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
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      curve: Curves.easeOut,
                                      opacity: active ? 0.0 : 1.0,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Icon(
                                            destination.icon,
                                            size: 24,
                                            color: AppColors.textMuted,
                                          ),
                                          if (destination.badgeCount > 0)
                                            Positioned(
                                              right: -8,
                                              top: -6,
                                              child: _UnreadBadge(
                                                count: destination.badgeCount,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      destination.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: active
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: active
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
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
                    badgeCount: items[currentIndex].badgeCount,
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
    this.badgeCount = 0,
  });

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF9FD0A7),
              boxShadow: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 18,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFBEE0C3),
                  width: 1.8,
                ),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryDark,
                size: 22,
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -3,
              child: _UnreadBadge(count: badgeCount),
            ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.card, width: 1.4),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
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
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int badgeCount;
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
        child: AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconBadge(
                icon: icon,
                size: 58,
                backgroundColor: AppColors.goldSoft,
                foregroundColor: AppColors.gold,
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
