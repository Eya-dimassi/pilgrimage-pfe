enum SosIncidentType {
  maladie('MALADIE'),
  perte('PERTE'),
  logistique('LOGISTIQUE'),
  autre('AUTRE');

  const SosIncidentType(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case SosIncidentType.maladie:
        return 'Maladie';
      case SosIncidentType.perte:
        return 'Perte';
      case SosIncidentType.logistique:
        return 'Logistique';
      case SosIncidentType.autre:
        return 'Autre';
    }
  }

  String get description {
    switch (this) {
      case SosIncidentType.maladie:
        return 'Probleme de sante';
      case SosIncidentType.perte:
        return 'Je suis perdu';
      case SosIncidentType.logistique:
        return 'Transport ou organisation';
      case SosIncidentType.autre:
        return 'Autre situation';
    }
  }

  static SosIncidentType fromApi(String? value) {
    for (final type in SosIncidentType.values) {
      if (type.apiValue == value) {
        return type;
      }
    }
    return SosIncidentType.autre;
  }
}

class SosAlert {
  const SosAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.type,
    this.message,
    this.resolvedAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
  final SosIncidentType type;
  final String? message;
  final DateTime? resolvedAt;

  bool get isActive => status == 'EN_COURS';

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: json['statut'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      type: SosIncidentType.fromApi(
        json['type'] as String?,
      ),
      message: json['message'] as String?,
      resolvedAt: json['resolueAt'] is String
          ? DateTime.tryParse(json['resolueAt'] as String)
          : null,
    );
  }
}
