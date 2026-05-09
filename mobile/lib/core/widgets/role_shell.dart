import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    this.chatbotChild,
    this.accountActions = const [],
    this.planningChild,
    this.alertsChild,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  final Widget homeChild;
  final Widget profileChild;
  final Widget? chatbotChild;
  final List<RoleShellAccountAction> accountActions;
  final Widget? planningChild;
  final Widget? alertsChild;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  @override
  ConsumerState<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends ConsumerState<RoleShell> {
  static const String _appName = 'Sacred Journey Hub';
  late int _currentIndex;
  int _lastMainIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _lastMainIndex = _currentIndex == 4 ? 0 : _currentIndex;
  }

  @override
  void didUpdateWidget(covariant RoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialIndex.clamp(0, 4);
    if (oldWidget.initialIndex != widget.initialIndex &&
        _currentIndex != nextIndex) {
      _currentIndex = nextIndex;
      if (nextIndex != 4) {
        _lastMainIndex = nextIndex;
      }
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
        label: 'Chatbot',
        icon: Icons.auto_awesome_outlined,
        activeIcon: Icons.auto_awesome_rounded,
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
      widget.chatbotChild ??
          const _FeaturePlaceholder(
            icon: Icons.auto_awesome_rounded,
            title: 'Chatbot',
            description:
                'Votre assistant de voyage apparaitra ici pour repondre rapidement aux questions utiles.',
          ),
      widget.profileChild,
    ];

    final isProfilePage = _currentIndex == 4;

    return Scaffold(
      body: BrandBackdrop(
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 56),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentIndex),
                    child: pages[_currentIndex],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: _RoleTopBar(
                  title: _appName,
                  trailing: Builder(
                    builder: (buttonContext) => _TopActionButton(
                      icon: isProfilePage
                          ? Icons.arrow_back_rounded
                          : Icons.person_outline_rounded,
                      label: isProfilePage ? 'Retour' : 'Compte',
                      onTap: isProfilePage
                          ? (_) => _closeProfile()
                          : (tapContext) => _openAccountMenu(tapContext),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _MagicBottomNavigation(
        items: destinations,
        currentIndex: _currentIndex == 4 ? _lastMainIndex : _currentIndex,
        onSelected: (index) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
            _lastMainIndex = index;
          });
          widget.onIndexChanged?.call(index);
        },
      ),
    );
  }

  void _closeProfile() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentIndex = _lastMainIndex;
    });
    widget.onIndexChanged?.call(_lastMainIndex);
  }

  Future<void> _openAccountMenu(BuildContext buttonContext) async {
    HapticFeedback.lightImpact();
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button = buttonContext.findRenderObject();
    if (button is! RenderBox) {
      return;
    }

    final buttonTopLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonBottomRight = button.localToGlobal(
      button.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final selected = await showMenu<String>(
      context: context,
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      position: RelativeRect.fromLTRB(
        buttonTopLeft.dx - 160,
        buttonBottomRight.dy + 8,
        overlay.size.width - buttonBottomRight.dx,
        overlay.size.height - buttonTopLeft.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'profile',
          child: _AccountMenuItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            toneColor: AppColors.primaryDark,
          ),
        ),
        ...widget.accountActions.asMap().entries.map(
          (entry) => PopupMenuItem<String>(
            value: 'action_${entry.key}',
            child: _AccountMenuItem(
              icon: entry.value.icon,
              label: entry.value.label,
              toneColor: entry.value.toneColor,
            ),
          ),
        ),
      ],
    );

    if (!mounted || selected == null) {
      return;
    }

    if (selected == 'profile') {
      setState(() {
        _lastMainIndex = _currentIndex;
        _currentIndex = 4;
      });
      widget.onIndexChanged?.call(4);
      return;
    }

    if (selected.startsWith('action_')) {
      final index = int.tryParse(selected.replaceFirst('action_', ''));
      if (index == null || index < 0 || index >= widget.accountActions.length) {
        return;
      }
      await widget.accountActions[index].onTap(context);
    }
  }
}

class RoleShellAccountAction {
  const RoleShellAccountAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.toneColor = AppColors.textPrimary,
  });

  final String label;
  final IconData icon;
  final Color toneColor;
  final Future<void> Function(BuildContext context) onTap;
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.section.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Icon(icon, size: 20, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _RoleTopBar extends StatelessWidget {
  const _RoleTopBar({
    required this.title,
    required this.trailing,
  });

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              const _BrandLogoBadge(),
              const Spacer(),
              trailing,
            ],
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogoBadge extends StatelessWidget {
  const _BrandLogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.section.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.all(5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.label,
    required this.toneColor,
  });

  final IconData icon;
  final String label;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconBadge(
          icon: icon,
          size: 36,
          backgroundColor: toneColor.withValues(alpha: 0.12),
          foregroundColor: toneColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
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
                                              child:
                                                  _UnreadBadge(
                                                    count:
                                                        destination.badgeCount,
                                                  ).animate().scale(
                                                    duration: 200.ms,
                                                    curve: Curves.elasticOut,
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
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
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
  const _ActiveNavBubble({required this.icon, this.badgeCount = 0});

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
                border: Border.all(color: const Color(0xFFBEE0C3), width: 1.8),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 22)
                  .animate()
                  .rotate(
                    begin: -0.05,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
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
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
