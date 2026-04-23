import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_navigation_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/mobile_notifications_repository.dart';
import '../domain/mobile_notification.dart';
import '../providers/mobile_notifications_provider.dart';

class MobileAlertsScreen extends ConsumerWidget {
  const MobileAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(mobileNotificationsProvider);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        final refreshed = ref.refresh(mobileNotificationsProvider.future);
        await refreshed;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        children: [
          _AlertsHeader(
            unreadCount: feedAsync.valueOrNull?.unreadCount ?? 0,
            onMarkAllRead: feedAsync.valueOrNull?.unreadCount == 0
                ? null
                : () async {
                    await ref
                        .read(mobileNotificationsRepositoryProvider)
                        .markAllAsRead();
                    ref.invalidate(mobileNotificationsProvider);
                  },
          ),
          const SizedBox(height: 16),
          feedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (error, _) => _AlertsEmptyState(
              icon: Icons.info_outline_rounded,
              title: 'Impossible de charger les alertes',
              subtitle: error.toString(),
            ),
            data: (feed) {
              if (feed.items.isEmpty) {
                return const _AlertsEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Aucune alerte pour le moment',
                  subtitle:
                      'Les validations d etapes, rappels et changements importants apparaitront ici.',
                );
              }

              return Column(
                children: [
                  for (final item in feed.items) ...[
                    _NotificationCard(item: item),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alertes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unreadCount == 0
                          ? 'Tout est lu'
                          : '$unreadCount nouvelle(s) alerte(s)',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onMarkAllRead,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.goldSoft,
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tout marquer comme lu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({
    required this.item,
  });

  final MobileNotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user.role ?? 'PELERIN';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.white.withValues(alpha: 0.92)
                : const Color(0xFFFFFBF1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: item.isRead ? AppColors.borderSoft : AppColors.goldSoft,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? AppColors.borderSoft
                      : AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: item.isRead ? AppColors.textMuted : AppColors.gold,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _timeLabel(item.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textFaint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (item.etape != null && item.etape!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.etape!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w800,
                          ),
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

  IconData _iconForType(String? type) {
    switch (type) {
      case 'planning_update':
      case 'planning':
        return Icons.calendar_today_outlined;
      case 'upcoming_rendezvous':
        return Icons.alarm_rounded;
      case 'alert':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _timeLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Maintenant';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min';
    if (difference.inHours < 24) return '${difference.inHours} h';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.gold),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
