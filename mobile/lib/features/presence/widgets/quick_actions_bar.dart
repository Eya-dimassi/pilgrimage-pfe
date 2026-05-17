import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback onMarquerTousPresents;
  final VoidCallback onRelancerAbsents;

  const QuickActionsBar({
    super.key,
    required this.onMarquerTousPresents,
    required this.onRelancerAbsents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onMarquerTousPresents,
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text('presence.quick_actions.all_present'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRelancerAbsents,
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text('presence.quick_actions.remind_absent'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
