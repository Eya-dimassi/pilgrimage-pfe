import 'pelerin_info.dart';

class ConfirmationPresence {
  const ConfirmationPresence({
    required this.id,
    required this.appelPresenceId,
    required this.pelerinId,
    required this.statut,
    this.confirmeAt,
    this.confirmeMode,
    this.note,
    required this.pelerin,
  });

  final String id;
  final String appelPresenceId;
  final String pelerinId;
  final String statut; // EN_ATTENTE, PRESENT, ABSENT, EXCUSE
  final DateTime? confirmeAt;
  final String? confirmeMode;
  final String? note;
  final PelerinInfo pelerin;

  factory ConfirmationPresence.fromJson(Map<String, dynamic> json) {
    return ConfirmationPresence(
      id: json['id'] as String? ?? '',
      appelPresenceId: json['appelPresenceId'] as String? ?? '',
      pelerinId: json['pelerinId'] as String? ?? '',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      confirmeAt: json['confirmeAt'] is String
          ? DateTime.tryParse(json['confirmeAt'] as String)
          : null,
      confirmeMode: json['confirmeMode'] as String?,
      note: json['note'] as String?,
      pelerin: PelerinInfo.fromJson(
        (json['pelerin'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  bool get isPresent => statut == 'PRESENT';
  bool get isAbsent => statut == 'ABSENT';
  bool get isExcuse => statut == 'EXCUSE';
  bool get isEnAttente => statut == 'EN_ATTENTE';
}
