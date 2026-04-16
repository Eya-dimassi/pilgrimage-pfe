import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/mobile_planning_models.dart';
import '../providers/mobile_planning_provider.dart';

enum PlanningRoleView {
  guide,
  pelerin,
  famille,
}

class MobilePlanningScreen extends ConsumerStatefulWidget {
  const MobilePlanningScreen({
    super.key,
    required this.view,
    required this.accentColor,
    this.preferredGroupId,
  });

  final PlanningRoleView view;
  final Color accentColor;
  final String? preferredGroupId;

  @override
  ConsumerState<MobilePlanningScreen> createState() =>
      _MobilePlanningScreenState();
}

class _MobilePlanningScreenState extends ConsumerState<MobilePlanningScreen> {
  String? _selectedGroupId;
  String? _selectedPlanningId;

  @override
  void didUpdateWidget(covariant MobilePlanningScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferredGroupId != widget.preferredGroupId &&
        widget.preferredGroupId != null &&
        widget.preferredGroupId != _selectedGroupId) {
      _selectedGroupId = widget.preferredGroupId;
      _selectedPlanningId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(mobilePlanningGroupsProvider);
    final isDayOnly = widget.view != PlanningRoleView.guide;
    final showGroupTabs = widget.view == PlanningRoleView.guide;

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _PlanningErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(mobilePlanningGroupsProvider),
      ),
      data: (groups) {
        if (showGroupTabs) {
          _ensureSelectedGroup(groups);
        }

        if (groups.isEmpty) {
          return const _PlanningEmptyState(
            title: 'Aucun groupe disponible',
            message:
                'Votre planning apparaitra ici des qu un groupe actif vous sera rattache.',
          );
        }

        final selectedGroup = showGroupTabs
            ? groups.firstWhere(
                (group) => group.id == _selectedGroupId,
                orElse: () => groups.first,
              )
            : _resolveDayOnlyGroup(groups);

        final planningAsync = ref.watch(
          mobilePlanningDetailProvider(selectedGroup.id),
        );

        return planningAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PlanningErrorState(
            message: error.toString(),
            onRetry: () =>
                ref.refresh(mobilePlanningDetailProvider(selectedGroup.id)),
          ),
          data: (planningData) {
            if (!isDayOnly) {
              _ensureSelectedPlanning(planningData.plannings);
            }

            final selectedIndex = isDayOnly
                ? (planningData.plannings.isEmpty ? -1 : 0)
                : planningData.plannings.indexWhere(
                    (planning) => planning.id == _selectedPlanningId,
                  );
            final selectedDay = isDayOnly
                ? (planningData.plannings.isEmpty
                      ? null
                      : planningData.plannings.first)
                : (selectedIndex >= 0
                      ? planningData.plannings[selectedIndex]
                      : null);
            final selectedDayNumber = selectedDay == null
                ? 0
                : _tripDayNumber(planningData.groupe.dateDepart, selectedDay.date);

            return RefreshIndicator(
              color: widget.accentColor,
              onRefresh: () async {
                ref.invalidate(mobilePlanningGroupsProvider);
                ref.invalidate(mobilePlanningDetailProvider(selectedGroup.id));
                await ref.read(
                  mobilePlanningDetailProvider(selectedGroup.id).future,
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 116),
                children: [
                  if (showGroupTabs) ...[
                    _GroupTabs(
                      groups: groups,
                      selectedGroupId: selectedGroup.id,
                      onSelected: (groupId) {
                        setState(() {
                          _selectedGroupId = groupId;
                          _selectedPlanningId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildRoleHeader(
                    planningData: planningData,
                    selectedDay: selectedDay,
                    dayNumber: selectedDayNumber,
                    accentColor: widget.accentColor,
                  ),
                  const SizedBox(height: 18),
                  if (planningData.plannings.isEmpty)
                    _PlanningEmptyState(
                      title: widget.view == PlanningRoleView.famille
                          ? 'Aucun planning aujourd hui'
                          : 'Aucune journee planifiee',
                      message: widget.view == PlanningRoleView.famille
                          ? 'Le groupe n a pas encore de programme partage pour aujourd hui.'
                          : 'L agence n a pas encore prepare le planning de ce groupe.',
                    )
                  else ...[
                    if (!isDayOnly) ...[
                      _DayRailHeader(
                        hasPrevious: selectedIndex > 0,
                        hasNext:
                            selectedIndex >= 0 &&
                            selectedIndex < planningData.plannings.length - 1,
                        onPrevious: selectedIndex > 0
                            ? () {
                                setState(() {
                                  _selectedPlanningId =
                                      planningData.plannings[selectedIndex - 1].id;
                                });
                              }
                            : null,
                        onNext: selectedIndex >= 0 &&
                                selectedIndex < planningData.plannings.length - 1
                            ? () {
                                setState(() {
                                  _selectedPlanningId =
                                      planningData.plannings[selectedIndex + 1].id;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 102,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: planningData.plannings.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final day = planningData.plannings[index];
                            return _PlanningDayCard(
                              planning: day,
                              dayNumber: _tripDayNumber(
                                planningData.groupe.dateDepart,
                                day.date,
                              ),
                              selected: day.id == _selectedPlanningId,
                              accentColor: widget.accentColor,
                              onTap: () {
                                setState(() {
                                  _selectedPlanningId = day.id;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      _DayOnlyHeader(
                        title: widget.view == PlanningRoleView.famille
                            ? 'Aujourd hui'
                            : 'Planning du jour',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (selectedDay != null)
                      _SelectedDaySection(
                        planning: selectedDay,
                        dayNumber: selectedDayNumber,
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  MobilePlanningGroup _resolveDayOnlyGroup(List<MobilePlanningGroup> groups) {
    final preferredGroupId = widget.preferredGroupId;
    if (preferredGroupId != null) {
      for (final group in groups) {
        if (group.id == preferredGroupId) {
          return group;
        }
      }
    }

    return groups.first;
  }

  void _ensureSelectedGroup(List<MobilePlanningGroup> groups) {
    if (groups.isEmpty) return;

    final preferredExists = widget.preferredGroupId != null &&
        groups.any((group) => group.id == widget.preferredGroupId);
    if (preferredExists && _selectedGroupId != widget.preferredGroupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedGroupId = widget.preferredGroupId;
          _selectedPlanningId = null;
        });
      });
      return;
    }

    final stillExists = groups.any((group) => group.id == _selectedGroupId);
    if (_selectedGroupId == null || !stillExists) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedGroupId = groups.first.id;
          _selectedPlanningId = null;
        });
      });
    }
  }

  void _ensureSelectedPlanning(List<MobilePlanningDay> plannings) {
    if (plannings.isEmpty) return;

    final stillExists = plannings.any(
      (planning) => planning.id == _selectedPlanningId,
    );
    if (_selectedPlanningId != null && stillExists) return;

    final nextPlanning = _pickBestPlanning(plannings);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedPlanningId = nextPlanning.id;
      });
    });
  }

  MobilePlanningDay _pickBestPlanning(List<MobilePlanningDay> plannings) {
    return plannings.first;
  }

  Widget _buildRoleHeader({
    required MobilePlanningData planningData,
    required MobilePlanningDay? selectedDay,
    required int dayNumber,
    required Color accentColor,
  }) {
    switch (widget.view) {
      case PlanningRoleView.guide:
        return _TripSummaryCard(
          groupe: planningData.groupe,
          accentColor: accentColor,
          plannedDaysCount: planningData.plannings.length,
          currentTripDay: selectedDay == null
              ? null
              : _tripDayNumber(
                  planningData.groupe.dateDepart,
                  selectedDay.date,
                ),
        );
      case PlanningRoleView.pelerin:
        return _TripSummaryCard(
          groupe: planningData.groupe,
          accentColor: accentColor,
          plannedDaysCount: planningData.plannings.length,
          currentTripDay: selectedDay == null
              ? null
              : _tripDayNumber(
                  planningData.groupe.dateDepart,
                  selectedDay.date,
                ),
          compact: true,
        );
      case PlanningRoleView.famille:
        return _FamilyCurrentMomentCard(
          groupe: planningData.groupe,
          planning: selectedDay,
          dayNumber: dayNumber,
          accentColor: accentColor,
        );
    }
  }
}

class _GroupTabs extends StatelessWidget {
  const _GroupTabs({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelected,
  });

  final List<MobilePlanningGroup> groups;
  final String selectedGroupId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          final selected = group.id == selectedGroupId;

          return InkWell(
            onTap: () => onSelected(group.id),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: selected ? AppColors.gold : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.border,
                ),
              ),
              child: Text(
                group.nom.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({
    required this.groupe,
    required this.accentColor,
    required this.plannedDaysCount,
    this.currentTripDay,
    this.compact = false,
  });

  final MobilePlanningGroup groupe;
  final Color accentColor;
  final int plannedDaysCount;
  final int? currentTripDay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final totalTripDays = _tripLengthInDays(groupe.dateDepart, groupe.dateRetour);
    final boundedCurrentTripDay =
        currentTripDay?.clamp(0, totalTripDays == 0 ? 0 : totalTripDays);
    final displayedProgressUnits = compact
        ? (boundedCurrentTripDay ?? plannedDaysCount)
        : plannedDaysCount;
    final progress = totalTripDays == 0
        ? 0.0
        : (displayedProgressUnits / totalTripDays).clamp(0.0, 1.0);
    final percentageLabel = '${(progress * 100).round()}%';
    final progressDetail = compact
        ? (totalTripDays == 0
              ? 'Progression du voyage'
              : 'Jour ${boundedCurrentTripDay ?? 0} sur $totalTripDays')
        : (totalTripDays == 0
              ? '$plannedDaysCount jour(s) planifies'
              : '$plannedDaysCount jour(s) planifies');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.section,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${groupe.typeVoyage == 'HAJJ' ? 'HAJJ' : 'OMRA'} - ${groupe.annee}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            groupe.nom,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tripSubtitle(groupe),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (groupe.dateDepart != null && groupe.dateRetour != null) ...[
            const SizedBox(height: 10),
            Text(
              '${_formatMediumDate(groupe.dateDepart!)} -> ${_formatMediumDate(groupe.dateRetour!)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  progressDetail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                percentageLabel,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: AppColors.borderSoft,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCurrentMomentCard extends StatelessWidget {
  const _FamilyCurrentMomentCard({
    required this.groupe,
    required this.planning,
    required this.dayNumber,
    required this.accentColor,
  });

  final MobilePlanningGroup groupe;
  final MobilePlanningDay? planning;
  final int dayNumber;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final currentEvent = _currentOrNextEvent(planning?.evenements ?? const []);
    final nextEvent = _nextEventAfter(
      planning?.evenements ?? const [],
      currentEvent,
    );
    final currentLocation =
        currentEvent == null ? null : _primaryLocation([currentEvent]);
    final totalTripDays = _tripLengthInDays(groupe.dateDepart, groupe.dateRetour);
    final progress = totalTripDays == 0
        ? 0.0
        : (dayNumber / totalTripDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'En ce moment',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            groupe.nom,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            planning == null
                ? 'Aucun programme partage pour aujourd hui.'
                : 'Jour $dayNumber - ${planning?.titre?.trim().isNotEmpty == true ? planning!.titre! : 'Programme du jour'}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalTripDays == 0
                      ? 'Progression du voyage'
                      : 'Jour $dayNumber sur $totalTripDays',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              backgroundColor: AppColors.borderSoft,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),
          _FamilyInfoRow(
            label: 'Lieu',
            value: currentLocation ?? 'A confirmer',
          ),
          const SizedBox(height: 10),
          _FamilyInfoRow(
            label: 'Activite',
            value: currentEvent?.titre ?? 'Aucune activite en cours',
          ),
          const SizedBox(height: 10),
          _FamilyInfoRow(
            label: 'Ensuite',
            value: nextEvent?.titre ?? 'Rien d autre de prevu pour aujourd hui',
          ),
        ],
      ),
    );
  }
}

class _FamilyInfoRow extends StatelessWidget {
  const _FamilyInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textFaint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRailHeader extends StatelessWidget {
  const _DayRailHeader({
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Journees',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          enabled: hasPrevious,
          onTap: onPrevious,
        ),
        const SizedBox(width: 8),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          enabled: hasNext,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _DayOnlyHeader extends StatelessWidget {
  const _DayOnlyHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.section,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textMuted : AppColors.textFaint,
        ),
      ),
    );
  }
}

class _PlanningDayCard extends StatelessWidget {
  const _PlanningDayCard({
    required this.planning,
    required this.dayNumber,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final MobilePlanningDay planning;
  final int dayNumber;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 74,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.gold : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              'J$dayNumber',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.gold : AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              planning.date.day.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: planning.evenements.isNotEmpty
                    ? AppColors.gold
                    : AppColors.border,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedDaySection extends StatelessWidget {
  const _SelectedDaySection({
    required this.planning,
    required this.dayNumber,
  });

  final MobilePlanningDay planning;
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    final locationLabel = _primaryLocation(planning.evenements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'J${dayNumber.toString()} - ${planning.titre?.trim().isNotEmpty == true ? planning.titre! : 'Journee'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            if (locationLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  locationLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (planning.evenements.isEmpty)
          const _PlanningEmptyState(
            title: 'Aucun evenement pour cette journee',
            message: 'Cette journee existe, mais aucun evenement n a encore ete ajoute.',
            compact: true,
          )
        else
          ...planning.evenements.asMap().entries.map(
            (entry) => _TimelineEventTile(
              event: entry.value,
              isLast: entry.key == planning.evenements.length - 1,
            ),
          ),
      ],
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({
    required this.event,
    required this.isLast,
  });

  final MobilePlanningEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final displayTime = event.heureDebutPrevue != null
        ? _formatHour(event.heureDebutPrevue!)
        : '--:--';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Column(
              children: [
                Text(
                  displayTime,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: 1.4,
                    color: isLast ? Colors.transparent : AppColors.borderSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSoft),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (event.lieux.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.lieux
                            .map(
                              (lieu) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.section,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  lieu,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MetaPill(
                          label: _eventTypeLabel(event.type),
                          background: _eventTypeSoftColor(event.type),
                          foreground: _eventTypeStrongColor(event.type),
                        ),
                      ],
                    ),
                    if (event.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Text(
                        event.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _PlanningEmptyState extends StatelessWidget {
  const _PlanningEmptyState({
    required this.title,
    required this.message,
    this.compact = false,
  });

  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: compact ? 34 : 42,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningErrorState extends StatelessWidget {
  const _PlanningErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textFaint,
            ),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger le planning',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

int _tripLengthInDays(DateTime? start, DateTime? end) {
  if (start == null || end == null) return 0;
  return end.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
}

int _tripDayNumber(DateTime? start, DateTime date) {
  if (start == null) return 1;
  final normalizedStart = DateTime(start.year, start.month, start.day);
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final difference = normalizedDate.difference(normalizedStart).inDays;
  return difference < 0 ? 1 : difference + 1;
}

String _tripSubtitle(MobilePlanningGroup groupe) {
  final type = groupe.typeVoyage == 'HAJJ' ? 'Groupe Hajj' : 'Groupe Omra';
  return '$type - ${groupe.annee}';
}

String _formatHour(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatMediumDate(DateTime value) {
  const months = [
    'janv',
    'fevr',
    'mars',
    'avr',
    'mai',
    'juin',
    'juil',
    'aout',
    'sept',
    'oct',
    'nov',
    'dec',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]}';
}

String _eventTypeLabel(String type) {
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
      return 'Autre';
  }
}

Color _eventTypeSoftColor(String type) {
  switch (type) {
    case 'TRANSPORT':
      return AppColors.blueSoft;
    case 'VISITE':
      return AppColors.greenSoft;
    case 'RITE':
      return AppColors.goldSoft;
    default:
      return AppColors.section;
  }
}

Color _eventTypeStrongColor(String type) {
  switch (type) {
    case 'TRANSPORT':
      return AppColors.blue;
    case 'VISITE':
      return AppColors.green;
    case 'RITE':
      return AppColors.gold;
    default:
      return AppColors.textMuted;
  }
}

String? _primaryLocation(List<MobilePlanningEvent> events) {
  for (final event in events) {
    for (final lieu in event.lieux) {
      final cleaned = lieu.trim();
      if (cleaned.isNotEmpty) return cleaned;
    }
  }
  return null;
}

MobilePlanningEvent? _currentOrNextEvent(List<MobilePlanningEvent> events) {
  if (events.isEmpty) return null;

  final now = DateTime.now();
  for (var index = 0; index < events.length; index += 1) {
    final event = events[index];
    final start = event.heureDebutPrevue;
    final nextStart =
        index + 1 < events.length ? events[index + 1].heureDebutPrevue : null;

    if (start == null) {
      return event;
    }

    final isCurrent = !start.isAfter(now) &&
        (nextStart == null || nextStart.isAfter(now));
    if (isCurrent) {
      return event;
    }

    if (start.isAfter(now)) {
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
