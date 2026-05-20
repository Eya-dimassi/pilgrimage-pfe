import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../utils/saudi_time.dart';
import '../utils/trip_progress.dart';
import '../../features/planning/domain/mobile_planning_models.dart';
import '../../features/notifications/providers/mobile_notifications_provider.dart';
import '../../features/planning/providers/mobile_planning_provider.dart';
import 'adhan_panel.dart';
import 'app_surfaces.dart';

class HomeQuickAction {
  const HomeQuickAction({
    required this.label,
    required this.icon,
    required this.toneColor,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final IconData icon;
  final Color toneColor;
  final VoidCallback onTap;
}

class RoleJourneyHomeContent extends ConsumerWidget {
  const RoleJourneyHomeContent({
    super.key,
    required this.firstName,
    required this.groupeNom,
    required this.groupsAsync,
    required this.accentColor,
    this.roleToneLabel = '',
    this.quickActions = const [],
    this.heroAssetPath = 'assets/images/mosque_guide.png',
    this.showOverviewSection = true,
    this.extraSections = const [],
  });

  final String firstName;
  final String? groupeNom;
  final AsyncValue<List<MobilePlanningGroup>> groupsAsync;
  final Color accentColor;
  final String roleToneLabel;
  final List<HomeQuickAction> quickActions;
  final String heroAssetPath;
  final bool showOverviewSection;
  final List<Widget> extraSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = groupsAsync.valueOrNull?.isNotEmpty == true
        ? pickBestPlanningGroup(groupsAsync.valueOrNull!)
        : null;
    final planningAsync = selectedGroup == null
        ? const AsyncValue<MobilePlanningData?>.data(null)
        : ref
              .watch(mobilePlanningDetailProvider(selectedGroup.id))
              .whenData((value) => value);

    Future<void> refreshHome() async {
      ref.invalidate(mobilePlanningGroupsProvider);
      ref.invalidate(mobileNotificationsProvider);
      if (selectedGroup != null) {
        ref.invalidate(mobilePlanningDetailProvider(selectedGroup.id));
      }

      await ref.read(mobilePlanningGroupsProvider.future);
      if (selectedGroup != null) {
        await ref.read(mobilePlanningDetailProvider(selectedGroup.id).future);
      }
      await ref.read(mobileNotificationsProvider.future);
    }

    return Stack(
      children: [
        const _SoftScreenBackdrop(),
        RefreshIndicator(
          color: accentColor,
          onRefresh: refreshHome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            children: [
              _HomeHeader(firstName: firstName, groupeNom: groupeNom),
              const SizedBox(height: 12),
              _RoleHero(
                fallbackGroupName: groupeNom,
                group: selectedGroup,
                planningAsync: planningAsync,
                heroAssetPath: heroAssetPath,
              ),
              const SizedBox(height: AppSpacing.m),
              AdhanPanel(
                accentColor: accentColor,
                roleToneLabel: roleToneLabel,
                compact: true,
              ),
              if (quickActions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                _QuickActionsRow(actions: quickActions),
              ],
              if (extraSections.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                ...extraSections,
              ],
              if (showOverviewSection) ...[
                const SizedBox(height: AppSpacing.m),
                SectionTitle(
                  'journey_home.overview.title'.tr(),
                  subtitle: 'journey_home.overview.subtitle'.tr(),
                  bottomPadding: AppSpacing.sm,
                  titleStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                _DailyFlowPanel(
                  planningAsync: planningAsync,
                  accentColor: accentColor,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.firstName, required this.groupeNom});

  final String firstName;
  final String? groupeNom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'journey_home.header.greeting'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  height: 0.98,
                  letterSpacing: -0.8,
                  color: AppColors.primaryDark,
                ),
              ),
              if (groupeNom != null) ...[
                const SizedBox(height: 4),
                Text(
                  groupeNom!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A8F98),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == actions.length - 1 ? 0 : 10,
                ),
                child: _QuickActionCard(action: action),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      radius: AppRadii.lg,
      onTap: action.onTap,
      gradient: LinearGradient(
        colors: [Colors.white, action.toneColor.withValues(alpha: 0.06)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          AppIconBadge(
            icon: action.icon,
            size: 38,
            backgroundColor: action.toneColor.withValues(alpha: 0.12),
            foregroundColor: action.toneColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (action.description != null &&
                    action.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    action.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 18, color: action.toneColor),
        ],
      ),
    );
  }
}

class _RoleHero extends StatelessWidget {
  const _RoleHero({
    required this.fallbackGroupName,
    required this.group,
    required this.planningAsync,
    required this.heroAssetPath,
  });

  final String? fallbackGroupName;
  final MobilePlanningGroup? group;
  final AsyncValue<MobilePlanningData?> planningAsync;
  final String heroAssetPath;

  @override
  Widget build(BuildContext context) {
    final planning = planningAsync.valueOrNull;
    final visiblePlannings = sortPlanningDaysByDate(
      planning?.plannings ?? const [],
    );
    final today = findPlanningDayForDate(
      visiblePlannings,
      SaudiTime.now(),
      preferWithEvents: true,
    );
    final currentEvent = pickCurrentOrNextPlanningEvent(
      today?.evenements ?? const [],
    );
    final nextEvent = pickNextPlanningEventPreview(
      visiblePlannings,
      anchorDay: SaudiTime.now(),
      currentEvent: currentEvent,
    );
    final groupLabel =
        group?.nom ?? fallbackGroupName ?? 'journey_home.hero.your_group'.tr();
    final progress = computeTripProgress(
      group?.dateDepart,
      group?.dateRetour,
      DateTime.now(),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3D2E), Color(0xFF156243), Color(0xFF1E7A58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: -6,
            bottom: -8,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.96,
                child:
                    AppHeroAsset(
                          assetPath: heroAssetPath,
                          width: 150,
                          height: 176,
                          scale: 1.0,
                          alignment: Alignment.bottomCenter,
                          fit: BoxFit.contain,
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
                        .slideX(
                          begin: 0.08,
                          end: 0,
                          duration: 420.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .moveY(
                          begin: 0,
                          end: -5,
                          duration: 2200.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppStatusChip(
                          label: group?.typeVoyage == 'HAJJ'
                              ? 'HAJJ ${group?.annee ?? ''}'.trim()
                              : 'UMRAH ${group?.annee ?? ''}'.trim(),
                          icon: Icons.auto_awesome_rounded,
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          foregroundColor: const Color(0xFF72E0A5),
                          compact: true,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentEvent?.titre ??
                              'journey_home.hero.no_events'.tr(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _heroMeta(currentEvent, groupLabel) ??
                              'journey_home.hero.program'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.74),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 120),
                ],
              ),
              const SizedBox(height: 18),
              _HeroProgressBlock(progress: progress),
              const SizedBox(height: 14),
              _HeroEventPanel(
                currentEvent: currentEvent,
                nextEvent: nextEvent,
                fallbackLocation: groupLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroProgressBlock extends StatelessWidget {
  const _HeroProgressBlock({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 6,
          width: 186,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF45E090),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'journey_home.hero.trip_progress'.tr(
            namedArgs: {'percent': '${(progress * 100).round()}'},
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroEventPanel extends StatelessWidget {
  const _HeroEventPanel({
    required this.currentEvent,
    required this.nextEvent,
    required this.fallbackLocation,
  });

  final MobilePlanningEvent? currentEvent;
  final MobilePlanningEvent? nextEvent;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final currentTitle =
        currentEvent?.titre ?? 'journey_home.hero.current_event'.tr();
    final currentMeta = _heroPanelMeta(currentEvent) ?? fallbackLocation;
    final upcomingTitle =
        nextEvent?.titre ?? 'journey_home.hero.no_upcoming_events'.tr();
    final upcomingMeta =
        _heroPanelMeta(nextEvent) ??
        'journey_home.hero.waiting_for_next_event'.tr();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          _HeroEventRow(
            icon: _eventTypeIcon(currentEvent?.type),
            title: currentTitle,
            meta: currentMeta,
            label: 'journey_home.hero.in_progress'.tr(),
          ),
          if (nextEvent != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            _HeroEventRow(
              icon: _eventTypeIcon(nextEvent?.type),
              title: upcomingTitle,
              meta: upcomingMeta,
              label: 'journey_home.hero.upcoming'.tr(),
              trailingIcon: Icons.chevron_right_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroEventRow extends StatelessWidget {
  const _HeroEventRow({
    required this.icon,
    required this.title,
    required this.meta,
    required this.label,
    this.trailingIcon,
  });

  final IconData icon;
  final String title;
  final String meta;
  final String label;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 22, color: Colors.white),
        ],
      ],
    );
  }
}

class _SoftScreenBackdrop extends StatelessWidget {
  const _SoftScreenBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFF7F7F3)),
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 130,
          right: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _DailyFlowPanel extends StatelessWidget {
  const _DailyFlowPanel({
    required this.planningAsync,
    required this.accentColor,
  });

  final AsyncValue<MobilePlanningData?> planningAsync;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return planningAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => _FlowCard(
        eventType: null,
        title: 'journey_home.hero.planning_unavailable'.tr(),
        meta: error.toString(),
        icon: Icons.info_outline_rounded,
        toneColor: AppColors.red,
      ),
      data: (planning) {
        final expandedPlannings = _expandPlanningsForTrip(
          planning?.plannings ?? const [],
        );
        final today = findPlanningDayForDate(
          expandedPlannings,
          SaudiTime.now(),
          preferWithEvents: true,
        );
        final events = today?.evenements ?? const <MobilePlanningEvent>[];
        final currentEvent = pickCurrentOrNextPlanningEvent(events);
        final nextEvent = pickNextPlanningEventPreview(
          expandedPlannings,
          anchorDay: SaudiTime.now(),
          currentEvent: currentEvent,
        );

        return Column(
          children: [
            _FlowCard(
              eventType: currentEvent?.type,
              title: currentEvent?.titre ?? 'journey_home.hero.no_events'.tr(),
              meta: _eventMeta(currentEvent),
              icon: _eventTypeIcon(currentEvent?.type),
              toneColor: _eventTypeColor(currentEvent?.type),
            ),
            const SizedBox(height: 12),
            if (nextEvent != null)
              _FlowCard(
                eventType: nextEvent.type,
                title: nextEvent.titre,
                meta: _eventMeta(nextEvent),
                icon: _eventTypeIcon(nextEvent.type),
                toneColor: _eventTypeColor(nextEvent.type),
              ),
          ],
        );
      },
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.eventType,
    required this.title,
    required this.meta,
    required this.icon,
    required this.toneColor,
  });

  final String? eventType;
  final String title;
  final String? meta;
  final IconData icon;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconBadge(
            icon: icon,
            size: 40,
            backgroundColor: toneColor.withValues(alpha: 0.12),
            foregroundColor: toneColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                AppStatusChip(
                  label: _eventTypeLabel(eventType),
                  icon: icon,
                  backgroundColor: toneColor.withValues(alpha: 0.12),
                  foregroundColor: toneColor,
                  compact: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<MobilePlanningDay> _expandPlanningsForTrip(
  List<MobilePlanningDay> plannings,
) => sortPlanningDaysByDate(plannings);

String? _primaryLocation(List<MobilePlanningEvent> events) {
  for (final event in events) {
    for (final lieu in event.lieux) {
      if (lieu.trim().isNotEmpty) return lieu.trim();
    }
  }
  return null;
}

String? _eventMeta(MobilePlanningEvent? event) {
  if (event == null) return null;
  final location = _primaryLocation([event]);
  final parts = <String>[
    if (location != null) location,
    if (event.heureDebutPrevue != null) _formatHour(event.heureDebutPrevue!),
  ];
  if (parts.isEmpty) return null;
  return parts.join(' - ');
}

String? _heroMeta(MobilePlanningEvent? event, String fallbackLabel) {
  return _primaryLocation(event == null ? const [] : [event]) ?? fallbackLabel;
}

String? _heroPanelMeta(MobilePlanningEvent? event) {
  if (event == null) return null;
  final location = _primaryLocation([event]) ?? event.lieu?.trim();
  if (location != null && location.isNotEmpty) {
    return location;
  }
  if (event.heureDebutPrevue != null) {
    return _formatHour(event.heureDebutPrevue!);
  }
  return null;
}

IconData _eventTypeIcon(String? type) {
  switch (type) {
    case 'TRANSPORT':
      return Icons.directions_bus_rounded;
    case 'VISITE':
      return Icons.explore_outlined;
    case 'RITE':
      return Icons.mosque_outlined;
    case 'PRIERE':
      return Icons.wb_twilight_outlined;
    default:
      return Icons.route_outlined;
  }
}

Color _eventTypeColor(String? type) {
  switch (type) {
    case 'TRANSPORT':
      return AppColors.blue;
    case 'VISITE':
      return AppColors.green;
    case 'RITE':
      return AppColors.gold;
    case 'PRIERE':
      return const Color(0xFFD4AF37);
    default:
      return AppColors.primary;
  }
}

String _eventTypeLabel(String? type) {
  switch (type) {
    case 'TRANSPORT':
      return 'journey_home.hero.transport'.tr();
    case 'VISITE':
      return 'journey_home.hero.visit'.tr();
    case 'RITE':
      return 'journey_home.hero.rite'.tr();
    case 'PRIERE':
      return 'journey_home.hero.prayer'.tr();
    default:
      return 'journey_home.hero.step'.tr();
  }
}

String _formatHour(DateTime value) {
  return SaudiTime.formatHour(value);
}
