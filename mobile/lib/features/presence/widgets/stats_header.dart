// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../domain/models/presence_stats.dart';

class StatsHeader extends StatelessWidget {
  final PresenceStats stats;

  const StatsHeader({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            icon: Icons.people,
            label: 'presence.stats.total'.tr(),
            value: stats.total.toString(),
            color: Colors.grey.shade700,
          ),
          _StatChip(
            icon: Icons.check_circle,
            label: 'presence.stats.present'.tr(),
            value: stats.presents.toString(),
            color: Colors.green.shade700,
          ),
          _StatChip(
            icon: Icons.cancel,
            label: 'presence.stats.absent'.tr(),
            value: stats.absents.toString(),
            color: Colors.red.shade700,
          ),
          _StatChip(
            icon: Icons.info,
            label: 'presence.stats.excuse'.tr(),
            value: stats.excuses.toString(),
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
