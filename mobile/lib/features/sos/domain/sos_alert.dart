import 'package:easy_localization/easy_localization.dart';

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
        return 'sos.types.maladie.label'.tr();
      case SosIncidentType.perte:
        return 'sos.types.perte.label'.tr();
      case SosIncidentType.logistique:
        return 'sos.types.logistique.label'.tr();
      case SosIncidentType.autre:
        return 'sos.types.autre.label'.tr();
    }
  }

  String get description {
    switch (this) {
      case SosIncidentType.maladie:
        return 'sos.types.maladie.description'.tr();
      case SosIncidentType.perte:
        return 'sos.types.perte.description'.tr();
      case SosIncidentType.logistique:
        return 'sos.types.logistique.description'.tr();
      case SosIncidentType.autre:
        return 'sos.types.autre.description'.tr();
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
    final incidents = json['incidents'];
    final incidentType =
        incidents is List && incidents.isNotEmpty && incidents.first is Map
            ? (incidents.first as Map)['type'] as String?
            : null;

    return SosAlert(
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      status: json['statut'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      type: SosIncidentType.fromApi(
        (json['type'] ?? json['incidentType'] ?? incidentType) as String?,
      ),
      message: json['message'] as String?,
      resolvedAt: json['resolueAt'] is String
          ? DateTime.tryParse(json['resolueAt'] as String)
          : null,
    );
  }
}
