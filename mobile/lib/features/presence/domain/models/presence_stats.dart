class PresenceStats {
  const PresenceStats({
    required this.total,
    required this.presents,
    required this.absents,
    required this.excuses,
    required this.enAttente,
  });

  final int total;
  final int presents;
  final int absents;
  final int excuses;
  final int enAttente;

  factory PresenceStats.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PresenceStats(
      total: parseInt(json['total']),
      presents: parseInt(json['presents']),
      absents: parseInt(json['absents']),
      excuses: parseInt(json['excuses']),
      enAttente: parseInt(json['enAttente']),
    );
  }

  int get tauxPresence => total > 0 ? ((presents / total) * 100).round() : 0;
}
