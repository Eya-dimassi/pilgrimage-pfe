class SosAlert {
  const SosAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.message,
    this.resolvedAt,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime createdAt;
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
      message: json['message'] as String?,
      resolvedAt: json['resolueAt'] is String
          ? DateTime.tryParse(json['resolueAt'] as String)
          : null,
    );
  }
}
