import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/saudi_time.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../services/notification_navigation_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sos/domain/guide_sos_alert.dart';
import '../../sos/domain/sos_alert.dart';
import '../../sos/providers/guide_sos_provider.dart';
import '../data/mobile_notifications_repository.dart';
import '../domain/mobile_notification.dart';
import '../providers/mobile_notifications_provider.dart';

enum _AlertsScope {
  today,
  yesterday,
  earlier,
}

class MobileAlertsScreen extends ConsumerStatefulWidget {
  const MobileAlertsScreen({super.key});

  @override
  ConsumerState<MobileAlertsScreen> createState() => _MobileAlertsScreenState();
}

class _MobileAlertsScreenState extends ConsumerState<MobileAlertsScreen> {
  _AlertsScope _selectedScope = _AlertsScope.today;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(mobileNotificationsProvider);
    final userRole = ref.watch(authProvider).valueOrNull?.user.role;
    final guideSosAsync = userRole == 'GUIDE'
        ? ref.watch(guideSosProvider)
        : const AsyncValue.data(<GuideSosAlert>[]);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final notificationsRefresh = ref.refresh(mobileNotificationsProvider.future);
        await notificationsRefresh;
        if (userRole == 'GUIDE') {
          final guideRefresh = ref.refresh(guideSosProvider.future);
          await guideRefresh;
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
        children: [
          _AlertsHeader(
            unreadCount: feedAsync.valueOrNull?.unreadCount ?? 0,
            onMarkAllRead:
                feedAsync.valueOrNull?.unreadCount == 0
                    ? null
                    : () async {
                      await ref
                          .read(mobileNotificationsRepositoryProvider)
                          .markAllAsRead();
                      ref.invalidate(mobileNotificationsProvider);
                    },
          ),
          const SizedBox(height: AppSpacing.l),
          _AlertsScopeBar(
            selectedScope: _selectedScope,
            onChanged: (scope) {
              setState(() {
                _selectedScope = scope;
              });
            },
          ),
          const SizedBox(height: AppSpacing.l),
          if (userRole == 'GUIDE') ...[
            _GuideSosSection(
              alertsAsync: guideSosAsync,
              selectedScope: _selectedScope,
            ),
            const SizedBox(height: AppSpacing.l),
          ],
          feedAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            error:
                (error, _) => _AlertsEmptyState(
                  icon: Icons.info_outline_rounded,
                  title: 'alerts.errors.load_notifications'.tr(),
                  subtitle: error.toString(),
                ),
            data: (feed) {
              final items = _filterNotifications(feed.items, _selectedScope);

              if (items.isEmpty) {
                return _AlertsEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: _emptyTitleForScope(_selectedScope),
                  subtitle:
                      'alerts.empty.feed_subtitle'.tr(),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _NotificationRow(item: items[i]),
                    if (i != items.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.borderSoft,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<MobileNotificationItem> _filterNotifications(
    List<MobileNotificationItem> items,
    _AlertsScope scope,
  ) {
    final now = SaudiTime.now();
    final today = SaudiTime.dayOf(now);
    final yesterday = today.subtract(const Duration(days: 1));

    return items.where((item) {
      final itemDay = SaudiTime.dayOf(item.createdAt);

      switch (scope) {
        case _AlertsScope.today:
          return itemDay == today;
        case _AlertsScope.yesterday:
          return itemDay == yesterday;
        case _AlertsScope.earlier:
          return itemDay.isBefore(yesterday);
      }
    }).toList();
  }

  String _emptyTitleForScope(_AlertsScope scope) {
    switch (scope) {
      case _AlertsScope.today:
        return 'alerts.empty.today'.tr();
      case _AlertsScope.yesterday:
        return 'alerts.empty.yesterday'.tr();
      case _AlertsScope.earlier:
        return 'alerts.empty.earlier'.tr();
    }
  }
}

class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({
    required this.unreadCount,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final Future<void> Function()? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'alerts.title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            if (onMarkAllRead != null)
              TextButton(
                onPressed: onMarkAllRead,
                child: Text('alerts.mark_all_read'.tr()),
              )
            else
              const SizedBox(width: 72),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          unreadCount == 0
              ? 'alerts.all_caught_up'.tr()
              : unreadCount == 1
              ? 'alerts.unread_one'.tr()
              : 'alerts.unread_count'.tr(namedArgs: {'count': '$unreadCount'}),
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _AlertsScopeBar extends StatelessWidget {
  const _AlertsScopeBar({
    required this.selectedScope,
    required this.onChanged,
  });

  final _AlertsScope selectedScope;
  final ValueChanged<_AlertsScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScopeChip(
          label: 'alerts.scope.today'.tr(),
          selected: selectedScope == _AlertsScope.today,
          onTap: () => onChanged(_AlertsScope.today),
        ),
        const SizedBox(width: AppSpacing.s),
        _ScopeChip(
          label: 'alerts.scope.yesterday'.tr(),
          selected: selectedScope == _AlertsScope.yesterday,
          onTap: () => onChanged(_AlertsScope.yesterday),
        ),
        const SizedBox(width: AppSpacing.s),
        _ScopeChip(
          label: 'alerts.scope.earlier'.tr(),
          selected: selectedScope == _AlertsScope.earlier,
          onTap: () => onChanged(_AlertsScope.earlier),
        ),
      ],
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.section,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _GuideSosSection extends StatelessWidget {
  const _GuideSosSection({
    required this.alertsAsync,
    required this.selectedScope,
  });

  final AsyncValue<List<GuideSosAlert>> alertsAsync;
  final _AlertsScope selectedScope;

  @override
  Widget build(BuildContext context) {
    return alertsAsync.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      error:
          (error, _) => _AlertsEmptyState(
            icon: Icons.sos_outlined,
            title: 'alerts.errors.load_sos'.tr(),
            subtitle: error.toString(),
          ),
      data: (alerts) {
        final filtered = _filterAlerts(alerts, selectedScope);
        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.section,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Text(
              'alerts.guide_sos.none_active'.tr(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppStatusChip(
                  label: 'alerts.guide_sos.chip'.tr(),
                  backgroundColor: AppColors.redSoft,
                  foregroundColor: AppColors.red,
                  icon: Icons.sos_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final alert in filtered) ...[
              _GuideSosCard(alert: alert),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }

  List<GuideSosAlert> _filterAlerts(
    List<GuideSosAlert> alerts,
    _AlertsScope scope,
  ) {
    final now = SaudiTime.now();
    final today = SaudiTime.dayOf(now);
    final yesterday = today.subtract(const Duration(days: 1));

    return alerts.where((alert) {
      final itemDay = SaudiTime.dayOf(alert.createdAt);

      switch (scope) {
        case _AlertsScope.today:
          return itemDay == today;
        case _AlertsScope.yesterday:
          return itemDay == yesterday;
        case _AlertsScope.earlier:
          return itemDay.isBefore(yesterday);
      }
    }).toList();
  }
}


class _GuideSosCard extends ConsumerStatefulWidget {
  const _GuideSosCard({required this.alert});

  final GuideSosAlert alert;

  @override
  ConsumerState<_GuideSosCard> createState() => _GuideSosCardState();
}

class _GuideSosCardState extends ConsumerState<_GuideSosCard> {
  bool _resolving = false;

  @override
  Widget build(BuildContext context) {
    final summary = _summaryForType(widget.alert.type);
    final locationLabel =
        '${widget.alert.latitude.toStringAsFixed(5)}, ${widget.alert.longitude.toStringAsFixed(5)}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: const Color(0xFFF2DCDD)),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFCEDEE),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'alerts.guide_sos.live_title'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.18),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(widget.alert.pelerinName),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.alert.pelerinName.isEmpty
                                ? 'alerts.guide_sos.pilgrim_fallback'.tr()
                                : widget.alert.pelerinName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.alert.groupeNom?.trim().isNotEmpty == true
                                ? widget.alert.groupeNom!
                                : 'alerts.guide_sos.group_unknown'.tr(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        _elapsedLabel(widget.alert.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GuideSosTypeChip(type: widget.alert.type),
                    _MiniInfoChip(
                      icon: Icons.place_outlined,
                      label: locationLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'alerts.guide_sos.situation'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (widget.alert.message?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              'alerts.guide_sos.message'.tr(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                widget.alert.message!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _resolving ? null : _confirmResolve,
              icon: _resolving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(
                _resolving
                    ? 'alerts.guide_sos.resolving'.tr()
                    : 'alerts.guide_sos.resolve'.tr(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callPilgrim,
                  icon: const Icon(Icons.call_outlined, size: 16),
                  label: Text('alerts.guide_sos.call'.tr()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text('alerts.guide_sos.location'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResolve() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Text(
                'alerts.guide_sos.resolve_sheet_title'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'alerts.guide_sos.resolve_sheet_message'.tr(
                  namedArgs: {
                    'name':
                        widget.alert.pelerinName.isNotEmpty
                            ? widget.alert.pelerinName
                            : 'alerts.guide_sos.pilgrim_fallback'.tr(),
                  },
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('actions.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('actions.confirm'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _resolving = true);
    try {
      await ref.read(guideSosActionsProvider).resolve(widget.alert.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('alerts.guide_sos.resolved_toast'.tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _resolving = false);
      }
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.alert.latitude},${widget.alert.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPilgrim() async {
    final phone = widget.alert.pelerinPhone?.trim() ?? '';
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('alerts.guide_sos.phone_unavailable'.tr())),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  String _elapsedLabel(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'alerts.guide_sos.elapsed.now'.tr();
    if (diff.inMinutes < 60) {
      return 'alerts.guide_sos.elapsed.minutes_ago'.tr(
        namedArgs: {'count': '${diff.inMinutes}'},
      );
    }
    return 'alerts.guide_sos.elapsed.hours_ago'.tr(
      namedArgs: {'count': '${diff.inHours}'},
    );
  }

  String _summaryForType(SosIncidentType type) {
    switch (type) {
      case SosIncidentType.maladie:
        return 'alerts.guide_sos.summary.maladie'.tr();
      case SosIncidentType.perte:
        return 'alerts.guide_sos.summary.perte'.tr();
      case SosIncidentType.logistique:
        return 'alerts.guide_sos.summary.logistique'.tr();
      case SosIncidentType.autre:
        return 'alerts.guide_sos.summary.autre'.tr();
    }
  }
}

class _GuideSosTypeChip extends StatelessWidget {
  const _GuideSosTypeChip({required this.type});

  final SosIncidentType type;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: tone.foreground,
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color foreground}) _toneForType(SosIncidentType type) {
  switch (type) {
    case SosIncidentType.maladie:
      return (
        background: const Color(0xFFFFF5DD),
        foreground: const Color(0xFFE0A11B),
      );
    case SosIncidentType.perte:
      return (
        background: const Color(0xFFEAF2FF),
        foreground: const Color(0xFF2F7BEA),
      );
    case SosIncidentType.logistique:
      return (
        background: const Color(0xFFFFECDD),
        foreground: const Color(0xFFEA7A2F),
      );
    case SosIncidentType.autre:
      return (
        background: const Color(0xFFF0F2F5),
        foreground: const Color(0xFF6D7484),
      );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({
    required this.item,
  });

  final MobileNotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user.role ?? 'PELERIN';
    final presentation = _presentationForNotification(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () async {
          if (!item.isRead) {
            await ref
                .read(mobileNotificationsRepositoryProvider)
                .markAsRead(item.id);
            ref.invalidate(mobileNotificationsProvider);
          }

          NotificationNavigationService.openFromPayload({
            if (item.type != null) 'type': item.type!,
            if (item.tab != null) 'tab': item.tab!,
            if (item.groupeId != null) 'groupeId': item.groupeId!,
            if (item.eventId != null) 'eventId': item.eventId!,
            if (item.etape != null) 'etape': item.etape!,
          }, role: role);
        },
          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color:
                item.isRead
                    ? Colors.transparent
                    : presentation.background.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: presentation.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.foreground,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          _timeLabel(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    if ((item.etape ?? '').trim().isNotEmpty ||
                        presentation.label != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (presentation.label != null)
                            AppStatusChip(
                              label: presentation.label!,
                              icon: presentation.icon,
                              backgroundColor: presentation.background,
                              foregroundColor: presentation.foreground,
                              compact: true,
                            ),
                          if ((item.etape ?? '').trim().isNotEmpty)
                            AppStatusChip(
                              label: item.etape!,
                              backgroundColor: AppColors.section,
                              foregroundColor: AppColors.textSecondary,
                              compact: true,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child:
                    item.isRead
                        ? const SizedBox(width: 8, height: 8)
                        : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime date) {
    final now = SaudiTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'alerts.notification.instant'.tr();
    if (difference.inMinutes < 60) {
      return 'alerts.notification.minutes_ago'.tr(
        namedArgs: {'count': '${difference.inMinutes}'},
      );
    }
    if (difference.inHours < 24) {
      return 'alerts.notification.hours_ago'.tr(
        namedArgs: {'count': '${difference.inHours}'},
      );
    }
    return 'alerts.notification.days_ago'.tr(
      namedArgs: {'count': '${difference.inDays}'},
    );
  }
}

class _NotificationPresentation {
  const _NotificationPresentation({
    required this.background,
    required this.foreground,
    required this.icon,
    this.label,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
  final String? label;
}

_NotificationPresentation _presentationForNotification(
  MobileNotificationItem item,
) {
  final title = item.title.toLowerCase();
  final body = item.body.toLowerCase();
  final type = item.type?.toLowerCase();

  if (type == 'sos') {
    return const _NotificationPresentation(
      background: AppColors.redSoft,
      foreground: AppColors.red,
      icon: Icons.sos_rounded,
      label: 'SOS',
    );
  }

  if (type == 'sos_resolved') {
    return _NotificationPresentation(
      background: AppColors.greenSoft,
      foreground: AppColors.green,
      icon: Icons.health_and_safety_outlined,
      label: 'alerts.notification.labels.sos_resolved'.tr(),
    );
  }

  final isCancelledStep =
      type == 'alert' &&
      (title.contains('annulee') ||
          title.contains('annul') ||
          body.contains(' a annule '));
  if (isCancelledStep) {
    return _NotificationPresentation(
      background: Color(0xFFFFF1E7),
      foreground: Color(0xFFCC6A1C),
      icon: Icons.event_busy_rounded,
      label: 'alerts.notification.labels.step_cancelled'.tr(),
    );
  }

  final isCompletedStep =
      type == 'alert' &&
      (title.contains('terminee') ||
          title.contains('termine') ||
          body.contains(' est passe a '));
  if (isCompletedStep) {
    return _NotificationPresentation(
      background: AppColors.greenSoft,
      foreground: AppColors.green,
      icon: Icons.check_circle_outline_rounded,
      label: 'alerts.notification.labels.step_completed'.tr(),
    );
  }

  if (type == 'planning' || type == 'planning_update') {
    return _NotificationPresentation(
      background: AppColors.blueSoft,
      foreground: AppColors.blue,
      icon: Icons.calendar_today_rounded,
      label: 'alerts.notification.labels.planning'.tr(),
    );
  }

  if (type == 'upcoming_rendezvous') {
    return _NotificationPresentation(
      background: AppColors.goldSoft,
      foreground: AppColors.gold,
      icon: Icons.alarm_rounded,
      label: 'alerts.notification.labels.reminder'.tr(),
    );
  }

  return _NotificationPresentation(
    background: AppColors.blueSoft,
    foreground: AppColors.blue,
    icon: Icons.notifications_none_rounded,
    label: 'alerts.notification.labels.generic'.tr(),
  );
}

class _AlertsEmptyState extends StatelessWidget {
  const _AlertsEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadow: const [],
      child: Column(
        children: [
          AppIconBadge(
            icon: icon,
            size: 56,
            backgroundColor: AppColors.section,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
