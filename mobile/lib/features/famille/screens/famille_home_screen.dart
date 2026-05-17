import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/saudi_time.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../core/widgets/role_profile_template.dart';
import '../../../core/widgets/role_shell.dart';
import '../../auth/domain/auth_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/auth_feedback.dart';
import '../../chat/screens/mobile_chat_screen.dart';
import '../../notifications/domain/mobile_notification.dart';
import '../../notifications/providers/mobile_notifications_provider.dart';
import '../../notifications/screens/mobile_alerts_screen.dart';
import '../../planning/domain/mobile_planning_models.dart';
import '../../planning/providers/mobile_planning_provider.dart';
import '../../planning/screens/role_planning_pages.dart';
import '../domain/family_link.dart';
import '../providers/family_links_provider.dart';
import '../providers/hidden_links_provider.dart';

// ─────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────

class FamilleHomeScreen extends ConsumerStatefulWidget {
  const FamilleHomeScreen({super.key, this.initialTabIndex = 0});
  final int initialTabIndex;

  @override
  ConsumerState<FamilleHomeScreen> createState() => _FamilleHomeScreenState();
}

class _FamilleHomeScreenState extends ConsumerState<FamilleHomeScreen> {
  late int _shellIndex;
  String? _selectedFamilyGroupId;
  String? _activeUserId;

  @override
  void initState() {
    super.initState();
    _shellIndex = widget.initialTabIndex;
    _activeUserId = ref.read(authProvider).valueOrNull?.user.id;
  }

  @override
  void didUpdateWidget(covariant FamilleHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _shellIndex = widget.initialTabIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final familyLinksAsync = ref.watch(familyLinksProvider);

    if (user == null) return const SizedBox.shrink();

    if (_activeUserId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _activeUserId = user.id;
          _selectedFamilyGroupId = null;
          _shellIndex = widget.initialTabIndex;
        });
      });
    }

    return RoleShell(
      key: ValueKey('famille-shell-${user.id}'),
      initialIndex: _shellIndex,
      onIndexChanged: (index) {
        if (_shellIndex == index || !mounted) return;
        setState(() => _shellIndex = index);
      },
      accountActions: [
        RoleShellAccountAction(
          label: 'Mes proches',
          icon: Icons.history_rounded,
          toneColor: const Color(0xFFE58E73),
          onTap: (_) async => _openRelativesSheet(
            context,
            familyLinksAsync,
          ),
        ),
        RoleShellAccountAction(
          label: 'Deconnexion',
          icon: Icons.logout_rounded,
          toneColor: AppColors.red,
          onTap: (context) async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
      homeChild: _FamilleHomeContent(
        firstName: user.prenom.trim().isNotEmpty ? user.prenom.trim() : user.email,
        linksAsync: familyLinksAsync,
        selectedGroupId: _selectedFamilyGroupId,
        onOpenRelatives: () => _openRelativesSheet(
          context,
          familyLinksAsync,
        ),
        onOpenAlerts: _openAlertsTab,
        onSelectLink: (link) => _handleLinkSelection(context, link),
        onArchiveLink: (link) => _handleLinkArchive(link, familyLinksAsync.valueOrNull ?? const []),
      ),
      planningChild: FamillePlanningPage(preferredGroupId: _selectedFamilyGroupId),
      alertsChild: const MobileAlertsScreen(),
      chatbotChild: const MobileChatScreen(),
      profileChild: RoleProfileTemplate(
        user: user,
        roleLabel: 'Famille',
        accentColor: const Color(0xFFE58E73),
        onEdit: () => context.push('/profile-edit'),
      ),
    );
  }

  void _openAlertsTab() {
    if (!mounted) return;
    setState(() => _shellIndex = 2);
  }

  void _handleLinkSelection(BuildContext context, FamilyLink link) {
    final groupId = link.groupe?.id;
    if (groupId == null || groupId.isEmpty) {
      showAuthSnackBar(context, 'Ce proche n a pas encore de groupe actif a afficher.');
      return;
    }
    setState(() {
      _selectedFamilyGroupId = groupId;
      _shellIndex = 1;
    });
  }

  Future<void> _handleLinkArchive(
    FamilyLink link,
    List<FamilyLink> allLinks,
  ) async {
    await ref.read(hiddenLinkIdsProvider.notifier).hide(link.id);
    if (!mounted) return;

    final archivedGroupId = link.groupe?.id;
    if (archivedGroupId == null || archivedGroupId != _selectedFamilyGroupId) {
      return;
    }

    final hiddenIds = ref.read(hiddenLinkIdsProvider).valueOrNull ?? const <String>{};
    final nextVisibleLinks = allLinks
        .where((item) => item.id != link.id && !hiddenIds.contains(item.id))
        .toList(growable: false);
    final fallbackLink = _resolveSelectedLink(nextVisibleLinks, null);

    setState(() {
      _selectedFamilyGroupId = fallbackLink?.groupe?.id;
      if (_shellIndex == 1 && _selectedFamilyGroupId == null) {
        _shellIndex = 0;
      }
    });
  }

  Future<void> _openAddRelativeDialog(BuildContext screenContext) async {
    await showModalBottomSheet<String>(
      context: screenContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFamilyRelativeSheet(
        accentColor: const Color(0xFFE58E73),
        onSubmit: (code) async {
          final msg = await ref.read(authProvider.notifier).addFamilyLink(codeUnique: code);
          ref.invalidate(familyLinksProvider);
          return msg;
        },
      ),
    ).then((message) {
      if (message != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showAuthSnackBar(screenContext, message);
        });
      }
    });
  }

  Future<void> _openRelativesSheet(
    BuildContext context,
    AsyncValue<List<FamilyLink>> familyLinksAsync,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16, 12, 16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: AppColors.borderSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.82,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Mes proches',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _FamilyLinksSection(
                    linksAsync: familyLinksAsync,
                    selectedGroupId: _selectedFamilyGroupId,
                    onArchiveLink: (link) => _handleLinkArchive(
                      link,
                      familyLinksAsync.valueOrNull ?? const [],
                    ),
                    compact: true,
                    onAddRelative: () {
                      Navigator.of(sheetContext).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!context.mounted) return;
                        _openAddRelativeDialog(context);
                      });
                    },
                    onSelectLink: (link) {
                      Navigator.of(sheetContext).pop();
                      _handleLinkSelection(context, link);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Home content
// ─────────────────────────────────────────────────────────────

class _FamilleHomeContent extends ConsumerWidget {
  const _FamilleHomeContent({
    required this.firstName,
    required this.linksAsync,
    required this.selectedGroupId,
    required this.onOpenRelatives,
    required this.onOpenAlerts,
    required this.onSelectLink,
    required this.onArchiveLink,
  });

  final String firstName;
  final AsyncValue<List<FamilyLink>> linksAsync;
  final String? selectedGroupId;
  final VoidCallback onOpenRelatives;
  final VoidCallback onOpenAlerts;
  final ValueChanged<FamilyLink> onSelectLink;
  final ValueChanged<FamilyLink> onArchiveLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = linksAsync.valueOrNull ?? const <FamilyLink>[];
    final hiddenIds = ref.watch(hiddenLinkIdsProvider).valueOrNull ?? {};
    final visibleLinks = links.where((l) => !hiddenIds.contains(l.id)).toList();
    final selectedLink = _resolveSelectedLink(visibleLinks, selectedGroupId);
    final notificationsAsync = ref.watch(mobileNotificationsProvider);

    Future<void> refreshHome() async {
      ref.invalidate(familyLinksProvider);
      ref.invalidate(mobileNotificationsProvider);
      for (final link in visibleLinks) {
        final id = link.groupe?.id;
        if (id != null && id.isNotEmpty) ref.invalidate(mobilePlanningDetailProvider(id));
      }
      await ref.read(familyLinksProvider.future);
      await ref.read(mobileNotificationsProvider.future);
      for (final link in visibleLinks) {
        final id = link.groupe?.id;
        if (id != null && id.isNotEmpty) {
          await ref.read(mobilePlanningDetailProvider(id).future);
        }
      }
    }

    return Stack(
      children: [
        const _FamilyHomeBackdrop(),
        RefreshIndicator(
          color: const Color(0xFFE58E73),
          onRefresh: refreshHome,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            children: [
              _FamilyHeader(firstName: firstName),
              const SizedBox(height: 18),
              _FamilyTodaySection(
                links: visibleLinks,
                selectedGroupId: selectedGroupId,
                onOpenRelatives: onOpenRelatives,
                onSelectLink: onSelectLink,
                onArchiveLink: onArchiveLink,
              ),
              const SizedBox(height: 18),
              _FamilyAlertsPreview(
                notificationsAsync: notificationsAsync,
                selectedGroupId: selectedLink?.groupe?.id,
                onOpenAlerts: onOpenAlerts,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────

class _FamilyHeader extends StatelessWidget {
  const _FamilyHeader({required this.firstName});
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bonjour',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(
          firstName,
          style: const TextStyle(
            fontSize: 31, fontWeight: FontWeight.w800,
            height: 0.98, letterSpacing: -0.8, color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Today section — shows first visible link
// ─────────────────────────────────────────────────────────────

class _FamilyTodaySection extends StatelessWidget {
  const _FamilyTodaySection({
    required this.links,
    required this.selectedGroupId,
    required this.onOpenRelatives,
    required this.onSelectLink,
    required this.onArchiveLink,
  });

  final List<FamilyLink> links;
  final String? selectedGroupId;
  final VoidCallback onOpenRelatives;
  final ValueChanged<FamilyLink> onSelectLink;
  final ValueChanged<FamilyLink> onArchiveLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Aujourd hui',
                  style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800,
                    letterSpacing: -0.5, color: AppColors.primaryDark,
                  )),
            ),
            TextButton(
              onPressed: onOpenRelatives,
              child: const Text('Voir tout',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (links.isEmpty)
          const _FamilyEmptyTodayCard()
        else
          _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    final ordered = _sortFamilyLinksForToday(links, selectedGroupId);
    final featured = ordered.first;
    final remainingCount = ordered.length - 1;

    return Column(
      children: [
        _FamilyTodayCard(
          link: featured,
          selected: featured.groupe?.id == selectedGroupId,
          onTap: () => onSelectLink(featured),
          onArchive: () => onArchiveLink(featured),
        ),
        if (remainingCount > 0) ...[
          const SizedBox(height: 10),
          Text(
            '$remainingCount autre${remainingCount > 1 ? 's' : ''} proche${remainingCount > 1 ? 's' : ''} dans Voir tout',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Today card — current/next event for a pilgrim
// ─────────────────────────────────────────────────────────────

class _FamilyTodayCard extends ConsumerWidget {
  const _FamilyTodayCard({
    required this.link,
    required this.selected,
    required this.onTap,
    this.onArchive,
  });

  final FamilyLink link;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupeId = link.groupe?.id;
    final planningAsync = (groupeId == null || groupeId.isEmpty)
        ? const AsyncValue<MobilePlanningData?>.data(null)
        : ref.watch(mobilePlanningDetailProvider(groupeId));

    final planning = planningAsync.valueOrNull;
    final day = findPlanningDayForDate(
      planning?.plannings ?? const [],
      SaudiTime.now(),
      preferWithEvents: true,
    );
    final currentEvent = pickCurrentOrNextPlanningEvent(day?.evenements ?? const []);
    final tone = _familyTodayTone(selected);

    return GestureDetector(
      onLongPress: onArchive,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? tone.borderColor : tone.borderColor.withValues(alpha: 0.74),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 22, offset: Offset(0, 10))],
          ),
            child: Row(
              children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: tone.softColor, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(_familyTodayIcon(currentEvent), size: 28, color: tone.accentColor),
              ),
                const SizedBox(width: 12),
                // Timeline dot
                SizedBox(
                width: 18,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 1.2, height: 82, color: tone.borderColor),
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: tone.borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(color: tone.accentColor, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
                const SizedBox(width: 12),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.fullName.isNotEmpty ? link.fullName : link.codeUnique,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _familyTodayTitle(currentEvent, day),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _familyTodayMetaSummary(currentEvent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                    if (currentEvent?.etape?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(color: tone.softColor, borderRadius: BorderRadius.circular(999)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Text(
                            _familyTodayEtapeText(currentEvent!.etape!),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tone.accentColor),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: tone.softColor, borderRadius: BorderRadius.circular(999)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Voir les details',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: tone.accentColor)),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded, size: 18, color: tone.accentColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ),
                if (onArchive != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: AppColors.textFaint,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Alerts preview
// ─────────────────────────────────────────────────────────────

class _FamilyAlertsPreview extends StatelessWidget {
  const _FamilyAlertsPreview({
    required this.notificationsAsync,
    required this.selectedGroupId,
    required this.onOpenAlerts,
  });

  final AsyncValue<MobileNotificationFeed> notificationsAsync;
  final String? selectedGroupId;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Alertes importantes',
                  style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w800,
                    letterSpacing: -0.5, color: AppColors.primaryDark,
                  )),
            ),
            TextButton(
              onPressed: onOpenAlerts,
              child: const Text('Voir tout',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        notificationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => AppCard(
            padding: const EdgeInsets.all(18),
            radius: 24,
            child: Text(error.toString(),
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
          data: (feed) {
            final relevant = feed.items
                .where((item) =>
                    selectedGroupId == null ||
                    item.groupeId == null ||
                    item.groupeId == selectedGroupId)
                .toList(growable: false);

            final featured = relevant.firstWhere(
              (item) => !item.isRead,
              orElse: () => relevant.isNotEmpty ? relevant.first : throw StateError(''),
            );

            return _FamilyFeaturedAlertCard(
              item: relevant.isEmpty ? null : featured,
              onTap: onOpenAlerts,
            );
          },
        ),
      ],
    );
  }
}

class _FamilyFeaturedAlertCard extends StatelessWidget {
  const _FamilyFeaturedAlertCard({required this.item, required this.onTap});
  final MobileNotificationItem? item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item?.title ?? 'Aucune alerte critique';
    final body = item?.body ?? 'Tout est sous controle. Continuez a suivre leurs etapes.';
    final footer = item == null ? null : _formatFamilyNotificationTime(item!.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7E7), Color(0xFFFFF1CB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF3DEAA)),
            boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Row(
            children: [
              const AppIconBadge(
                icon: Icons.notifications_none_rounded,
                size: 50,
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFF2A21F),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFFAD6A08))),
                    const SizedBox(height: 4),
                    Text(body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF8A6D3B))),
                    if (footer != null) ...[
                      const SizedBox(height: 8),
                      Text(footer,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB88D3C))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AppMosqueIllustration(width: 78, height: 64, soft: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

class _FamilyEmptyTodayCard extends StatelessWidget {
  const _FamilyEmptyTodayCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Aucun proche lie pour le moment.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          SizedBox(height: 6),
          Text('Ajoutez un pelerin avec son code unique pour suivre ses etapes ici.',
              style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Links section (inside "Mes proches" sheet)
// ─────────────────────────────────────────────────────────────

class _FamilyLinksSection extends ConsumerWidget {
  const _FamilyLinksSection({
    required this.linksAsync,
    required this.onAddRelative,
    required this.onSelectLink,
    required this.selectedGroupId,
    this.onArchiveLink,
    this.compact = false,
  });

  final AsyncValue<List<FamilyLink>> linksAsync;
  final VoidCallback onAddRelative;
  final ValueChanged<FamilyLink> onSelectLink;
  final String? selectedGroupId;
  final ValueChanged<FamilyLink>? onArchiveLink;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenIds = ref.watch(hiddenLinkIdsProvider).valueOrNull ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          const Text('Mes proches',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
          const SizedBox(height: 8),
          const Text(
            'Ajoutez un pelerin avec son code unique ou touchez une carte pour voir sa journee en direct.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
        ],
        OutlinedButton.icon(
          onPressed: onAddRelative,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE58E73),
            side: const BorderSide(color: Color(0xFFF0CEC5)),
            backgroundColor: const Color(0xFFFFF8F6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Ajouter un proche'),
        ),
        const SizedBox(height: 14),
        linksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => _errorBox(error.toString()),
          data: (links) {
            if (links.isEmpty) return _errorBox('Aucun proche lie pour le moment.');

            final visibleLinks = links.where((l) => !hiddenIds.contains(l.id)).toList();
            final hiddenLinks = links.where((l) => hiddenIds.contains(l.id)).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visible
                ...visibleLinks.map((link) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FamilyLinkCard(
                    link: link,
                    selected: link.groupe?.id == selectedGroupId,
                    onTap: () => onSelectLink(link),
                    onArchive: () async {
                      if (onArchiveLink != null) {
                        onArchiveLink!(link);
                        return;
                      }
                      await ref.read(hiddenLinkIdsProvider.notifier).hide(link.id);
                    },
                  ),
                )),

                // Hidden
                if (hiddenLinks.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Proches masques',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  ...hiddenLinks.map((link) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _HiddenLinkRow(
                      link: link,
                      onRestore: () =>
                          ref.read(hiddenLinkIdsProvider.notifier).restore(link.id),
                    ),
                  )),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(message, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Link card (visible) — long press to hide
// ─────────────────────────────────────────────────────────────

class _FamilyLinkCard extends StatelessWidget {
  const _FamilyLinkCard({
    required this.link,
    required this.selected,
    required this.onTap,
    this.onArchive,
  });

  final FamilyLink link;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final groupLabel = _familyTripDateLabel(link.groupe);

    return GestureDetector(
      onLongPress: onArchive == null ? null : () => _confirmArchive(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? const Color(0xFFE58E73) : AppColors.borderSoft,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE58E73).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person_outline_rounded, color: Color(0xFFE58E73)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.fullName.isNotEmpty ? link.fullName : link.codeUnique,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text('Code ${link.codeUnique}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textFaint, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(groupLabel,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: selected ? const Color(0xFFE58E73) : AppColors.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const Text('Masquer ce proche',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Masquer ${link.fullName} de votre accueil ? Vous pourrez le retrouver dans "Mes proches".',
                style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Masquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) onArchive!();
  }
}

// ─────────────────────────────────────────────────────────────
// Hidden link row (restore button)
// ─────────────────────────────────────────────────────────────

class _HiddenLinkRow extends StatelessWidget {
  const _HiddenLinkRow({required this.link, required this.onRestore});
  final FamilyLink link;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.section,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              link.fullName.isNotEmpty ? link.fullName : link.codeUnique,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
          TextButton(onPressed: onRestore, child: const Text('Restaurer')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Add relative sheet
// ─────────────────────────────────────────────────────────────

class _AddFamilyRelativeSheet extends StatefulWidget {
  const _AddFamilyRelativeSheet({required this.accentColor, required this.onSubmit});
  final Color accentColor;
  final Future<String> Function(String codeUnique) onSubmit;

  @override
  State<_AddFamilyRelativeSheet> createState() => _AddFamilyRelativeSheetState();
}

class _AddFamilyRelativeSheetState extends State<_AddFamilyRelativeSheet> {
  late final TextEditingController _codeController;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _submitting = true; _errorText = null; });
    try {
      final message = await widget.onSubmit(_codeController.text);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(message);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() { _submitting = false; _errorText = error.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _submitting = false; _errorText = 'Une erreur est survenue'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Material(
          color: const Color(0xFFFFF7F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xFFF1CDC3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.person_add_alt_1_rounded, color: widget.accentColor),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Ajouter un proche',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                    ),
                    IconButton(
                      onPressed: _submitting ? null : () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Entrez le code unique du pelerin pour lier un nouveau proche a votre compte famille.',
                  style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) { if (_errorText != null) setState(() => _errorText = null); },
                  onSubmitted: (_) { if (!_submitting) _submit(); },
                  decoration: InputDecoration(
                    labelText: 'Code unique',
                    hintText: 'XXXXXXXX',
                    prefixIcon: Icon(Icons.qr_code_rounded, color: widget.accentColor),
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: widget.accentColor),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFF0CEC5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: widget.accentColor, width: 1.4),
                    ),
                    errorText: _errorText,
                  ),
                ),
                if (_errorText == null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Le code doit correspondre au code unique partage par votre proche.',
                    style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFFB67C6A)),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Annuler',
                          style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Ajouter'),
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

class _FamilyHomeBackdrop extends StatelessWidget {
  const _FamilyHomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFF8F7F3)),
        Positioned(
          top: -90,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFE58E73).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 180,
          left: -70,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _FamilyTodayTone {
  const _FamilyTodayTone({
    required this.accentColor,
    required this.softColor,
    required this.borderColor,
  });
  final Color accentColor;
  final Color softColor;
  final Color borderColor;
}

_FamilyTodayTone _familyTodayTone(bool selected) => _FamilyTodayTone(
  accentColor: const Color(0xFFE58E73),
  softColor: const Color(0xFFFFF3EE),
  borderColor: selected ? const Color(0xFFF0C6B7) : const Color(0xFFF6DDD3),
);

IconData _familyTodayIcon(MobilePlanningEvent? event) {
  switch (event?.type) {
    case 'TRANSPORT': return Icons.directions_bus_rounded;
    case 'PRIERE':    return Icons.mosque_rounded;
    case 'VISITE':    return Icons.location_on_outlined;
    default:          return Icons.route_rounded;
  }
}

String _familyTodayTitle(MobilePlanningEvent? event, MobilePlanningDay? day) =>
    event?.titre.trim().isNotEmpty == true ? event!.titre.trim() : 'Aucune etape partagee aujourd hui';

String _familyTodayMetaSummary(MobilePlanningEvent? event) {
  final parts = <String>[
    if (event?.heureDebutPrevue != null) _formatFamilyHour(event!.heureDebutPrevue!),
    if (event?.lieux.isNotEmpty == true) event!.lieux.first.toUpperCase(),
    if (event?.etape?.trim().isNotEmpty == true) _familyTodayEtapeText(event!.etape!),
  ];
  return parts.isEmpty ? 'Journee en attente de partage' : parts.join(' · ');
}

String _familyTodayEtapeText(String rawValue) {
  final n = rawValue.trim();
  if (n.isEmpty) return '';
  switch (n.toLowerCase()) {
    case 'arrivee':      return 'Etape arrivee';
    case 'tawaf_arrivee': return 'Etape tawaf arrivee';
    case 'saee':         return 'Etape saee';
    case 'mina':         return 'Etape Mina';
    case 'arafat':       return 'Etape Arafat';
    case 'mouzdalifa':   return 'Etape Mouzdalifa';
    case 'lapidation':   return 'Etape lapidation';
    case 'tawaf_ifada':  return 'Etape tawaf ifada';
    case 'depart':       return 'Etape depart';
    default:             return 'Etape ${n.replaceAll('_', ' ')}';
  }
}

String _familyTripDateLabel(FamilyLinkedGroup? group) {
  if (group == null) return 'Sans groupe actif';
  final d = group.dateDepart;
  final r = group.dateRetour;
  if (d != null && r != null) return 'Du ${_formatFamilyShortDate(d)} au ${_formatFamilyShortDate(r)}';
  if (d != null) return 'Depart le ${_formatFamilyShortDate(d)}';
  if (r != null) return 'Retour le ${_formatFamilyShortDate(r)}';
  return '${group.typeVoyage == 'HAJJ' ? 'Hajj' : 'Omra'} ${group.annee}';
}

FamilyLink? _resolveSelectedLink(List<FamilyLink> links, String? selectedGroupId) {
  if (links.isEmpty) return null;
  if (selectedGroupId != null) {
    for (final l in links) { if (l.groupe?.id == selectedGroupId) return l; }
  }
  for (final l in links) { if (l.groupe?.id.isNotEmpty == true) return l; }
  return links.first;
}

List<FamilyLink> _sortFamilyLinksForToday(List<FamilyLink> links, String? selectedGroupId) {
  return [...links]..sort((a, b) {
    // 1. Selected group first
    final aSelected = a.groupe?.id == selectedGroupId;
    final bSelected = b.groupe?.id == selectedGroupId;
    if (aSelected != bSelected) return aSelected ? -1 : 1;

    // 2. Most recently linked first
    final aAt = a.linkedAt?.millisecondsSinceEpoch ?? 0;
    final bAt = b.linkedAt?.millisecondsSinceEpoch ?? 0;
    if (aAt != bAt) return bAt.compareTo(aAt);

    return a.fullName.compareTo(b.fullName);
  });
}

String _formatFamilyNotificationTime(DateTime value) {
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'A l instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
}

String _formatFamilyHour(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _formatFamilyShortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
