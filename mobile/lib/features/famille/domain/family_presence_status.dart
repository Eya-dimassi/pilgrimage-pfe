class FamilyPresenceStatus {
  const FamilyPresenceStatus({
    required this.pelerinId,
    required this.statusForFamily,
    this.note,
    this.activeAppelId,
  });

  final String pelerinId;
  final String statusForFamily; // PRESENT | ABSENT | EXCUSE
  final String? note;
  final String? activeAppelId;

  factory FamilyPresenceStatus.fromJson(Map<String, dynamic> json) {
    final raw = (json['statusForFamily'] as String? ?? 'PRESENT').trim();
    final normalized = raw == 'ABSENT' || raw == 'EXCUSE' ? raw : 'PRESENT';

    return FamilyPresenceStatus(
      pelerinId: json['pelerinId'] as String? ?? '',
      statusForFamily: normalized,
      note: json['note'] as String?,
      activeAppelId: json['activeAppelId'] as String?,
    );
  }

  bool get isPresent => statusForFamily == 'PRESENT';
  bool get isAbsent => statusForFamily == 'ABSENT';
  bool get isExcuse => statusForFamily == 'EXCUSE';
}
