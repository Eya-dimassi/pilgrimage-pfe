import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../data/mobile_planning_repository.dart';
import '../domain/mobile_planning_models.dart';
import '../providers/mobile_planning_provider.dart';
import '../../../services/planning_feed_refresh_service.dart';

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
  final Set<String> _validatingEventIds = <String>{};

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
    final isDayOnly = widget.view == PlanningRoleView.famille;
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
            final selectedTripDayNumber = selectedDay == null
                ? 0
                : _tripDayNumber(planningData.groupe.dateDepart, selectedDay.date);
            final selectedDayNumber = selectedDay == null
                ? 0
                : _planningDisplayDayNumber(
                    planningData.plannings,
                    selectedDay,
                    fallbackStartDate: planningData.groupe.dateDepart,
                  );

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
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 102),
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
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _buildRoleHeader(
                    planningData: planningData,
                    selectedDay: selectedDay,
                    dayNumber: selectedTripDayNumber,
                    accentColor: widget.accentColor,
                  ),
                  const SizedBox(height: AppSpacing.m),
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
                      const SizedBox(height: AppSpacing.s),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: planningData.plannings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.s),
                          itemBuilder: (context, index) {
                            final day = planningData.plannings[index];
                            return _PlanningDayCard(
                              planning: day,
                              dayNumber: _planningDisplayDayNumber(
                                planningData.plannings,
                                day,
                                fallbackStartDate:
                                    planningData.groupe.dateDepart,
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
                      const SizedBox(height: AppSpacing.l),
                    ] else ...[
                      _DayOnlyHeader(
                        title: widget.view == PlanningRoleView.famille
                            ? 'Aujourd hui'
                            : 'Planning du jour',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (selectedDay != null)
                      _SelectedDaySection(
                        planning: selectedDay,
                        dayNumber: selectedDayNumber,
                        isGuide: widget.view == PlanningRoleView.guide,
                        validatingEventIds: _validatingEventIds,
                        onValidateEvent: widget.view == PlanningRoleView.guide
                            ? (event) => _validateEvent(
                                  groupeId: selectedGroup.id,
                                  event: event,
                                )
                            : null,
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

    return _pickBestGroup(groups);
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
      final nextGroup = _pickBestGroup(groups);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedGroupId = nextGroup.id;
          _selectedPlanningId = null;
        });
      });
    }
  }

  MobilePlanningGroup _pickBestGroup(List<MobilePlanningGroup> groups) {
    if (groups.isEmpty) {
      throw StateError('Cannot pick a group from an empty list.');
    }

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
    if (widget.view == PlanningRoleView.pelerin) {
      final todayAst = _startOfAstDay(DateTime.now());

      for (final planning in plannings) {
        final planningDayAst = _startOfAstDay(planning.date);
        if (planningDayAst.isAtSameMomentAs(todayAst)) {
          return planning;
        }
        if (planningDayAst.isAfter(todayAst)) {
          return planning;
        }
      }

      return plannings.last;
    }

    return plannings.first;
  }

  Future<void> _validateEvent({
    required MobilePlanningEvent event,
    required String groupeId,
  }) async {
    if (!event.canBeValidated || _validatingEventIds.contains(event.id)) return;

    setState(() => _validatingEventIds.add(event.id));

    try {
      await ref.read(mobilePlanningRepositoryProvider).validateEvent(
            groupeId: groupeId,
            eventId: event.id,
          );
      PlanningFeedRefreshService.instance.bump();
      ref.invalidate(mobilePlanningDetailProvider(groupeId));
      await ref.read(mobilePlanningDetailProvider(groupeId).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Etape validee')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Validation impossible: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _validatingEventIds.remove(event.id));
      }
    }
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
          illustrationAssetPath: 'assets/images/mosque_guide.png',
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
          illustrationAssetPath: 'assets/images/mosque_home.png',
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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, index) {
          final group = groups[index];
          final selected = group.id == selectedGroupId;

          return InkWell(
            onTap: () => onSelected(group.id),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: selected ? AppShadows.soft : const [],
              ),
              child: Text(
                group.nom.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.8,
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
    required this.illustrationAssetPath,
    required this.plannedDaysCount,
    this.currentTripDay,
    this.compact = false,
  });

  final MobilePlanningGroup groupe;
  final Color accentColor;
  final String illustrationAssetPath;
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

    return AppCard(
      padding: EdgeInsets.fromLTRB(
        compact ? 15 : 18,
        compact ? 15 : 18,
        compact ? 15 : 18,
        compact ? 14 : 16,
      ),
      radius: 24,
      gradient: compact
          ? AppGradients.heroSoft
          : const LinearGradient(
              colors: [
                Color(0xFFF4FBF8),
                Color(0xFFE8F5EF),
                Color(0xFFF9FCFA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      shadow: AppShadows.lifted,
      child: Stack(
        children: [
          if (!compact)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: RadialGradient(
                    center: const Alignment(0.88, -0.18),
                    radius: 0.9,
                    colors: [
                      AppColors.greenSoft.withValues(alpha: 0.62),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          if (!compact)
            Positioned(
              left: -18,
              top: 34,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.greenSoft.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Positioned(
            top: compact ? 16 : 18,
            right: compact ? 12 : 18,
            child: Opacity(
              opacity: compact ? 0.9 : 0.92,
              child: AppHeroAsset(
                assetPath: illustrationAssetPath,
                width: compact ? 66 : 112,
                height: compact ? 68 : 88,
                scale: compact ? 1.01 : 1.04,
                alignment: compact ? Alignment.bottomRight : Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStatusChip(
                label:
                    '${groupe.typeVoyage == 'HAJJ' ? 'HAJJ' : 'OMRA'} ${groupe.annee}',
                icon: Icons.auto_awesome_rounded,
                backgroundColor: compact
                    ? AppColors.greenSoft
                    : Colors.white.withValues(alpha: 0.72),
                foregroundColor: AppColors.primary,
                compact: true,
              ),
              SizedBox(height: compact ? 8 : 10),
              SizedBox(
                width: compact ? 160 : 150,
                child: Text(
                  groupe.nom,
                  style: TextStyle(
                    fontSize: compact ? 19 : 23,
                    fontWeight: FontWeight.w800,
                    height: 1.02,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _tripSubtitle(groupe),
                style: TextStyle(
                  fontSize: compact ? 11.5 : 12.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (groupe.dateDepart != null && groupe.dateRetour != null) ...[
                SizedBox(height: compact ? 9 : 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: compact ? 16 : 18,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${_formatMediumDate(groupe.dateDepart!)} -> ${_formatMediumDate(groupe.dateRetour!)}',
                      style: TextStyle(
                        fontSize: compact ? 11.5 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: compact ? 12 : 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progressDetail,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    percentageLabel,
                    style: TextStyle(
                      fontSize: compact ? 15 : 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 8),
              Container(
                height: compact ? 5 : 6,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: compact ? accentColor : AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ),
            ],
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      radius: AppRadii.xl,
      gradient: AppGradients.heroSoft,
      shadow: AppShadows.lifted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStatusChip(
            label: 'Live now',
            icon: Icons.bolt_rounded,
            backgroundColor: accentColor.withValues(alpha: 0.12),
            foregroundColor: accentColor,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            groupe.nom,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.m),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: AppColors.borderSoft,
              color: accentColor,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          _FamilyInfoRow(
            label: 'Lieu',
            value: currentLocation ?? 'A confirmer',
          ),
          const SizedBox(height: AppSpacing.sm),
          _FamilyInfoRow(
            label: 'Activite',
            value: currentEvent?.titre ?? 'Aucune activite en cours',
          ),
          const SizedBox(height: AppSpacing.sm),
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
    return SectionTitle(
      'Journees',
      subtitle: '',
      bottomPadding: AppSpacing.sm,
      titleStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrevious,
            onTap: onPrevious,
          ),
          const SizedBox(width: AppSpacing.s),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            enabled: hasNext,
            onTap: onNext,
          ),
        ],
      ),
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
    return SectionTitle(
      title,
      subtitle: 'Today view for the selected journey.',
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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.soft,
        ),
        child: Icon(
          icon,
          size: 18,
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
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.borderSoft,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Text(
              'J$dayNumber',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.gold : AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _toAst(planning.date).day.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _monthLabel(planning.date),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
            ),
            const Spacer(),
            Container(
              width: 8,
              height: 8,
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
    required this.isGuide,
    required this.validatingEventIds,
    required this.onValidateEvent,
  });

  final MobilePlanningDay planning;
  final int dayNumber;
  final bool isGuide;
  final Set<String> validatingEventIds;
  final ValueChanged<MobilePlanningEvent>? onValidateEvent;

  @override
  Widget build(BuildContext context) {
    final locationLabel = _primaryLocation(planning.evenements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'J${dayNumber.toString()} - ${_planningTitleLabel(planning)}',
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            height: 1.18,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Programme partage pour cette journee.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            if (locationLabel != null)
              AppStatusChip(
                label: locationLabel,
                icon: _locationIcon(locationLabel),
                backgroundColor: AppColors.goldSoft,
                foregroundColor: AppColors.gold,
                compact: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (planning.evenements.isEmpty)
          const _PlanningEmptyState(
            title: 'Aucun evenement pour cette journee',
            message: 'Cette journee existe, mais aucun evenement n a encore ete ajoute.',
            compact: true,
          )
        else
          ...planning.evenements.asMap().entries.map(
            (entry) {
              final event = entry.value;
              return _TimelineEventTile(
                event: event,
                isLast: entry.key == planning.evenements.length - 1,
                canValidate: isGuide && !event.estValide,
                isValidating: validatingEventIds.contains(event.id),
                onValidate: onValidateEvent == null
                    ? null
                    : () {
                        _confirmAndValidateEvent(
                          context,
                          event,
                          onValidateEvent!,
                        );
                      },
              );
            },
          ),
      ],
    );
  }
}

Future<void> _confirmAndValidateEvent(
  BuildContext context,
  MobilePlanningEvent event,
  ValueChanged<MobilePlanningEvent> onValidateEvent,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirmer la validation'),
          content: Text(
            'Voulez-vous valider cet evenement : "${event.titre}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Valider'),
            ),
          ],
        ),
      ) ??
      false;

  if (!context.mounted || !confirmed) {
    return;
  }

  onValidateEvent(event);
}

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({
    required this.event,
    required this.isLast,
    required this.canValidate,
    required this.isValidating,
    this.onValidate,
  });

  final MobilePlanningEvent event;
  final bool isLast;
  final bool canValidate;
  final bool isValidating;
  final VoidCallback? onValidate;

  @override
  Widget build(BuildContext context) {
    final displayTime = event.heureDebutPrevue != null
        ? _formatHour(event.heureDebutPrevue!)
        : '--:--';
    final canShowValidation =
        event.type != 'PRIERE' && (canValidate || event.estValide);
    final timelineColor = event.estValide ? AppColors.green : AppColors.borderSoft;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  displayTime,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textFaint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: event.estValide ? 22 : 10,
                  height: event.estValide ? 22 : 10,
                  decoration: BoxDecoration(
                    color: event.estValide ? AppColors.greenSoft : AppColors.goldSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: event.estValide ? AppColors.green : AppColors.gold,
                      width: event.estValide ? 1.6 : 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: event.estValide
                      ? const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: AppColors.green,
                        )
                      : Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Container(
                    width: event.estValide ? 2 : 1.4,
                    decoration: BoxDecoration(
                      color: isLast ? Colors.transparent : timelineColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                radius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.titre,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        if (event.estValide)
                          const Padding(
                            padding: EdgeInsets.only(left: 8, top: 1),
                            child: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: AppColors.textFaint,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        AppStatusChip(
                          label: _eventTypeLabel(event.type),
                          icon: _eventTypeIcon(event.type),
                          backgroundColor: _eventTypeSoftColor(event.type),
                          foregroundColor: _eventTypeStrongColor(event.type),
                          compact: true,
                        ),
                        if (event.estValide)
                          const _MetaPill(
                            label: 'Valide',
                            icon: Icons.check_circle_rounded,
                            background: AppColors.greenSoft,
                            foreground: AppColors.green,
                          ),
                      ],
                    ),
                    if (event.lieux.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: event.lieux
                            .map(
                              (lieu) => AppStatusChip(
                                label: lieu,
                                icon: _locationIcon(lieu),
                                backgroundColor: AppColors.section,
                                foregroundColor: AppColors.textMuted,
                                compact: true,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (event.etape?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 7),
                      _MetaPill(
                        label: _formatEtapeLabel(event.etape!),
                        background: AppColors.section,
                        foreground: AppColors.textMuted,
                      ),
                    ],
                    if (event.estValide && event.valideeAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Valide a ${_formatHour(event.valideeAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: AppColors.green,
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Etape validee',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Cette etape a ete validee avec succes.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (event.description?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 7),
                      Text(
                        event.description!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    if (canShowValidation) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: event.estValide
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 17,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Etape validee',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : FilledButton(
                                onPressed: isValidating ? null : onValidate,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isValidating)
                                      const SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      const Icon(Icons.check_rounded, size: 17),
                                    const SizedBox(width: 8),
                                    Text(
                                      isValidating
                                          ? 'Validation...'
                                          : 'Valider l etape',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
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
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppStatusChip(
      label: label,
      icon: icon,
      backgroundColor: background,
      foregroundColor: foreground,
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
    return AppCard(
      padding: EdgeInsets.all(compact ? 20 : 24),
      radius: AppRadii.lg,
      child: Column(
        children: [
          AppIconBadge(
            icon: Icons.calendar_month_outlined,
            size: compact ? 54 : 58,
            backgroundColor: AppColors.goldSoft,
            foregroundColor: AppColors.gold,
          ),
          const SizedBox(height: AppSpacing.sm),
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
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          radius: AppRadii.lg,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIconBadge(
              icon: Icons.error_outline_rounded,
              size: 56,
              backgroundColor: AppColors.redSoft,
              foregroundColor: AppColors.red,
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.m),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

int _tripLengthInDays(DateTime? start, DateTime? end) {
  if (start == null || end == null) return 0;
  return _startOfAstDay(end).difference(_startOfAstDay(start)).inDays + 1;
}

int _tripDayNumber(DateTime? start, DateTime date) {
  if (start == null) return 1;
  final normalizedStart = _startOfAstDay(start);
  final normalizedDate = _startOfAstDay(date);
  final difference = normalizedDate.difference(normalizedStart).inDays;
  return difference < 0 ? 1 : difference + 1;
}

String _tripSubtitle(MobilePlanningGroup groupe) {
  final type = groupe.typeVoyage == 'HAJJ' ? 'Groupe Hajj' : 'Groupe Omra';
  return '$type - ${groupe.annee}';
}

String _planningTitleLabel(MobilePlanningDay planning) {
  final rawTitle = planning.titre?.trim();
  if (rawTitle == null || rawTitle.isEmpty) {
    return 'Journee';
  }

  final cleanedTitle = rawTitle.replaceFirst(
    RegExp(r'^(?:j(?:our)?\s*\d+)\s*[-:]\s*', caseSensitive: false),
    '',
  );
  return cleanedTitle.trim().isEmpty ? 'Journee' : cleanedTitle.trim();
}

int _planningDisplayDayNumber(
  List<MobilePlanningDay> plannings,
  MobilePlanningDay planning, {
  DateTime? fallbackStartDate,
}) {
  final index = plannings.indexWhere((day) => day.id == planning.id);
  if (index >= 0) {
    return index + 1;
  }
  return _tripDayNumber(fallbackStartDate, planning.date);
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
  final astDate = _toAst(value);
  return '${astDate.day.toString().padLeft(2, '0')} ${months[astDate.month - 1]}';
}

DateTime _toAst(DateTime value) {
  return value.toUtc().add(const Duration(hours: 3));
}

DateTime _startOfAstDay(DateTime value) {
  final ast = _toAst(value);
  return DateTime.utc(ast.year, ast.month, ast.day);
}

String _monthLabel(DateTime value) {
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
  return months[value.month - 1];
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

IconData _eventTypeIcon(String type) {
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

String _formatEtapeLabel(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
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

IconData _locationIcon(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('masjid') ||
      normalized.contains('haram') ||
      normalized.contains('mecque') ||
      normalized.contains('kaaba')) {
    return Icons.mosque_outlined;
  }
  if (normalized.contains('hotel')) {
    return Icons.hotel_rounded;
  }
  if (normalized.contains('miqat') ||
      normalized.contains('safa') ||
      normalized.contains('marwa')) {
    return Icons.place_outlined;
  }
  return Icons.location_on_outlined;
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
