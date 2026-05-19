// ignore_for_file: control_flow_in_finally

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_theme.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../presence/providers/presence_provider.dart';

class GuidePresenceGroupsSection extends ConsumerStatefulWidget {
  const GuidePresenceGroupsSection({
    super.key,
    required this.groups,
  });

  final List<MobilePlanningGroup> groups;

  @override
  ConsumerState<GuidePresenceGroupsSection> createState() =>
      _GuidePresenceGroupsSectionState();
}

class _GuidePresenceGroupsSectionState
    extends ConsumerState<GuidePresenceGroupsSection> {
  final Set<String> _pendingGroupIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups;
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'guide.presence.groups.section_title'.tr(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GroupPresenceTile(
              group: group,
              pending: _pendingGroupIds.contains(group.id),
              onTap: () => _openOrCreateCall(group),
            ),
          ),
      ],
    );
  }

  Future<void> _openOrCreateCall(MobilePlanningGroup group) async {
    if (_pendingGroupIds.contains(group.id)) return;

    setState(() => _pendingGroupIds.add(group.id));
    try {
      final snapshot = await ref.read(
        guideGroupPresenceSnapshotProvider(group.id).future,
      );

      String? appelId = snapshot.activeAppelId;
      if (appelId == null || appelId.trim().isEmpty) {
        if (group.status != 'EN_COURS') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Impossible de lancer un appel: le groupe doit etre EN_COURS.',
                ),
              ),
            );
          }
          return;
        }

        final repository = ref.read(presenceRepositoryProvider);
        final result = await repository.creerAppel(group.id);
        final rawAppel = result['appel'];
        if (rawAppel is Map<String, dynamic>) {
          appelId = rawAppel['id']?.toString();
        } else if (rawAppel is Map) {
          appelId = rawAppel['id']?.toString();
        }
      }

      if (!mounted) return;
      if (appelId == null || appelId.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('guide.presence.groups.open_error'.tr())),
        );
        return;
      }

      final route =
          '/guide-presence/$appelId?groupeNom=${Uri.encodeComponent(group.nom)}';
      await context.push(route);
      ref.invalidate(guideGroupPresenceSnapshotProvider(group.id));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) return;
      setState(() => _pendingGroupIds.remove(group.id));
    }
  }
}

class _GroupPresenceTile extends ConsumerWidget {
  const _GroupPresenceTile({
    required this.group,
    required this.pending,
    required this.onTap,
  });

  final MobilePlanningGroup group;
  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(guideGroupPresenceSnapshotProvider(group.id));

    final bool hasActiveCall = snapshotAsync.valueOrNull?.hasActiveCall ?? false;
    final bool canStartNewCall = group.status == 'EN_COURS';
    final bool canOpenOrLaunch = hasActiveCall || canStartNewCall;
    final bool isLoading = pending || snapshotAsync.isLoading;

    final subtitle = snapshotAsync.when(
      data: (snapshot) {
        if (!snapshot.hasActiveCall && !canStartNewCall) {
          return 'Le groupe doit etre EN_COURS pour lancer un appel.';
        }
        if (!snapshot.hasActiveCall) {
          return 'guide.presence.groups.no_active_call'.tr();
        }
        final totalLabel = snapshot.total ?? 0;
        final attenteLabel = snapshot.enAttente ?? 0;
        return 'guide.presence.groups.pending_summary'.tr(
          namedArgs: {
            'pending': '$attenteLabel',
            'total': '$totalLabel',
          },
        );
      },
      loading: () => 'guide.presence.groups.loading'.tr(),
      error: (_, __) => 'guide.presence.groups.unavailable'.tr(),
    );

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: (isLoading || !canOpenOrLaunch) ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
            color: AppColors.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: hasActiveCall
                        ? AppColors.greenSoft
                        : canOpenOrLaunch
                            ? AppColors.goldSoft
                            : AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    hasActiveCall
                        ? 'guide.presence.groups.action_open'.tr()
                        : canOpenOrLaunch
                            ? 'guide.presence.groups.action_launch'.tr()
                            : 'Indisponible',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: hasActiveCall
                          ? AppColors.green
                          : canOpenOrLaunch
                              ? AppColors.gold
                              : AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
