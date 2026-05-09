import 'saudi_time.dart';

double computeTripProgress(
  DateTime? start,
  DateTime? end,
  DateTime? currentDay,
) {
  if (start == null || end == null || currentDay == null) {
    return 0.0;
  }

  final normalizedStart = SaudiTime.dayOf(start);
  final normalizedEnd = SaudiTime.dayOf(end);
  final normalizedCurrent = SaudiTime.dayOf(currentDay);

  final totalDays =
      normalizedEnd.difference(normalizedStart).inDays + 1;

  if (totalDays <= 0) {
    return 0.0;
  }

  final currentIndex =
      normalizedCurrent.difference(normalizedStart).inDays + 1;

  return (currentIndex / totalDays).clamp(0.0, 1.0);
}