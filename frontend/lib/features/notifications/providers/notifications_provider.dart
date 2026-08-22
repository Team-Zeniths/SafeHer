import 'package:flutter/material.dart';
import '../../../models/notification_model.dart';

enum NotificationsStatus { idle, loading, loaded, error }

/// Manages in-app notification state.
///
/// Currently starts empty — real notifications will be populated
/// via FCM push or a backend /notifications/ endpoint when that
/// feature is implemented.
class NotificationsProvider extends ChangeNotifier {
  NotificationsStatus _status = NotificationsStatus.idle;
  List<NotificationModel> _notifications = [];
  String? _errorMessage;
  NotificationType? _activeFilter;

  NotificationsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  NotificationType? get activeFilter => _activeFilter;

  /// Number of unread notifications — drives the badge on the home screen bell.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationModel> get notifications {
    if (_activeFilter == null) return _notifications;
    return _notifications.where((n) => n.type == _activeFilter).toList();
  }

  void setFilter(NotificationType? type) {
    _activeFilter = type;
    notifyListeners();
  }

  /// Loads notifications. Currently resolves to an empty list.
  ///
  /// Wire to GET /notifications/ when the backend endpoint is ready.
  Future<void> loadNotifications() async {
    if (_status == NotificationsStatus.loading) return;
    _status = NotificationsStatus.loading;
    notifyListeners();
    try {
      // No backend endpoint yet — start with an empty list.
      // Replace with: final response = await ApiService.instance.get('notifications/');
      _notifications = [];
      _status = NotificationsStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotificationsStatus.error;
    }
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
      // TODO: PATCH /notifications/{id}/read/
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    // TODO: POST /notifications/mark-all-read/
  }

  /// Adds a notification programmatically (e.g. from an FCM push handler).
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
