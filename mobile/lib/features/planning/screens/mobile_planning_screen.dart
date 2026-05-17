import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/saudi_time.dart';
import '../../../core/utils/trip_progress.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/mobile_planning_repository.dart';
import '../domain/mobile_planning_models.dart';
import '../providers/mobile_planning_provider.dart';
import '../../../services/planning_feed_refresh_service.dart';

enum PlanningRoleView { guide, pelerin, famille }

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
  String? _activeUserId;
  final Set<String> _updatingEventIds = <String>{};

  @override
  void initState() {
    super.initState();
    _activeUserId = ref.read(authProvider).valueOrNull?.user.id;
  }

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
    final activeUserId = ref.watch(
      authProvider.select((state) => state.valueOrNull?.user.id),
    );
    if (_activeUserId != activeUserId) {
      _activeUserId = activeUserId;
      _selectedGroupId = null;
      _selectedPlanningId = null;
      _updatingEventIds.clear();
    }

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
            final visiblePlannings = expandPlanningDaysForPlanningView(
              plannings: planningData.plannings,
              referenceDay: SaudiTime.now(),
              tripStart: planningData.groupe.dateDepart,
              tripEnd: planningData.groupe.dateRetour,
              fullTrip: widget.view == PlanningRoleView.guide,
              daysBefore: widget.view == PlanningRoleView.pelerin ? 1 : 0,
              daysAfter: widget.view == PlanningRoleView.pelerin ? 1 : 0,
            );

            if (!isDayOnly) {
              _ensureSelectedPlanning(visiblePlannings);
            }

            final exactTodayPlanning = findPlanningDayForDate(
              visiblePlannings,
              SaudiTime.now(),
            );
            final selectedIndex = isDayOnly
                ? exactTodayPlanning == null
                      ? -1
                      : visiblePlannings.indexWhere(
                          (planning) => planning.id == exactTodayPlanning.id,
                        )
                : visiblePlannings.indexWhere(
                    (planning) => planning.id == _selectedPlanningId,
                  );
            final selectedDay = isDayOnly
                ? (selectedIndex >= 0 ? visiblePlannings[selectedIndex] : null)
                : (selectedIndex >= 0 ? visiblePlannings[selectedIndex] : null);
            final selectedTripDayNumber = selectedDay == null
                ? 0
                : _tripDayNumber(
                    planningData.groupe.dateDepart,
                    selectedDay.date,
                  );
            final selectedDayNumber = selectedDay == null
                ? 0
                : _planningDisplayDayNumber(
                    visiblePlannings,
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
                  if (visiblePlannings.isEmpty)
                    _PlanningEmptyState(
                      title: widget.view == PlanningRoleView.famille
                          ? 'Aucun planning aujourd hui'
                          : 'Aucune journee disponible',
                      message: widget.view == PlanningRoleView.famille
                          ? 'Le groupe n a pas encore de programme partage pour aujourd hui.'
                          : 'Aucune journee du voyage n est disponible pour le moment.',
                    )
                  else if (isDayOnly && selectedDay == null)
                    const _PlanningEmptyState(
                      title: 'Aucun planning aujourd hui',
                      message:
                          'Le groupe n a pas encore de programme partage pour aujourd hui.',
                    )
                  else ...[
                    if (!isDayOnly) ...[
                      _DayRailHeader(
                        hasPrevious: selectedIndex > 0,
                        hasNext:
                            selectedIndex >= 0 &&
                            selectedIndex < visiblePlannings.length - 1,
                        onPrevious: selectedIndex > 0
                            ? () {
                                setState(() {
                                  _selectedPlanningId =
                                      visiblePlannings[selectedIndex - 1].id;
                                });
                              }
                            : null,
                        onNext:
                            selectedIndex >= 0 &&
                                selectedIndex < visiblePlannings.length - 1
                            ? () {
                                setState(() {
                                  _selectedPlanningId =
                                      visiblePlannings[selectedIndex + 1].id;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: visiblePlannings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.s),
                          itemBuilder: (context, index) {
                            final day = visiblePlannings[index];
                            return _PlanningDayCard(
                              planning: day,
                              dayNumber: _planningDisplayDayNumber(
                                visiblePlannings,
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
                        updatingEventIds: _updatingEventIds,
                        onUpdateEventStatus:
                            widget.view == PlanningRoleView.guide
                            ? (event, status) => _updateEventStatus(
                                groupeId: selectedGroup.id,
                                event: event,
                                status: status,
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

    return pickBestPlanningGroup(groups);
  }

  void _ensureSelectedGroup(List<MobilePlanningGroup> groups) {
    if (groups.isEmpty) return;

    final preferredExists =
        widget.preferredGroupId != null &&
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
      final nextGroup = pickBestPlanningGroup(groups);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedGroupId = nextGroup.id;
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

    final nextPlanning = pickDefaultPlanningDay(
      plannings,
      referenceDay: SaudiTime.now(),
    );
    if (nextPlanning == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedPlanningId = nextPlanning.id;
      });
    });
  }

  Future<void> _updateEventStatus({
    required MobilePlanningEvent event,
    required String groupeId,
    required String status,
  }) async {
    if (_updatingEventIds.contains(event.id)) return;
    if (status == 'TERMINE' && !event.canBeCompleted) return;
    if (status == 'ANNULE' && !event.canBeCancelled) return;

    setState(() => _updatingEventIds.add(event.id));

    try {
      await ref
          .read(mobilePlanningRepositoryProvider)
          .updateEventStatus(
            groupeId: groupeId,
            eventId: event.id,
            status: status,
          );
      PlanningFeedRefreshService.instance.bump();
      ref.invalidate(mobilePlanningDetailProvider(groupeId));
      await ref.read(mobilePlanningDetailProvider(groupeId).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'ANNULE' ? 'Etape annulee' : 'Etape terminee',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${status == 'ANNULE' ? 'Annulation impossible' : 'Mise a jour impossible'}: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingEventIds.remove(event.id));
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
          currentDayDate: selectedDay?.date,
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
          illustrationAssetPath: 'assets/images/kaaba.png',
          plannedDaysCount: planningData.plannings.length,
          currentDayDate: selectedDay?.date,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    this.currentDayDate,
    this.currentTripDay,
    this.compact = false,
  });

  final MobilePlanningGroup groupe;
  final Color accentColor;
  final String illustrationAssetPath;
  final int plannedDaysCount;
  final DateTime? currentDayDate;
  final int? currentTripDay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final totalTripDays = _tripLengthInDays(
      groupe.dateDepart,
      groupe.dateRetour,
    );
    final boundedCurrentTripDay = currentTripDay?.clamp(
      0,
      totalTripDays == 0 ? 0 : totalTripDays,
    );
    final progress = computeTripProgress(
      groupe.dateDepart,
      groupe.dateRetour,
      DateTime.now(),
    );
    final percentageLabel = '${(progress * 100).round()}%';
    final progressDetail = totalTripDays == 0
        ? 'Progression du voyage'
        : 'Jour ${boundedCurrentTripDay ?? 0} sur $totalTripDays';

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
              colors: [Color(0xFFF4FBF8), Color(0xFFE8F5EF), Color(0xFFF9FCFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
      shadow: AppShadows.lifted,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── guide: radial glow + large bottom-right image ──
          if (!compact) ...[
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
              right: -6,
              bottom: -10,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.96,
                  child:
                      AppHeroAsset(
                            assetPath: illustrationAssetPath,
                            width: 144,
                            height: 156,
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
          ],

          // ── pèlerin compact: bigger image, better anchored ──
          if (compact)
            Positioned(
              // anchor to right edge and bottom of card
              right: -4,
              bottom: -14,
              child: IgnorePointer(
                child:
                    AppHeroAsset(
                          assetPath: illustrationAssetPath,
                          // FIX: was 66×68 — now 148×160, large enough to feel
                          // intentional and grounded at the bottom-right
                          width: 148,
                          height: 160,
                          scale: 1.0,
                          alignment: Alignment.bottomRight,
                          fit: BoxFit.contain,
                        )
                        // FIX: entrance — fades + slides in from right on build
                        .animate()
                        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                        .slideX(
                          begin: 0.12,
                          end: 0,
                          duration: 500.ms,
                          curve: Curves.easeOutCubic,
                        )
                        // FIX: idle — gentle floating loop (same as guide card)
                        .then()
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -6,
                          duration: 2400.ms,
                          curve: Curves.easeInOut,
                        ),
              ),
            ),

          // ── text content — right padding guards against image ──
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
              // FIX: constrain text width so it never overlaps the image
              SizedBox(
                width: compact ? 170 : 150,
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
              // subtitle also constrained
              SizedBox(
                width: compact ? 170 : double.infinity,
                child: Text(
                  _tripSubtitle(groupe),
                  style: TextStyle(
                    fontSize: compact ? 11.5 : 12.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
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
              // progress row — constrained width on compact so
              // percentage label doesn't collide with the image
              SizedBox(
                width: compact ? 175 : double.infinity,
                child: Row(
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
              ),
              SizedBox(height: compact ? 6 : 8),
              // progress bar — also constrained on compact
              SizedBox(
                width: compact ? 175 : double.infinity,
                child: Container(
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
              ),
              // FIX: extra bottom padding on compact so the image
              // (which overflows below the card) has room to breathe
              if (compact) const SizedBox(height: 56),
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
    final currentEvent = pickCurrentOrNextPlanningEvent(
      planning?.evenements ?? const [],
    );
    final events = sortPlanningEventsByTime(planning?.evenements ?? const []);
    final currentIndex = currentEvent == null
        ? -1
        : events.indexWhere((e) => e.id == currentEvent.id);
    final nextEvent = (currentIndex >= 0 && currentIndex < events.length - 1)
        ? events[currentIndex + 1]
        : null;
    final currentLocation = currentEvent == null
        ? null
        : _primaryLocation([currentEvent]);
    final totalTripDays = _tripLengthInDays(
      groupe.dateDepart,
      groupe.dateRetour,
    );
    final progress = computeTripProgress(
      groupe.dateDepart,
      groupe.dateRetour,
      DateTime.now(),
    );

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
                : _planningSectionHeading(dayNumber, planning!),
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
  const _FamilyInfoRow({required this.label, required this.value});

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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
  const _DayOnlyHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionTitle(title);
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
              SaudiTime.inSaudi(planning.date).day.toString().padLeft(2, '0'),
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
    required this.updatingEventIds,
    required this.onUpdateEventStatus,
  });

  final MobilePlanningDay planning;
  final int dayNumber;
  final bool isGuide;
  final Set<String> updatingEventIds;
  final void Function(MobilePlanningEvent event, String status)?
  onUpdateEventStatus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _planningSectionHeading(dayNumber, planning),
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            height: 1.18,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (planning.evenements.isEmpty)
          const _PlanningEmptyState(
            title: 'Aucun evenement pour cette journee',
            compact: true,
          )
        else
          ...planning.evenements.asMap().entries.map((entry) {
            final event = entry.value;
            return _TimelineEventTile(
              event: event,
              isLast: entry.key == planning.evenements.length - 1,
              canComplete: isGuide && event.canBeCompleted,
              canCancel: isGuide && event.canBeCancelled,
              isUpdating: updatingEventIds.contains(event.id),
              onComplete: onUpdateEventStatus == null
                  ? null
                  : () {
                      _confirmAndUpdateEventStatus(
                        context,
                        event,
                        'TERMINE',
                        onUpdateEventStatus!,
                      );
                    },
              onCancel: onUpdateEventStatus == null
                  ? null
                  : () {
                      _confirmAndUpdateEventStatus(
                        context,
                        event,
                        'ANNULE',
                        onUpdateEventStatus!,
                      );
                    },
            );
          }),
      ],
    );
  }
}

Future<void> _confirmAndUpdateEventStatus(
  BuildContext context,
  MobilePlanningEvent event,
  String status,
  void Function(MobilePlanningEvent event, String status) onUpdateEventStatus,
) async {
  final isCancellation = status == 'ANNULE';
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            isCancellation
                ? 'Confirmer l annulation'
                : 'Confirmer la fin de l etape',
          ),
          content: Text(
            isCancellation
                ? 'Voulez-vous annuler cet evenement : "${event.titre}" ?'
                : 'Voulez-vous marquer cet evenement comme termine : "${event.titre}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isCancellation ? 'Annuler l etape' : 'Terminer'),
            ),
          ],
        ),
      ) ??
      false;

  if (!context.mounted || !confirmed) {
    return;
  }

  onUpdateEventStatus(event, status);
}

class _TimelineEventTile extends StatelessWidget {
  const _TimelineEventTile({
    required this.event,
    required this.isLast,
    required this.canComplete,
    required this.canCancel,
    required this.isUpdating,
    this.onComplete,
    this.onCancel,
  });

  final MobilePlanningEvent event;
  final bool isLast;
  final bool canComplete;
  final bool canCancel;
  final bool isUpdating;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final displayTime = event.heureDebutPrevue != null
        ? _formatHour(event.heureDebutPrevue!)
        : '--:--';
    final description = event.description?.trim();
    final hasDescription = description?.isNotEmpty == true;
    final hasLongDescription = _isLongEventDescription(description);
    final showActionRow = canComplete || canCancel;
    final statusAccent = _eventStatusColor(event);
    final statusSoft = _eventStatusSoftColor(event);
    final statusIcon = _eventStatusIcon(event);
    final statusLabel = _eventStatusLabel(event);
    final isResolved = event.isResolved;

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
                  width: isResolved ? 22 : 10,
                  height: isResolved ? 22 : 10,
                  decoration: BoxDecoration(
                    color: isResolved ? statusSoft : AppColors.goldSoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isResolved ? statusAccent : AppColors.gold,
                      width: isResolved ? 1.6 : 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isResolved
                      ? Icon(statusIcon, size: 13, color: statusAccent)
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
                    width: isResolved ? 2 : 1.4,
                    decoration: BoxDecoration(
                      color: isLast
                          ? Colors.transparent
                          : (isResolved ? statusAccent : AppColors.borderSoft),
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
                        ...event.lieux.map(
                          (lieu) => AppStatusChip(
                            label: lieu,
                            icon: _locationIcon(lieu),
                            backgroundColor: _locationSoftColor(lieu),
                            foregroundColor: _locationStrongColor(lieu),
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    if (isResolved) ...[
                      const SizedBox(height: 7),
                      _MetaPill(
                        label: statusLabel,
                        icon: statusIcon,
                        background: statusSoft,
                        foreground: statusAccent,
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
                    if (event.isCompleted && event.valideeAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Terminee a ${_formatHour(event.valideeAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: statusAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (hasDescription) ...[
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              description!,
                              maxLines: hasLongDescription ? 3 : null,
                              overflow: hasLongDescription
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.visible,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          if (hasLongDescription) ...[
                            const SizedBox(width: 8),
                            _DescriptionInfoButton(description: description),
                          ],
                        ],
                      ),
                      if (hasLongDescription) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Description complete',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ],
                    ],
                    if (showActionRow) ...[
                      const SizedBox(height: 10),
                      _buildEventActionArea(isUpdating: isUpdating),
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

  Widget _buildEventActionArea({required bool isUpdating}) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: isUpdating ? null : onComplete,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isUpdating)
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
                  isUpdating ? 'Mise a jour...' : 'Terminer',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: isUpdating ? null : onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            side: const BorderSide(color: AppColors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Annuler',
            style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
          ),
        ),
      ],
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

class _DescriptionInfoButton extends StatelessWidget {
  const _DescriptionInfoButton({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => _showDescriptionDialog(context, description),
        borderRadius: BorderRadius.circular(999),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.blue,
          ),
        ),
      ),
    );
  }
}

class _PlanningEmptyState extends StatelessWidget {
  const _PlanningEmptyState({
    required this.title,
    this.message = '',
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (message.trim().isNotEmpty) ...[
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
        ],
      ),
    );
  }
}

class _PlanningErrorState extends StatelessWidget {
  const _PlanningErrorState({required this.message, required this.onRetry});

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
  return SaudiTime.dayOf(end).difference(SaudiTime.dayOf(start)).inDays + 1;
}

int _tripDayNumber(DateTime? start, DateTime date) {
  if (start == null) return 1;
  final normalizedStart = SaudiTime.dayOf(start);
  final normalizedDate = SaudiTime.dayOf(date);
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
    RegExp(r'^(?:j(?:our)?\s*\d+)(?:\s*[-:]\s*|\s*$)', caseSensitive: false),
    '',
  );
  return cleanedTitle.trim().isEmpty ? 'Journee' : cleanedTitle.trim();
}

String _planningSectionHeading(int dayNumber, MobilePlanningDay planning) {
  final cleanedTitle = _planningTitleLabel(planning);
  if (cleanedTitle == 'Journee') {
    return 'Jour $dayNumber';
  }
  return 'Jour $dayNumber - $cleanedTitle';
}

int _planningDisplayDayNumber(
  List<MobilePlanningDay> plannings,
  MobilePlanningDay planning, {
  DateTime? fallbackStartDate,
}) {
  if (fallbackStartDate != null) {
    return _tripDayNumber(fallbackStartDate, planning.date);
  }
  final index = plannings.indexWhere((day) => day.id == planning.id);
  if (index >= 0) {
    return index + 1;
  }
  return _tripDayNumber(fallbackStartDate, planning.date);
}

String _formatHour(DateTime value) {
  return SaudiTime.formatHour(value);
}

bool _isLongEventDescription(String? value) {
  if (value == null) return false;
  final normalized = value.trim();
  return normalized.length > 120 || '\n'.allMatches(normalized).length >= 2;
}

Future<void> _showDescriptionDialog(BuildContext context, String description) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.lifted,
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Description complete',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
  final astDate = SaudiTime.inSaudi(value);
  return '${astDate.day.toString().padLeft(2, '0')} ${months[astDate.month - 1]}';
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
    case 'REPAS':
      return 'Repas';
    case 'REPOS':
      return 'Repos';
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
    case 'REPAS':
      return Icons.restaurant_outlined;
    case 'REPOS':
      return Icons.king_bed_outlined;
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

String _eventStatusLabel(MobilePlanningEvent event) {
  if (event.isCancelled) return 'Annulee';
  if (event.isCompleted) return 'Terminee';
  if (event.status == 'EN_COURS') return 'En cours';
  return 'Planifiee';
}

IconData _eventStatusIcon(MobilePlanningEvent event) {
  if (event.isCancelled) return Icons.cancel_outlined;
  if (event.isCompleted) return Icons.check_circle_rounded;
  if (event.status == 'EN_COURS') return Icons.play_circle_outline_rounded;
  return Icons.schedule_rounded;
}

Color _eventStatusColor(MobilePlanningEvent event) {
  if (event.isCancelled) return AppColors.red;
  if (event.isCompleted) return AppColors.green;
  if (event.status == 'EN_COURS') return AppColors.blue;
  return AppColors.gold;
}

Color _eventStatusSoftColor(MobilePlanningEvent event) {
  if (event.isCancelled) return AppColors.redSoft;
  if (event.isCompleted) return AppColors.greenSoft;
  if (event.status == 'EN_COURS') return AppColors.blueSoft;
  return AppColors.goldSoft;
}

Color _eventTypeSoftColor(String type) {
  switch (type) {
    case 'PRIERE':
      return const Color(0x264A9EFF);
    case 'TRANSPORT':
      return const Color(0xFFDCECFF);
    case 'VISITE':
      return const Color(0x2E50CD89);
    case 'REPAS':
      return const Color(0x33FFAE66);
    case 'REPOS':
      return const Color(0x33ADB7C9);
    case 'RITE':
      return const Color(0xFFE9E1FF);
    default:
      return const Color(0x1F7D7D7D);
  }
}

Color _eventTypeStrongColor(String type) {
  switch (type) {
    case 'PRIERE':
      return const Color(0xFF2F7AD6);
    case 'TRANSPORT':
      return const Color(0xFF1764C3);
    case 'VISITE':
      return const Color(0xFF248A4B);
    case 'REPAS':
      return const Color(0xFFB86A1A);
    case 'REPOS':
      return const Color(0xFF667287);
    case 'RITE':
      return const Color(0xFF5D47D6);
    default:
      return AppColors.textMuted;
  }
}

Color _locationSoftColor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('masjid') ||
      normalized.contains('haram') ||
      normalized.contains('mecque') ||
      normalized.contains('kaaba')) {
    return AppColors.goldSoft;
  }
  if (normalized.contains('hotel')) {
    return AppColors.blueSoft;
  }
  if (normalized.contains('mina') ||
      normalized.contains('arafat') ||
      normalized.contains('muzdalifah') ||
      normalized.contains('miqat') ||
      normalized.contains('safa') ||
      normalized.contains('marwa')) {
    return AppColors.greenSoft;
  }
  return AppColors.section;
}

Color _locationStrongColor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('masjid') ||
      normalized.contains('haram') ||
      normalized.contains('mecque') ||
      normalized.contains('kaaba')) {
    return AppColors.gold;
  }
  if (normalized.contains('hotel')) {
    return AppColors.blue;
  }
  if (normalized.contains('mina') ||
      normalized.contains('arafat') ||
      normalized.contains('muzdalifah') ||
      normalized.contains('miqat') ||
      normalized.contains('safa') ||
      normalized.contains('marwa')) {
    return AppColors.green;
  }
  return AppColors.textMuted;
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
