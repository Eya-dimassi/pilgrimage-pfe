import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/planning/domain/mobile_planning_models.dart';
import '../../features/planning/providers/mobile_planning_provider.dart';
import 'adhan_panel.dart';

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
  });

  final String firstName;
  final String? groupeNom;
  final AsyncValue<List<MobilePlanningGroup>> groupsAsync;
  final Color accentColor;
  final String roleToneLabel;
  final List<HomeQuickAction> quickActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = groupsAsync.valueOrNull?.isNotEmpty == true
        ? groupsAsync.valueOrNull!.first
        : null;
    final planningAsync = selectedGroup == null
        ? const AsyncValue<MobilePlanningData?>.data(null)
        : ref.watch(mobilePlanningDetailProvider(selectedGroup.id)).whenData(
              (value) => value,
            );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      children: [
        _RoleHero(
          firstName: firstName,
          fallbackGroupName: groupeNom,
          group: selectedGroup,
          planningAsync: planningAsync,
        ),
        const SizedBox(height: 14),
        AdhanPanel(
          accentColor: accentColor,
          roleToneLabel: roleToneLabel,
          compact: true,
        ),
        if (quickActions.isNotEmpty) ...[
          const SizedBox(height: 14),
          _QuickActionsRow(actions: quickActions),
        ],
        const SizedBox(height: 14),
        _DailyFlowPanel(
          planningAsync: planningAsync,
          accentColor: accentColor,
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
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: action.toneColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.toneColor),
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
                        fontSize: 14,
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
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleHero extends StatelessWidget {
  const _RoleHero({
    required this.firstName,
    required this.fallbackGroupName,
    required this.group,
    required this.planningAsync,
  });

  final String firstName;
  final String? fallbackGroupName;
  final MobilePlanningGroup? group;
  final AsyncValue<MobilePlanningData?> planningAsync;

  @override
  Widget build(BuildContext context) {
    final planning = planningAsync.valueOrNull;
    final today = planning?.plannings.isNotEmpty == true
        ? planning!.plannings.first
        : null;
    final currentEvent = _currentOrNextEvent(today?.evenements ?? const []);
    final nextEvent = _nextEventAfter(today?.evenements ?? const [], currentEvent);
    final groupLabel = group?.nom ?? fallbackGroupName ?? 'Votre groupe';
    final tripPercent = _tripProgress(
      group?.dateDepart,
      group?.dateRetour,
      today?.date,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF103B2C),
            Color(0xFF175340),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            firstName,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            groupLabel,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.74),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          _StageCard(
            title: currentEvent?.titre ?? 'Aucun rendez-vous partage',
            meta: _eventMeta(currentEvent),
            progress: tripPercent,
            progressLabel: '${(tripPercent * 100).round()}% du voyage',
            nextTitle: nextEvent?.titre,
            nextMeta: _eventMeta(nextEvent),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.title,
    required this.meta,
    required this.progress,
    required this.progressLabel,
    required this.nextTitle,
    required this.nextMeta,
  });

  final String title;
  final String? meta;
  final double progress;
  final String progressLabel;
  final String? nextTitle;
  final String? nextMeta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: Colors.white,
            ),
          ),
          if (meta != null) ...[
            const SizedBox(height: 6),
            Text(
              meta!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF48D48F)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progressLabel,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (nextTitle != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.north_east_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextTitle!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (nextMeta != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            nextMeta!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
        title: 'Planning indisponible',
        meta: error.toString(),
        icon: Icons.info_outline_rounded,
        toneColor: const Color(0xFFE58E73),
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
              title: currentEvent?.titre ?? 'Rien de partage pour aujourd hui',
              meta: _eventMeta(currentEvent),
              icon: Icons.route_outlined,
              toneColor: accentColor,
            ),
            const SizedBox(height: 12),
            if (nextEvent != null)
              _FlowCard(
                title: nextEvent.titre,
                meta: _eventMeta(nextEvent),
                icon: Icons.north_east_rounded,
                toneColor: const Color(0xFF2D7A4A),
              ),
          ],
        );
      },
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.title,
    required this.meta,
    required this.icon,
    required this.toneColor,
  });

  final String title;
  final String? meta;
  final IconData icon;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: toneColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (meta != null && meta!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meta!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
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

double _tripProgress(DateTime? start, DateTime? end, DateTime? currentDay) {
  if (start == null || end == null || currentDay == null) return 0.0;
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedEnd = DateTime(end.year, end.month, end.day);
  final normalizedCurrent = DateTime(
    currentDay.year,
    currentDay.month,
    currentDay.day,
  );
  final totalDays = normalizedEnd.difference(normalizedStart).inDays + 1;
  if (totalDays <= 0) return 0.0;
  final currentIndex =
      normalizedCurrent.difference(normalizedStart).inDays + 1;
  return (currentIndex / totalDays).clamp(0.0, 1.0);
}

String _formatHour(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
