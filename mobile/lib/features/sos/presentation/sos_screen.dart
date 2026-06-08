import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/sos_alert.dart';

Future<SosIncidentType?> showSosTypePickerSheet(BuildContext context) {
  return showModalBottomSheet<SosIncidentType>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _SosTypePickerSheet(),
  );
}

Future<void> showSosConfirmationSheet(
  BuildContext context, {
  required SosAlert alert,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0x14B3292D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: Color(0xFFB3292D),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'sos.sheet.confirmation_title'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'sos.sheet.confirmation_message'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _accentForType(alert.type).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _sosTypeLabel(alert.type).tr(),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _accentForType(alert.type),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF4F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'sos.sheet.position_sent'.tr(
                    namedArgs: {
                      'lat': alert.latitude.toStringAsFixed(5),
                      'lng': alert.longitude.toStringAsFixed(5),
                    },
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3292D),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('sos.sheet.got_it'.tr()),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool?> showSosSendConfirmSheet(
  BuildContext context, {
  required SosIncidentType type,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final accent = _accentForType(type);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _iconForType(type),
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'sos.sheet.confirm_type_title'.tr(
                  namedArgs: {'type': _sosTypeLabel(type).tr().toLowerCase()},
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type == SosIncidentType.autre
                    ? 'sos.sheet.confirm_other_message'.tr()
                    : 'sos.sheet.confirm_default_message'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('actions.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('actions.confirm'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SosTypePickerSheet extends StatelessWidget {
  const _SosTypePickerSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
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
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'sos.sheet.pick_situation_title'.tr(),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'sos.sheet.pick_situation_subtitle'.tr(),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            for (final type in SosIncidentType.values) ...[
              _SosTypeCard(type: type),
              if (type != SosIncidentType.values.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SosTypeCard extends StatelessWidget {
  const _SosTypeCard({required this.type});

  final SosIncidentType type;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(type);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).pop(type),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _iconForType(type),
                color: accent,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sosTypeLabel(type).tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _sosTypeDescription(type).tr(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}

String _sosTypeLabel(SosIncidentType type) {
  switch (type) {
    case SosIncidentType.maladie:
      return 'sos.types.maladie.label';
    case SosIncidentType.perte:
      return 'sos.types.perte.label';
    case SosIncidentType.logistique:
      return 'sos.types.logistique.label';
    case SosIncidentType.autre:
      return 'sos.types.autre.label';
  }
}

String _sosTypeDescription(SosIncidentType type) {
  switch (type) {
    case SosIncidentType.maladie:
      return 'sos.types.maladie.description';
    case SosIncidentType.perte:
      return 'sos.types.perte.description';
    case SosIncidentType.logistique:
      return 'sos.types.logistique.description';
    case SosIncidentType.autre:
      return 'sos.types.autre.description';
  }
}

Color _accentForType(SosIncidentType type) {
  switch (type) {
    case SosIncidentType.maladie:
      return const Color(0xFFE0A11B);
    case SosIncidentType.perte:
      return const Color(0xFF2F7BEA);
    case SosIncidentType.logistique:
      return const Color(0xFFEA7A2F);
    case SosIncidentType.autre:
      return const Color(0xFF6D7484);
  }
}

IconData _iconForType(SosIncidentType type) {
  switch (type) {
    case SosIncidentType.maladie:
      return Icons.health_and_safety_outlined;
    case SosIncidentType.perte:
      return Icons.search_rounded;
    case SosIncidentType.logistique:
      return Icons.route_rounded;
    case SosIncidentType.autre:
      return Icons.support_agent_rounded;
  }
}
