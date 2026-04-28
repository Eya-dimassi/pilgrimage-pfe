class MobileNotificationFeed {
  const MobileNotificationFeed({
    required this.items,
    required this.unreadCount,
  });

  final List<MobileNotificationItem> items;
  final int unreadCount;

  const MobileNotificationFeed.empty()
      : items = const [],
        unreadCount = 0;

  factory MobileNotificationFeed.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MobileNotificationItem.fromJson)
        .toList();

    return MobileNotificationFeed(
      items: items,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}

class MobileNotificationItem {
  const MobileNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.tab,
    this.groupeId,
    this.eventId,
    this.etape,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String? type;
  final String? tab;
  final String? groupeId;
  final String? eventId;
  final String? etape;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  factory MobileNotificationItem.fromJson(Map<String, dynamic> json) {
    return MobileNotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String?,
      tab: json['tab'] as String?,
      groupeId: json['groupeId'] as String?,
      eventId: json['eventId'] as String?,
      etape: json['etape'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] is String
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }
}
