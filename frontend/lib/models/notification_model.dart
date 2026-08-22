/// Represents an in-app notification.
///
/// TODO: Sync field names with backend `/notifications` endpoint.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type = NotificationType.info,
    this.isRead = false,
    this.actionRoute,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationType type;
  final bool isRead;
  final String? actionRoute;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.info,
      ),
      isRead: json['isRead'] as bool? ?? false,
      actionRoute: json['actionRoute'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      type: type,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
    );
  }
}

enum NotificationType { sos, journey, community, safety, info }

extension NotificationTypeExtension on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.sos:
        return 'SOS';
      case NotificationType.journey:
        return 'Journey';
      case NotificationType.community:
        return 'Community';
      case NotificationType.safety:
        return 'Safety';
      case NotificationType.info:
        return 'Info';
    }
  }
}
