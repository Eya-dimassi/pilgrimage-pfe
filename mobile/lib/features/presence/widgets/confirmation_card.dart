// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final isQrConfirmed =
        confirmation.statut == 'PRESENT' && confirmation.confirmeMode == 'QR';

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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentNote != null)
                  Text(
                    currentNote!,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                if (isQrConfirmed) ...[
                  if (currentNote != null) const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 14,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Confirmé par QR',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatutIconButton(
                  targetStatut: 'PRESENT',
                  currentStatut: currentStatut,
                  icon: Icons.check_circle,
                  tooltip: 'presence.status.present'.tr(),
                  color: Colors.green,
                  onPressed:
                      isQrConfirmed ? null : () => onStatutChanged('PRESENT'),
                ),
                const SizedBox(width: 8),
                _StatutIconButton(
                  targetStatut: 'EXCUSE',
                  currentStatut: currentStatut,
                  icon: Icons.info,
                  tooltip: 'presence.status.excuse'.tr(),
                  color: Colors.orange,
                  onPressed:
                      isQrConfirmed ? null : () => onStatutChanged('EXCUSE'),
                ),
                const SizedBox(width: 8),
                _StatutIconButton(
                  targetStatut: 'ABSENT',
                  currentStatut: currentStatut,
                  icon: Icons.cancel,
                  tooltip: 'presence.status.absent'.tr(),
                  color: Colors.red,
                  onPressed:
                      isQrConfirmed ? null : () => onStatutChanged('ABSENT'),
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
        return Colors.orange;
      default:
        return theme.colorScheme.surfaceVariant;
    }
  }
}

class _StatutIconButton extends StatelessWidget {
  final String targetStatut;
  final String currentStatut;
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  const _StatutIconButton({
    required this.targetStatut,
    required this.currentStatut,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentStatut == targetStatut;
    final isDisabled = onPressed == null;

    return Tooltip(
      message: tooltip,
      child: Ink(
        decoration: ShapeDecoration(
          color: isDisabled
              ? Colors.grey.shade100
              : isSelected
                  ? color
                  : Colors.grey.shade200,
          shape: const CircleBorder(),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: isDisabled
              ? Colors.grey.shade400
              : isSelected
                  ? Colors.white
                  : Colors.grey.shade700,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
