import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import 'guide_groupe_pelerins_sheet.dart';

class GuideGroupesSheet extends ConsumerStatefulWidget {
  const GuideGroupesSheet({super.key});

  @override
  ConsumerState<GuideGroupesSheet> createState() => _GuideGroupesSheetState();
}

class _GuideGroupesSheetState extends ConsumerState<GuideGroupesSheet> {
  final _searchController = TextEditingController();

  _GroupFilter _filter = _GroupFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGroupe(MobilePlanningGroup group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GuideGroupePelerinsSheet(
        groupeId: group.id,
        groupeNom: group.nom,
      ),
    );
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(mobilePlanningGroupsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height;
    final query = _searchController.text.trim().toLowerCase();
    final stateChild = groupsAsync.when(
      loading: () => const _LoadingView(key: ValueKey('loading')),
      error: (error, _) => Padding(
        key: const ValueKey('error'),
        padding: const EdgeInsets.all(16),
        child: _ErrorView(
          message: error.toString(),
          onRetry: () async => ref.invalidate(mobilePlanningGroupsProvider),
        ),
      ),
      data: (groups) {
        final baseGroups = switch (_filter) {
          _GroupFilter.all => groups,
          _GroupFilter.enCours =>
            groups.where((g) => g.status == 'EN_COURS').toList(),
          _GroupFilter.planifie =>
            groups.where((g) => g.status == 'PLANIFIE').toList(),
          _GroupFilter.termine =>
            groups.where((g) => g.status == 'TERMINE').toList(),
        };

        final visibleGroups = query.isEmpty
            ? baseGroups
            : baseGroups.where((g) => g.nom.toLowerCase().contains(query)).toList();

        return RefreshIndicator(
          key: ValueKey('list_${_filter.name}_${query}_${visibleGroups.length}'),
          onRefresh: () async => ref.refresh(mobilePlanningGroupsProvider.future),
          color: AppColors.gold,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
            children: [
              const SizedBox(height: 10),
              const Center(child: _Handle()),
              const SizedBox(height: 12),
              _Header(
                searchController: _searchController,
                visibleCount: visibleGroups.length,
                filter: _filter,
                onSearchChanged: (_) => setState(() {}),
                onFilterChanged: (next) => setState(() => _filter = next),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: visibleGroups.isEmpty
                    ? Padding(
                        key: ValueKey('empty_$query'),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _EmptyState(isSearch: query.isNotEmpty),
                      )
                    : Column(
                        key: ValueKey('groups_${visibleGroups.length}_$query'),
                        children: [
                          for (int index = 0; index < visibleGroups.length; index++)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: _AppearIn(
                                index: index,
                                child: _GroupCard(
                                  group: visibleGroups[index],
                                  onOpen: () => _openGroupe(visibleGroups[index]),
                                  formatDate: _formatDate,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomInset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.borderSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: height * 0.91,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: stateChild,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _GroupFilter {
  all,
  enCours,
  planifie,
  termine,
}

class _Header extends StatelessWidget {
  const _Header({
    required this.searchController,
    required this.visibleCount,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final int visibleCount;
  final _GroupFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_GroupFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSoft),
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Groupes',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$visibleCount groupe(s) disponibles',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: AppColors.section,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Consultez vos groupes et accedez rapidement a la liste des pelerins.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _SearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 8),
            _FilterRow(
              value: filter,
              onChanged: onFilterChanged,
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Container(
                key: ValueKey('count_$visibleCount'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.section,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Text(
                  '$visibleCount resultat(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearIn extends StatelessWidget {
  const _AppearIn({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, 8).toInt();
    final duration = Duration(milliseconds: 210 + (safeIndex * 30));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, animatedChild) {
        final offsetY = (1 - value) * 14;
        final scale = 0.97 + (0.03 * value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: animatedChild,
            ),
          ),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onOpen,
    required this.formatDate,
  });

  final MobilePlanningGroup group;
  final VoidCallback onOpen;
  final String Function(DateTime) formatDate;

  Color get _accentColor {
    if (group.status == 'EN_COURS') return AppColors.blue;
    if (group.status == 'PLANIFIE') return AppColors.gold;
    if (group.status == 'TERMINE') return AppColors.green;
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.black,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSoft),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFFEFC)],
          ),
        ),
        child: InkWell(
          onTap: onOpen,
          splashColor: _accentColor.withValues(alpha: 0.08),
          highlightColor: _accentColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(typeVoyage: group.typeVoyage),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.nom,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            group.dateDepart == null
                                ? group.typeVoyage
                                : 'Depart ${formatDate(group.dateDepart!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ActionBadge(accent: _accentColor),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GroupStatusChip.fromStatus(status: group.status ?? ''),
                    _InfoPill(
                      icon: Icons.group_rounded,
                      label: '${group.nbPelerins ?? 0} pelerins',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.typeVoyage});
  final String typeVoyage;

  @override
  Widget build(BuildContext context) {
    final isHajj = typeVoyage == 'HAJJ';
    final foreground = isHajj ? const Color(0xFF0C447C) : const Color(0xFF6E4409);
    final background = isHajj ? const Color(0xFFEAF3FD) : const Color(0xFFFCF1DC);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white),
      ),
      alignment: Alignment.center,
      child: Text(
        isHajj ? 'H' : 'U',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.1,
          color: foreground,
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: accent,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: AppColors.textFaint,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.8,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.section,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.groups_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isSearch ? 'Aucun resultat' : 'Aucun groupe',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSearch
                ? 'Essayez un autre mot-cle.'
                : "Aucun groupe actif n'est disponible pour le moment.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.8,
              height: 1.45,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 24,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async => onRetry(),
              child: const Text('Recharger'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Rechercher un groupe',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: AppColors.section,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: controller.text.trim().isEmpty
              ? const SizedBox.shrink(key: ValueKey('clear_empty'))
              : IconButton(
                  key: const ValueKey('clear_button'),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.value,
    required this.onChanged,
  });

  final _GroupFilter value;
  final ValueChanged<_GroupFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Tous',
            selected: value == _GroupFilter.all,
            onTap: () => onChanged(_GroupFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'En cours',
            selected: value == _GroupFilter.enCours,
            onTap: () => onChanged(_GroupFilter.enCours),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Planifies',
            selected: value == _GroupFilter.planifie,
            onTap: () => onChanged(_GroupFilter.planifie),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Termines',
            selected: value == _GroupFilter.termine,
            onTap: () => onChanged(_GroupFilter.termine),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 160),
      scale: selected ? 1 : 0.98,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.text : AppColors.section,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? AppColors.text : AppColors.borderSoft,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupStatusChip extends StatelessWidget {
  const _GroupStatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _GroupStatusChip.fromStatus({
    required String status,
  }) {
    if (status == 'TERMINE') {
      return const _GroupStatusChip(
        label: 'TERMINE',
        color: AppColors.green,
        icon: Icons.check_circle_rounded,
      );
    }
    if (status == 'EN_COURS') {
      return const _GroupStatusChip(
        label: 'EN COURS',
        color: AppColors.blue,
        icon: Icons.autorenew_rounded,
      );
    }
    if (status == 'PLANIFIE') {
      return const _GroupStatusChip(
        label: 'PLANIFIE',
        color: AppColors.textMuted,
        icon: Icons.schedule_rounded,
      );
    }
    return const _GroupStatusChip(
      label: 'INFO',
      color: AppColors.textMuted,
      icon: Icons.info_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.25,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      children: [
        const SizedBox(height: 10),
        const Center(child: _Handle()),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _HeaderSkeleton(),
        ),
        const SizedBox(height: 14),
        for (int index = 0; index < 3; index++)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _GroupCardSkeleton(),
          ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBox(width: 130, height: 24, radius: 10),
        SizedBox(height: 8),
        _SkeletonBox(width: 210, height: 12, radius: 8),
        SizedBox(height: 14),
        _SkeletonBox(width: double.infinity, height: 48, radius: 16),
        SizedBox(height: 10),
        _SkeletonBox(width: double.infinity, height: 34, radius: 999),
      ],
    );
  }
}

class _GroupCardSkeleton extends StatelessWidget {
  const _GroupCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBox(width: 38, height: 38, radius: 11),
              SizedBox(width: 10),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 15)),
              SizedBox(width: 8),
              _SkeletonBox(width: 30, height: 30, radius: 999),
            ],
          ),
          SizedBox(height: 8),
          _SkeletonBox(width: 140, height: 12, radius: 8),
          SizedBox(height: 12),
          Row(
            children: [
              _SkeletonBox(width: 92, height: 26, radius: 999),
              SizedBox(width: 8),
              _SkeletonBox(width: 106, height: 26, radius: 999),
            ],
          ),
          SizedBox(height: 10),
          _SkeletonBox(width: 95, height: 11, radius: 8),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.borderSoft),
      ),
    );
  }
}
