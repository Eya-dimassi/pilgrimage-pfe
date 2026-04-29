class GuideSosAlert {
  const GuideSosAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.pelerinName,
    this.message,
    this.groupeId,
    this.groupeNom,
  });

  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String pelerinName;
  final String? message;
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
      message: json['message'] as String?,
      groupeId: groupe is Map<String, dynamic> ? groupe['id'] as String? : null,
      groupeNom: groupe is Map<String, dynamic> ? groupe['nom'] as String? : null,
    );
  }
}
