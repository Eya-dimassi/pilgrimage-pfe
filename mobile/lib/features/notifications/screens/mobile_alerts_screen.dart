import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surfaces.dart';
import '../../../services/notification_navigation_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sos/domain/guide_sos_alert.dart';
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
                  title: 'Unable to load notifications',
                  subtitle: error.toString(),
                ),
            data: (feed) {
              final items = _filterNotifications(feed.items, _selectedScope);

              if (items.isEmpty) {
                return _AlertsEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: _emptyTitleForScope(_selectedScope),
                  subtitle:
                      'Planning changes, reminders, and safety updates will appear here as your trip moves forward.',
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return items.where((item) {
      final itemDay = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );

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
        return 'Nothing for today yet';
      case _AlertsScope.yesterday:
        return 'No updates from yesterday';
      case _AlertsScope.earlier:
        return 'No earlier notifications';
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
            const Expanded(
              child: Text(
                'Notification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            if (onMarkAllRead != null)
              TextButton(
                onPressed: onMarkAllRead,
                child: const Text('Mark all'),
              )
            else
              const SizedBox(width: 72),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          unreadCount == 0
              ? 'Everything is up to date.'
              : '$unreadCount unread alert${unreadCount > 1 ? 's' : ''} waiting for you.',
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
          label: 'Today',
          selected: selectedScope == _AlertsScope.today,
          onTap: () => onChanged(_AlertsScope.today),
        ),
        const SizedBox(width: AppSpacing.s),
        _ScopeChip(
          label: 'Yesterday',
          selected: selectedScope == _AlertsScope.yesterday,
          onTap: () => onChanged(_AlertsScope.yesterday),
        ),
        const SizedBox(width: AppSpacing.s),
        _ScopeChip(
          label: 'Earlier',
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
            title: 'Unable to load SOS alerts',
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
            child: const Text(
              'Aucune urgence SOS active pour le moment.',
              style: TextStyle(
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
            const Row(
              children: [
                AppStatusChip(
                  label: 'Guide SOS',
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    return alerts.where((alert) {
      final itemDay = DateTime(
        alert.createdAt.year,
        alert.createdAt.month,
        alert.createdAt.day,
      );

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border(
          left: const BorderSide(color: AppColors.red, width: 3),
          top: BorderSide(color: AppColors.red.withValues(alpha: 0.10)),
          right: BorderSide(color: AppColors.red.withValues(alpha: 0.10)),
          bottom: BorderSide(color: AppColors.red.withValues(alpha: 0.10)),
        ),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
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
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alert.pelerinName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.alert.groupeNom != null)
                      Text(
                        widget.alert.groupeNom!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
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
          if (widget.alert.message?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.section,
                borderRadius: BorderRadius.circular(AppRadii.sm),
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
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.location_on_outlined, size: 16),
                  label: const Text('Position'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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
                  label: Text(_resolving ? 'En cours...' : 'Resoudre'),
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
              const Text(
                'Resoudre l\'alerte',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Confirmez-vous que ${widget.alert.pelerinName} va bien et que la situation est prise en charge ?',
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
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Confirmer'),
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
        const SnackBar(content: Text('Alerte SOS resolue')),
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
    if (diff.inMinutes < 1) return 'Maintenant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    return 'Il y a ${diff.inHours} h';
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
    final tone = _toneForType(item.type);

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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color:
                item.isRead
                    ? Colors.transparent
                    : tone.background.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: tone.foreground,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          _timeLabel(item.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    if ((item.etape ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s),
                      AppStatusChip(
                        label: item.etape!,
                        backgroundColor: tone.background,
                        foregroundColor: tone.foreground,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Padding(
                padding: const EdgeInsets.only(top: 4),
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

  IconData _iconForType(String? type) {
    switch (type) {
      case 'planning':
      case 'planning_update':
        return Icons.calendar_today_rounded;
      case 'upcoming_rendezvous':
        return Icons.alarm_rounded;
      case 'alert':
        return Icons.priority_high_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  ({Color background, Color foreground}) _toneForType(String? type) {
    switch (type) {
      case 'planning':
      case 'planning_update':
        return (
          background: AppColors.greenSoft,
          foreground: AppColors.primary,
        );
      case 'upcoming_rendezvous':
        return (
          background: AppColors.goldSoft,
          foreground: AppColors.gold,
        );
      case 'alert':
        return (
          background: AppColors.redSoft,
          foreground: AppColors.red,
        );
      default:
        return (
          background: AppColors.blueSoft,
          foreground: AppColors.blue,
        );
    }
  }

  String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
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
