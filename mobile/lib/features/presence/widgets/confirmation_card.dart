// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../domain/models/confirmation_presence.dart';

class ConfirmationCard extends StatelessWidget {
  final ConfirmationPresence confirmation;
  final String currentStatut;
  final String? currentNote;
  final bool hasLocalChanges;
  final ValueChanged<String> onStatutChanged;
  final VoidCallback onNotePressed;

  const ConfirmationCard({
    super.key,
    required this.confirmation,
    required this.currentStatut,
    this.currentNote,
    required this.hasLocalChanges,
    required this.onStatutChanged,
    required this.onNotePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: hasLocalChanges ? 3 : 1,
      color: hasLocalChanges
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatutColor(currentStatut, theme),
              backgroundImage: confirmation.pelerin.utilisateur.photoUrl != null
                  ? NetworkImage(confirmation.pelerin.utilisateur.photoUrl!)
                  : null,
              child: confirmation.pelerin.utilisateur.photoUrl == null
                  ? Text(
                      confirmation.pelerin.initiales,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              confirmation.pelerin.nomComplet,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: currentNote != null
                ? Text(
                    currentNote!,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: onNotePressed,
              color: currentNote != null
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color?.withOpacity(0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _StatutButton(
                    targetStatut: 'PRESENT',
                    currentStatut: currentStatut,
                    icon: Icons.check_circle,
                    label: 'Present',
                    color: Colors.green,
                    onPressed: () => onStatutChanged('PRESENT'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatutButton(
                    targetStatut: 'ABSENT',
                    currentStatut: currentStatut,
                    icon: Icons.cancel,
                    label: 'Absent',
                    color: Colors.red,
                    onPressed: () => onStatutChanged('ABSENT'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(String statut, ThemeData theme) {
    switch (statut) {
      case 'PRESENT':
        return Colors.green;
      case 'ABSENT':
        return Colors.red;
      case 'EXCUSE':
        return Colors.red;
      default:
        return theme.colorScheme.surfaceVariant;
    }
  }
}

class _StatutButton extends StatelessWidget {
  final String targetStatut;
  final String currentStatut;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _StatutButton({
    required this.targetStatut,
    required this.currentStatut,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentStatut == targetStatut;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }
}
