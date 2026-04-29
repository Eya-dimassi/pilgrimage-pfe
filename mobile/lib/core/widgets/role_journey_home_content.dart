import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
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
  });

  final String firstName;
  final String? groupeNom;
  final AsyncValue<List<MobilePlanningGroup>> groupsAsync;
  final Color accentColor;
  final String roleToneLabel;
  final List<HomeQuickAction> quickActions;
  final String heroAssetPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = groupsAsync.valueOrNull?.isNotEmpty == true
        ? _pickBestGroup(groupsAsync.valueOrNull!)
        : null;
    final planningAsync = selectedGroup == null
        ? const AsyncValue<MobilePlanningData?>.data(null)
        : ref.watch(mobilePlanningDetailProvider(selectedGroup.id)).whenData(
              (value) => value,
            );

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
              _HomeHeader(
                firstName: firstName,
                groupeNom: groupeNom,
              ),
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
              const SizedBox(height: AppSpacing.m),
              const SectionTitle(
                'Vue d ensemble',
                subtitle:
                    'Les etapes, lieux et reperes partages pour votre groupe aujourd hui.',
                bottomPadding: AppSpacing.sm,
                titleStyle: TextStyle(
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
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.firstName,
    required this.groupeNom,
  });

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
              const Text(
                'Bonjour',
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
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: Color(0xFF0F3D2E),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }
}

MobilePlanningGroup _pickBestGroup(List<MobilePlanningGroup> groups) {
  int priority(MobilePlanningGroup group) {
    switch (group.status) {
      case 'EN_COURS':
        return 0;
      case 'PLANIFIE':
        return 1;
      case 'TERMINE':
        return 2;
      case 'ANNULE':
        return 3;
      default:
        return 4;
    }
  }

  final sortedGroups = [...groups]
    ..sort((left, right) {
      final priorityDiff = priority(left) - priority(right);
      if (priorityDiff != 0) return priorityDiff;

      final rightStart = right.dateDepart?.millisecondsSinceEpoch ?? 0;
      final leftStart = left.dateDepart?.millisecondsSinceEpoch ?? 0;
      if (rightStart != leftStart) return rightStart.compareTo(leftStart);

      final rightEnd = right.dateRetour?.millisecondsSinceEpoch ?? 0;
      final leftEnd = left.dateRetour?.millisecondsSinceEpoch ?? 0;
      if (rightEnd != leftEnd) return rightEnd.compareTo(leftEnd);

      return right.annee.compareTo(left.annee);
    });

  return sortedGroups.first;
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.asMap().entries.map((entry) {
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
      }).toList(growable: false),
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
        colors: [
          Colors.white,
          action.toneColor.withValues(alpha: 0.06),
        ],
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
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: action.toneColor,
          ),
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
    final today = planning?.plannings.isNotEmpty == true
        ? planning!.plannings.first
        : null;
    final currentEvent = _currentOrNextEvent(today?.evenements ?? const []);
    final nextEvent = _nextEventAfter(today?.evenements ?? const [], currentEvent);
    final groupLabel = group?.nom ?? fallbackGroupName ?? 'Votre groupe';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F3D2E),
            Color(0xFF156243),
            Color(0xFF1E7A58),
          ],
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
            right: 8,
            top: 28,
            child: Opacity(
              opacity: 0.84,
              child: AppHeroAsset(
                assetPath: heroAssetPath,
                width: 122,
                height: 132,
                scale: 1.14,
                alignment: Alignment.bottomCenter,
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
                              : 'OMRA ${group?.annee ?? ''}'.trim(),
                          icon: Icons.auto_awesome_rounded,
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          foregroundColor: const Color(0xFF72E0A5),
                          compact: true,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          currentEvent?.titre ?? 'Aucune etape partagee pour le moment',
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
                          _heroMeta(currentEvent, groupLabel) ?? 'Programme du jour',
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
    final currentTitle = currentEvent?.titre ?? 'Programme du moment';
    final currentMeta = _heroPanelMeta(currentEvent) ?? fallbackLocation;
    final upcomingTitle = nextEvent?.titre ?? 'Aucune suite partagee';
    final upcomingMeta = _heroPanelMeta(nextEvent) ?? 'En attente de la prochaine etape';

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
            label: 'En cours',
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
              label: 'Ensuite',
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
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
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
          Icon(
            trailingIcon,
            size: 22,
            color: Colors.white,
          ),
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
        title: 'Planning indisponible',
        meta: error.toString(),
        icon: Icons.info_outline_rounded,
        toneColor: AppColors.red,
      ),
      data: (planning) {
        final today = planning?.plannings.isNotEmpty == true
            ? planning!.plannings.first
            : null;
        final events = today?.evenements ?? const <MobilePlanningEvent>[];
          final currentEvent = _currentOrNextEvent(events);
          final nextEvent = _nextEventAfter(events, currentEvent);

          return Column(
            children: [
              _FlowCard(
                eventType: currentEvent?.type,
                title: currentEvent?.titre ?? 'Aucune etape partagee pour aujourd hui',
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

MobilePlanningEvent? _currentOrNextEvent(List<MobilePlanningEvent> events) {
  if (events.isEmpty) return null;

  final now = DateTime.now();
  for (var index = 0; index < events.length; index += 1) {
    final event = events[index];
    final start = event.heureDebutPrevue;
    final nextStart =
        index + 1 < events.length ? events[index + 1].heureDebutPrevue : null;

    if (start == null) return event;

    final isCurrent =
        !start.isAfter(now) && (nextStart == null || nextStart.isAfter(now));
    if (isCurrent || start.isAfter(now)) {
      return event;
    }
  }

  return events.last;
}

MobilePlanningEvent? _nextEventAfter(
  List<MobilePlanningEvent> events,
  MobilePlanningEvent? current,
) {
  if (current == null) return null;
  final currentIndex = events.indexWhere((event) => event.id == current.id);
  if (currentIndex < 0 || currentIndex >= events.length - 1) {
    return null;
  }
  return events[currentIndex + 1];
}

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
      return 'Transport';
    case 'VISITE':
      return 'Visite';
    case 'RITE':
      return 'Rite';
    case 'PRIERE':
      return 'Priere';
    default:
      return 'Etape';
  }
}

String _formatHour(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
