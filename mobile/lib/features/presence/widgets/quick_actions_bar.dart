import 'package:flutter/material.dart';

class QuickActionsBar extends StatelessWidget {
  final VoidCallback onMarquerTousPresents;
  final VoidCallback onReinitialiser;

  const QuickActionsBar({
    super.key,
    required this.onMarquerTousPresents,
    required this.onReinitialiser,
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
              label: const Text('Tous presents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReinitialiser,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reinitialiser'),
            ),
          ),
        ],
      ),
    );
  }
}
