import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/saudi_time.dart';
import '../../../core/utils/trip_progress.dart';
import '../../../core/widgets/adhan_panel.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/mobile_notifications_provider.dart';
import '../../notifications/screens/mobile_alerts_screen.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import '../../planning/screens/role_planning_pages.dart';
import '../../sos/presentation/sos_screen.dart';
import '../../sos/providers/sos_provider.dart';

class PelerinHomeScreen extends ConsumerWidget {
  const PelerinHomeScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final fullName = user.fullName.trim();
    final firstName = user.prenom.trim().isNotEmpty
        ? user.prenom.trim()
        : (fullName.isNotEmpty ? fullName.split(' ').first : user.email);
    final planningGroupsAsync = ref.watch(mobilePlanningGroupsProvider);

    return RoleShell(
      initialIndex: initialTabIndex,
      accountActions: [
        RoleShellAccountAction(
          label: 'Historique groupes',
          icon: Icons.history_rounded,
          toneColor: const Color(0xFFD4AF37),
          onTap: (context) async => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const _PelerinGroupHistorySheetHome(),
          ),
        ),
        RoleShellAccountAction(
          label: 'Deconnexion',
          icon: Icons.logout_rounded,
          toneColor: AppColors.red,
          onTap: (context) async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
      homeChild: _PelerinHomeContent(
        firstName: firstName,
        groupeNom: user.groupeNom,
        groupsAsync: planningGroupsAsync,
      ),
      planningChild: const PelerinPlanningPage(),
      alertsChild: const MobileAlertsScreen(),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'Pelerin',
        accentColor: const Color(0xFFD4AF37),
        onEdit: () => context.push('/profile-edit'),
      ),
    );
  }
}

class _PelerinHomeContent extends ConsumerWidget {
  const _PelerinHomeContent({
    required this.firstName,
    required this.groupeNom,
    required this.groupsAsync,
  });

  final String firstName;
  final String? groupeNom;
  final AsyncValue<List<MobilePlanningGroup>> groupsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = groupsAsync.valueOrNull?.isNotEmpty == true
        ? pickBestPlanningGroup(groupsAsync.valueOrNull!)
        : null;

    final planningAsync = selectedGroup == null
        ? const AsyncValue<MobilePlanningData?>.data(null)
        : ref.watch(mobilePlanningDetailProvider(selectedGroup.id));

    Future<void> refreshHome() async {
      ref.invalidate(mobilePlanningGroupsProvider);
      ref.invalidate(mobileNotificationsProvider);
      ref.invalidate(sosControllerProvider);
      if (selectedGroup != null) {
        ref.invalidate(mobilePlanningDetailProvider(selectedGroup.id));
      }

      await ref.read(mobilePlanningGroupsProvider.future);
      if (selectedGroup != null) {
        await ref.read(mobilePlanningDetailProvider(selectedGroup.id).future);
      }
      await ref.read(mobileNotificationsProvider.future);
      await ref.read(sosControllerProvider.future);
    }

    return Stack(
      children: [
        const _SoftScreenBackdrop(),
        RefreshIndicator(
          color: const Color(0xFFD4AF37),
          onRefresh: refreshHome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
            children: [
              _Header(firstName: firstName, groupeNom: groupeNom),
              const SizedBox(height: 12),
              _HeroCard(
                group: selectedGroup,
                planningAsync: planningAsync,
              ),
              const SizedBox(height: 12),
              const AdhanPanel(
                accentColor: Color(0xFFD4AF37),
                roleToneLabel: '',
                compact: true,
              ),
              const SizedBox(height: 12),
              const _SosSection(),
            ],
          ),
        ),
      ],
    );
  }
}

class _PelerinGroupHistorySheetHome extends ConsumerWidget {
  const _PelerinGroupHistorySheetHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(mobilePlanningGroupHistoryProvider);
    final height = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: height * 0.82,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Historique de vos groupes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: historyAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Aucun historique de groupe disponible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _HistoryGroupTileHome(item: item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryGroupTileHome extends StatelessWidget {
  const _HistoryGroupTileHome({
    required this.item,
  });

  final MobilePlanningGroupHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(item.groupe.status);
    final statusColor = _statusColor(item.groupe.status);
    final departureDate = item.groupe.dateDepart;
    final returnDate = item.groupe.dateRetour;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              item.groupe.typeVoyage == 'HAJJ'
                  ? Icons.mosque_rounded
                  : Icons.location_on_outlined,
              size: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.groupe.nom,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.groupe.typeVoyage == 'HAJJ' ? 'Hajj' : 'Omra'} - ${item.groupe.annee}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (departureDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    returnDate == null
                        ? 'Depart: ${_formatDate(departureDate)}'
                        : 'Depart-Retour: ${_formatDate(departureDate)} - ${_formatDate(returnDate)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11.5,
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final astDate = _toAst(value);
    final day = astDate.day.toString().padLeft(2, '0');
    final month = astDate.month.toString().padLeft(2, '0');
    return '$day/$month/${astDate.year}';
  }

  DateTime _toAst(DateTime value) {
  return value;
}

  String _statusLabel(String? status) {
    switch (status) {
      case 'PLANIFIE':
        return 'Planifie';
      case 'EN_COURS':
        return 'En cours';
      case 'TERMINE':
        return 'Termine';
      case 'ANNULE':
        return 'Annule';
      default:
        return 'Inconnu';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'PLANIFIE':
        return AppColors.gold;
      case 'EN_COURS':
        return AppColors.green;
      case 'TERMINE':
        return AppColors.blue;
      case 'ANNULE':
        return const Color(0xFFE58E73);
      default:
        return AppColors.textMuted;
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.firstName,
    required this.groupeNom,
  });

  final String firstName;
  final String? groupeNom;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.group,
    required this.planningAsync,
  });

  final MobilePlanningGroup? group;
  final AsyncValue<MobilePlanningData?> planningAsync;

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

    final percent = computeTripProgress(
      group?.dateDepart,
      group?.dateRetour,
      DateTime.now(),
    );

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
            right: 0,
            top: 18,
            child: Opacity(
              opacity: 0.92,
              child: AppHeroAsset(
                assetPath: 'assets/images/kaaba.png',
                width: 154,
                height: 148,
                scale: 1.0,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 118),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentEvent?.titre ?? 'Aucune etape aujourd hui',
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
                      _heroMeta(currentEvent, group) ?? 'Programme du jour',
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
              const SizedBox(height: 22),
              _ProgressBlock(progress: percent),
              const SizedBox(height: 14),
              _HeroNextStepPanel(
                event: nextEvent,
                fallbackLocation: group?.nom ?? '',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.progress});

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
          '${(progress * 100).round()}% du voyage',
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

class _SosSection extends ConsumerWidget {
  const _SosSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosControllerProvider);
    final activeAlert = sosState.valueOrNull;
    final isLoading = sosState.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urgence SOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Utilisez ce bouton uniquement en cas d urgence reelle.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          activeAlert?.isActive == true
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'Alerte active depuis ${_formatHour(activeAlert!.createdAt)}',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red,
                    ),
                  ),
                )
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _SosQuickActionButton(
                    loading: isLoading,
                    onPressed: () async {
                      final type = await showSosTypePickerSheet(context);
                      if (type == null || !context.mounted) return;

                      final confirmed = await showSosSendConfirmSheet(
                        context,
                        type: type,
                      );
                      if (confirmed != true || !context.mounted) return;

                      try {
                        final alert = await ref
                            .read(sosControllerProvider.notifier)
                            .triggerSos(type: type);
                        if (!context.mounted) return;
                        await showSosConfirmationSheet(context, alert: alert);
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

class _SosQuickActionButton extends StatelessWidget {
  const _SosQuickActionButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: loading ? 0.7 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            children: [
              const Text(
                'Choisir le type d aide',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selectionnez votre situation puis confirmez l envoi de l alerte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: Color(0xFFFDECEC),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Envoi en cours...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Continuer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroNextStepPanel extends StatelessWidget {
  const _HeroNextStepPanel({
    required this.event,
    required this.fallbackLocation,
  });

  final MobilePlanningEvent? event;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final title = event != null && event!.titre.trim().isNotEmpty
        ? event!.titre.trim()
        : 'Programme partage a venir';
    final meta = _heroPanelMeta(event) ?? fallbackLocation;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.north_east_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prochaine etape',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
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
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: Colors.white,
          ),
        ],
      ),
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
String? _primaryLocation(List<MobilePlanningEvent> events) {
  for (final event in events) {
    for (final lieu in event.lieux) {
      final value = lieu.trim();
      if (value.isNotEmpty) return value;
    }
  }
  return null;
}

String? _heroMeta(MobilePlanningEvent? event, MobilePlanningGroup? group) {
  return _primaryLocation(event == null ? const [] : [event]) ?? group?.nom;
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

String _formatHour(DateTime value) {
  return SaudiTime.formatHour(value);
}


