import 'sos_alert.dart';

class GuideSosAlert {
  const GuideSosAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.pelerinName,
    required this.type,
    this.message,
    this.pelerinPhone,
    this.groupeId,
    this.groupeNom,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String pelerinName;
  final SosIncidentType type;
  final String? message;
  final String? pelerinPhone;
  final String? groupeId;
  final String? groupeNom;

  factory GuideSosAlert.fromJson(Map<String, dynamic> json) {
    final groupe = json['groupe'];
    return GuideSosAlert(
      id: json['id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      pelerinName: json['pelerinName'] as String? ?? 'Pelerin',
      type: SosIncidentType.fromApi(json['type'] as String?),
      message: json['message'] as String?,
      pelerinPhone: json['pelerinPhone'] as String?,
      groupeId: groupe is Map<String, dynamic> ? groupe['id'] as String? : null,
      groupeNom: groupe is Map<String, dynamic> ? groupe['nom'] as String? : null,
    );
  }
}
