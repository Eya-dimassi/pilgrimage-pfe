import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class AdhanPanel extends StatelessWidget {
  const AdhanPanel({
    super.key,
    required this.accentColor,
    required this.roleToneLabel,
    this.compact = false,
  });

  final Color accentColor;
  final String roleToneLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final timeline = _PrayerTimeline.forNow();

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.lifted,
      ),
      child: compact
          ? _CompactPrayerBlock(
              timeline: timeline,
              accentColor: accentColor,
            )
          : _ExpandedPrayerBlock(
              timeline: timeline,
              accentColor: accentColor,
              roleToneLabel: roleToneLabel,
            ),
    );
  }
}

class _ExpandedPrayerBlock extends StatelessWidget {
  const _ExpandedPrayerBlock({
    required this.timeline,
    required this.accentColor,
    required this.roleToneLabel,
  });

  final _PrayerTimeline timeline;
  final Color accentColor;
  final String roleToneLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appel a la priere',
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleToneLabel,
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
        Text(
          timeline.message,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        _PrayerRow(
          timeline: timeline,
          accentColor: accentColor,
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.section,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Text(
            'Horaires calcules pour Makkah. ${timeline.footer}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactPrayerBlock extends StatelessWidget {
  const _CompactPrayerBlock({
    required this.timeline,
    required this.accentColor,
  });

  final _PrayerTimeline timeline;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF4E7C3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.nightlight_round,
                size: 17,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horaires de priere',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeline.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: timeline.entries.map((entry) {
            final isActive = entry.isActive;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFFEAEAEA),
                    width: isActive ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      _iconFor(entry.name),
                      size: 14,
                      color: isActive
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.wb_twilight_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny_outlined;
      case 'Asr':
        return Icons.cloud_outlined;
      case 'Maghrib':
        return Icons.wb_twilight;
      case 'Isha':
        return Icons.nightlight_round;
      default:
        return Icons.access_time;
    }
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.timeline,
    required this.accentColor,
  });

  final _PrayerTimeline timeline;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < timeline.entries.length; index++) ...[
            _PrayerChip(
              entry: timeline.entries[index],
              accentColor: accentColor,
              compact: false,
            ),
            if (index < timeline.entries.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PrayerChip extends StatelessWidget {
  const _PrayerChip({
    required this.entry,
    required this.accentColor,
    required this.compact,
  });

  final _PrayerEntry entry;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = entry.isActive;
    final icon = switch (entry.name) {
      'Fajr' => Icons.wb_twilight_outlined,
      'Dhuhr' => Icons.wb_sunny_outlined,
      'Asr' => Icons.cloud_outlined,
      'Maghrib' => Icons.wb_twilight,
      'Isha' => Icons.nightlight_round,
      _ => Icons.access_time_rounded,
    };

    return Container(
      width: compact ? 0 : 108,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 8 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 18 : 18),
        border: Border.all(
          color: isActive ? AppColors.gold : AppColors.borderSoft,
          width: isActive ? 1.3 : 1,
        ),
        boxShadow: isActive ? AppShadows.soft : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            entry.name,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.time,
            style: TextStyle(
              fontSize: compact ? 13 : 16,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: compact ? 28 : 38,
            height: compact ? 28 : 38,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.goldSoft
                  : accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: compact ? 17 : 20,
              color: isActive ? AppColors.primaryDark : accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerEntry {
  const _PrayerEntry({
    required this.name,
    required this.time,
    this.isActive = false,
  });

  final String name;
  final String time;
  final bool isActive;
}

class _PrayerTimeline {
  const _PrayerTimeline({
    required this.message,
    required this.shortLabel,
    required this.footer,
    required this.nextMeta,
    required this.entries,
  });

  final String message;
  final String shortLabel;
  final String footer;
  final String? nextMeta;
  final List<_PrayerEntry> entries;

  static final Coordinates _makkahCoordinates = Coordinates(21.4225, 39.8262);

  static _PrayerTimeline forNow() {
    final params = CalculationMethod.umm_al_qura.getParameters();
    final prayerTimes = PrayerTimes.today(_makkahCoordinates, params);
    final currentPrayer = prayerTimes.currentPrayer();
    final nextPrayer = prayerTimes.nextPrayer();
    final nextPrayerTime = _resolvePrayerTime(nextPrayer, prayerTimes);

    final entries = [
      _PrayerEntry(
        name: 'Fajr',
        time: _formatHour(prayerTimes.fajr),
        isActive: currentPrayer == Prayer.fajr,
      ),
      _PrayerEntry(
        name: 'Dhuhr',
        time: _formatHour(prayerTimes.dhuhr),
        isActive: currentPrayer == Prayer.dhuhr,
      ),
      _PrayerEntry(
        name: 'Asr',
        time: _formatHour(prayerTimes.asr),
        isActive: currentPrayer == Prayer.asr,
      ),
      _PrayerEntry(
        name: 'Maghrib',
        time: _formatHour(prayerTimes.maghrib),
        isActive: currentPrayer == Prayer.maghrib,
      ),
      _PrayerEntry(
        name: 'Isha',
        time: _formatHour(prayerTimes.isha),
        isActive: currentPrayer == Prayer.isha,
      ),
    ];

    return _PrayerTimeline(
      message: _messageForPrayer(currentPrayer, nextPrayer),
      shortLabel: _shortLabel(currentPrayer, nextPrayer),
      footer: nextPrayerTime == null
          ? 'Umm al-Qura'
          : '${_labelForPrayer(nextPrayer)} ${_formatHour(nextPrayerTime)}',
      nextMeta: nextPrayerTime == null
          ? null
          : 'Makkah · ${_labelForPrayer(nextPrayer)} a ${_formatHour(nextPrayerTime)}',
      entries: entries,
    );
  }

  static String _messageForPrayer(Prayer currentPrayer, Prayer nextPrayer) {
    switch (currentPrayer) {
      case Prayer.fajr:
        return 'Le jour commence avec Fajr. Gardez un depart calme avant le mouvement du groupe.';
      case Prayer.dhuhr:
        return 'Dhuhr marque le coeur de la journee. Gardez un repere clair entre rites et deplacements.';
      case Prayer.asr:
        return 'Asr invite a ralentir un instant, verifier le groupe et se recentrer.';
      case Prayer.maghrib:
        return 'Maghrib ouvre un moment de gratitude apres l effort et les deplacements.';
      case Prayer.isha:
        return 'Isha appelle au calme et a la preparation du lendemain.';
      case Prayer.sunrise:
      case Prayer.none:
        return _messageForUpcoming(nextPrayer);
    }
  }

  static String _messageForUpcoming(Prayer nextPrayer) {
    switch (nextPrayer) {
      case Prayer.fajr:
        return 'La prochaine priere sera Fajr. Reposez-vous et gardez l intention du lendemain.';
      case Prayer.dhuhr:
        return 'La prochaine priere sera Dhuhr. Prenez vos reperes avant la reprise du rythme.';
      case Prayer.asr:
        return 'La prochaine priere sera Asr. Gardez un temps pour vous recentrer.';
      case Prayer.maghrib:
        return 'La prochaine priere sera Maghrib. La fin du jour approche avec douceur.';
      case Prayer.isha:
        return 'La prochaine priere sera Isha. Le soir approche, avec plus de calme.';
      case Prayer.sunrise:
        return 'Le lever du jour approche. Gardez un rythme calme avant le prochain mouvement.';
      case Prayer.none:
        return 'Gardez un repere spirituel clair pendant tout le voyage.';
    }
  }

  static String _shortLabel(Prayer currentPrayer, Prayer nextPrayer) {
    if (currentPrayer != Prayer.none) {
      return '${_labelForPrayer(currentPrayer)} en cours';
    }
    if (nextPrayer != Prayer.none) {
      return 'Prochaine priere: ${_labelForPrayer(nextPrayer)}';
    }
    return 'Horaires de priere';
  }

  static String _labelForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.none:
        return 'Priere';
    }
  }

  static DateTime? _resolvePrayerTime(Prayer prayer, PrayerTimes prayerTimes) {
    switch (prayer) {
      case Prayer.fajr:
        return prayerTimes.fajr;
      case Prayer.dhuhr:
        return prayerTimes.dhuhr;
      case Prayer.asr:
        return prayerTimes.asr;
      case Prayer.maghrib:
        return prayerTimes.maghrib;
      case Prayer.isha:
        return prayerTimes.isha;
      case Prayer.sunrise:
        return prayerTimes.sunrise;
      case Prayer.none:
        return null;
    }
  }
}

String _formatHour(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
