import '../../../core/utils/saudi_time.dart';

class MobilePlanningGroup {
  const MobilePlanningGroup({
    required this.id,
    required this.nom,
    required this.annee,
    required this.typeVoyage,
    this.dateDepart,
    this.dateRetour,
    this.status,
    this.nbPelerins,
  });

  final String id;
  final String nom;
  final int annee;
  final String typeVoyage;
  final DateTime? dateDepart;
  final DateTime? dateRetour;
  final String? status;
  final int? nbPelerins;

  factory MobilePlanningGroup.fromJson(Map<String, dynamic> json) {
    return MobilePlanningGroup(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      annee: json['annee'] as int? ?? 0,
      typeVoyage: json['typeVoyage'] as String? ?? '',
      dateDepart: json['dateDepart'] is String
          ? DateTime.tryParse(json['dateDepart'] as String)
          : null,
      dateRetour: json['dateRetour'] is String
          ? DateTime.tryParse(json['dateRetour'] as String)
          : null,
      status: json['status'] as String?,
      nbPelerins: json['nbPelerins'] as int?,
    );
  }
}

class MobileGroupPelerin {
  const MobileGroupPelerin({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
  });

  final String id;
  final String nom;
  final String prenom;
  final String? telephone;

  String get fullName => '${prenom.trim()} ${nom.trim()}'.trim();

  factory MobileGroupPelerin.fromJson(Map<String, dynamic> json) {
    return MobileGroupPelerin(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      telephone: json['telephone'] as String?,
    );
  }
}

class MobilePlanningEvent {
  const MobilePlanningEvent({
    required this.id,
    required this.type,
    required this.titre,
    this.typeLabel,
    this.description,
    this.lieu,
    this.heureDebutPrevue,
    this.etape,
    this.status,
    this.estValide = false,
    this.valideeAt,
    this.valideParGuideId,
  });

  final String id;
  final String type;
  final String titre;
  final String? typeLabel;
  final String? description;
  final String? lieu;
  final DateTime? heureDebutPrevue;
  final String? etape;
  final String? status;
  final bool estValide;
  final DateTime? valideeAt;
  final String? valideParGuideId;

  bool get isCompleted => status == 'TERMINE' || (status == null && estValide);
  bool get isCancelled => status == 'ANNULE';
  bool get isResolved => isCompleted || isCancelled;

  bool get canBeCompleted => !isResolved;
  bool get canBeCancelled => !isResolved;

  List<String> get lieux {
    if (lieu == null || lieu!.trim().isEmpty) return const [];
    return lieu!
        .split(RegExp(r'\s*(?:â€¢|•)\s*'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  factory MobilePlanningEvent.fromJson(Map<String, dynamic> json) {
    return MobilePlanningEvent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      typeLabel: json['typeLabel'] as String?,
      description: json['description'] as String?,
      lieu: json['lieu'] as String?,
      heureDebutPrevue: json['heureDebutPrevue'] is String
          ? DateTime.tryParse(json['heureDebutPrevue'] as String)
          : null,
      etape: json['etape'] as String?,
      status: json['status'] as String?,
      estValide: json['estValide'] as bool? ?? false,
      valideeAt: json['valideeAt'] is String
          ? DateTime.tryParse(json['valideeAt'] as String)
          : null,
      valideParGuideId: json['valideParGuideId'] as String?,
    );
  }
}

class MobilePlanningDay {
  const MobilePlanningDay({
    required this.id,
    required this.date,
    this.titre,
    required this.evenements,
  });

  final String id;
  final DateTime date;
  final String? titre;
  final List<MobilePlanningEvent> evenements;

  factory MobilePlanningDay.fromJson(Map<String, dynamic> json) {
    return MobilePlanningDay(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      titre: json['titre'] as String?,
      evenements: ((json['evenements'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobilePlanningEvent.fromJson)
          .toList(),
    );
  }
}

class MobilePlanningData {
  const MobilePlanningData({
    required this.groupe,
    required this.plannings,
  });

  final MobilePlanningGroup groupe;
  final List<MobilePlanningDay> plannings;

  factory MobilePlanningData.fromJson(Map<String, dynamic> json) {
    return MobilePlanningData(
      groupe: MobilePlanningGroup.fromJson(
        json['groupe'] as Map<String, dynamic>? ?? const {},
      ),
      plannings: ((json['plannings'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobilePlanningDay.fromJson)
          .toList(),
    );
  }
}

class MobilePlanningGroupHistoryItem {
  const MobilePlanningGroupHistoryItem({
    required this.groupe,
    required this.relationActive,
    this.relationDateDebut,
  });

  final MobilePlanningGroup groupe;
  final bool relationActive;
  final DateTime? relationDateDebut;

  factory MobilePlanningGroupHistoryItem.fromJson(Map<String, dynamic> json) {
    return MobilePlanningGroupHistoryItem(
      groupe: MobilePlanningGroup.fromJson(
        json['groupe'] as Map<String, dynamic>? ?? const {},
      ),
      relationActive: json['relationActive'] as bool? ?? false,
      relationDateDebut: json['relationDateDebut'] is String
          ? DateTime.tryParse(json['relationDateDebut'] as String)
          : null,
    );
  }
}

MobilePlanningGroup pickBestPlanningGroup(List<MobilePlanningGroup> groups) {
  if (groups.isEmpty) {
    throw StateError('Cannot pick a group from an empty list.');
  }

  int priority(MobilePlanningGroup group) {
    switch (group.status) {
      case 'EN_COURS':
        return 0;
      case 'PLANIFIE':
        return 1;
      case 'TERMINE':
        return 2;
      case 'ANNULE':
        return 3;
      default:
        return 4;
    }
  }

  final sortedGroups = [...groups]
    ..sort((left, right) {
      final priorityDiff = priority(left) - priority(right);
      if (priorityDiff != 0) return priorityDiff;

      final rightStart = right.dateDepart?.millisecondsSinceEpoch ?? 0;
      final leftStart = left.dateDepart?.millisecondsSinceEpoch ?? 0;
      if (rightStart != leftStart) return rightStart.compareTo(leftStart);

      final rightEnd = right.dateRetour?.millisecondsSinceEpoch ?? 0;
      final leftEnd = left.dateRetour?.millisecondsSinceEpoch ?? 0;
      if (rightEnd != leftEnd) return rightEnd.compareTo(leftEnd);

      return right.annee.compareTo(left.annee);
    });

  return sortedGroups.first;
}

List<MobilePlanningDay> sortPlanningDaysByDate(
  List<MobilePlanningDay> plannings,
) {
  final sortedPlannings = [...plannings]
    ..sort((left, right) => left.date.compareTo(right.date));

  return sortedPlannings;
}

List<MobilePlanningEvent> sortPlanningEventsByTime(
  List<MobilePlanningEvent> events,
) {
  final sortedEvents = [...events]
    ..sort((left, right) {
      final leftHasTime = left.heureDebutPrevue != null;
      final rightHasTime = right.heureDebutPrevue != null;
      if (leftHasTime != rightHasTime) {
        return leftHasTime ? -1 : 1;
      }

      final leftTime = left.heureDebutPrevue?.millisecondsSinceEpoch ?? 0;
      final rightTime = right.heureDebutPrevue?.millisecondsSinceEpoch ?? 0;
      if (leftTime != rightTime) return leftTime.compareTo(rightTime);

      return left.id.compareTo(right.id);
    });

  return sortedEvents;
}

MobilePlanningDay? findPlanningDayForDate(
  List<MobilePlanningDay> plannings,
  DateTime targetDay, {
  bool preferWithEvents = false,
}) {
  if (plannings.isEmpty) return null;

  final normalizedTargetDay = SaudiTime.dayOf(targetDay);
  final sortedPlannings = sortPlanningDaysByDate(plannings);

  if (preferWithEvents) {
    for (final planning in sortedPlannings) {
      if (planning.evenements.isNotEmpty &&
          SaudiTime.isSameDay(planning.date, normalizedTargetDay)) {
        return planning;
      }
    }
  }

  for (final planning in sortedPlannings) {
    if (SaudiTime.isSameDay(planning.date, normalizedTargetDay)) {
      return planning;
    }
  }

  return null;
}

MobilePlanningDay? pickDefaultPlanningDay(
  List<MobilePlanningDay> plannings, {
  DateTime? referenceDay,
  bool exactDayOnly = false,
}) {
  if (plannings.isEmpty) return null;

  final normalizedReferenceDay = SaudiTime.dayOf(referenceDay ?? SaudiTime.now());
  final sortedPlannings = sortPlanningDaysByDate(plannings);
  final exactMatch = findPlanningDayForDate(
    sortedPlannings,
    normalizedReferenceDay,
  );
  if (exactMatch != null) return exactMatch;
  if (exactDayOnly) return null;

  for (final planning in sortedPlannings) {
    final planningDay = SaudiTime.dayOf(planning.date);
    if (planningDay.isAfter(normalizedReferenceDay)) {
      return planning;
    }
  }

  return sortedPlannings.last;
}

MobilePlanningEvent? pickCurrentOrNextPlanningEvent(
  List<MobilePlanningEvent> events, {
  DateTime? now,
}) {
  if (events.isEmpty) return null;

  final currentTime = now ?? SaudiTime.now();
  final sorted = sortPlanningEventsByTime(events);

  // A backend-marked in-progress event always wins.
  for (final event in sorted) {
    if (event.status == 'EN_COURS') return event;
  }

  // Otherwise, the first unresolved event is the real current/next step.
  for (final event in sorted) {
    if (!event.isResolved) return event;
  }

  // If everything is resolved for today, keep showing the latest started event
  // instead of falling back to an empty state.
  MobilePlanningEvent? active;
  for (final event in sorted) {
    final start = event.heureDebutPrevue;
    if (start == null || !start.isAfter(currentTime)) {
      active = event;
    } else {
      break;
    }
  }

  return active ?? sorted.last;
}

MobilePlanningEvent? pickNextPlanningEventPreview(
  List<MobilePlanningDay> plannings, {
  DateTime? anchorDay,
  MobilePlanningEvent? currentEvent,
}) {
  if (plannings.isEmpty) return null;

  final normalizedAnchorDay = SaudiTime.dayOf(anchorDay ?? SaudiTime.now());
  final sorted = sortPlanningDaysByDate(plannings);
  DateTime currentEventDay = normalizedAnchorDay;

  // Look for the next unresolved event after the current one in its own day.
  if (currentEvent != null) {
    for (final planning in sorted) {
      final sortedEvents = sortPlanningEventsByTime(planning.evenements);
      final currentIndex = sortedEvents.indexWhere(
        (event) => event.id == currentEvent.id,
      );
      if (currentIndex < 0) continue;

      currentEventDay = SaudiTime.dayOf(planning.date);
      for (var index = currentIndex + 1; index < sortedEvents.length; index++) {
        final event = sortedEvents[index];
        if (!event.isResolved) return event;
      }
      break;
    }
  }

  // No next event today — find the first event in any future day
  for (final planning in sorted) {
    if (!SaudiTime.dayOf(planning.date).isAfter(currentEventDay)) continue;
    final sortedEvents = sortPlanningEventsByTime(planning.evenements);
    for (final event in sortedEvents) {
      if (!event.isResolved) return event;
    }
  }

  return null;
}
List<MobilePlanningDay> expandPlanningDaysInRange(
  List<MobilePlanningDay> plannings, {
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final normalizedStart = SaudiTime.dayOf(rangeStart);
  final normalizedEnd = SaudiTime.dayOf(rangeEnd);
  if (normalizedEnd.isBefore(normalizedStart)) {
    return sortPlanningDaysByDate(plannings);
  }

  final sortedPlannings = sortPlanningDaysByDate(plannings);
  final planningByDayKey = <String, MobilePlanningDay>{
    for (final planning in sortedPlannings)
      _planningDayKey(planning.date): planning,
  };

  final expandedDays = <MobilePlanningDay>[];
  var cursor = normalizedStart;
  while (!cursor.isAfter(normalizedEnd)) {
    final key = _planningDayKey(cursor);
    expandedDays.add(
      planningByDayKey[key] ??
          MobilePlanningDay(
            id: 'virtual-$key',
            date: cursor,
            titre: null,
            evenements: const [],
          ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }

  return expandedDays;
}

List<MobilePlanningDay> expandPlanningDaysForPlanningView({
  required List<MobilePlanningDay> plannings,
  required DateTime referenceDay,
  required DateTime? tripStart,
  required DateTime? tripEnd,
  required bool fullTrip,
  required int daysBefore,
  required int daysAfter,
}) {
  final normalizedReferenceDay = SaudiTime.dayOf(referenceDay);

  if (fullTrip) {
    if (tripStart == null || tripEnd == null) {
      return sortPlanningDaysByDate(plannings);
    }
    return expandPlanningDaysInRange(
      plannings,
      rangeStart: tripStart,
      rangeEnd: tripEnd,
    );
  }

  var windowStart = normalizedReferenceDay.subtract(Duration(days: daysBefore));
  var windowEnd = normalizedReferenceDay.add(Duration(days: daysAfter));

  if (tripStart != null) {
    final normalizedTripStart = SaudiTime.dayOf(tripStart);
    if (windowStart.isBefore(normalizedTripStart)) {
      windowStart = normalizedTripStart;
    }
  }

  if (tripEnd != null) {
    final normalizedTripEnd = SaudiTime.dayOf(tripEnd);
    if (windowEnd.isAfter(normalizedTripEnd)) {
      windowEnd = normalizedTripEnd;
    }
  }

  return expandPlanningDaysInRange(
    plannings,
    rangeStart: windowStart,
    rangeEnd: windowEnd,
  );
}

String _planningDayKey(DateTime value) {
  final day = SaudiTime.dayOf(value);
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}
