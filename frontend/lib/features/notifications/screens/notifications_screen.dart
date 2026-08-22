import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../providers/notifications_provider.dart';
import '../../../models/notification_model.dart';

/// Notification center screen.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationsProvider>();
    final unread = np.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.sosRed, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: np.markAllAsRead,
              child: const Text('Mark all read', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 6),
              children: [
                _Chip(label: 'All', selected: np.activeFilter == null, onTap: () => np.setFilter(null), color: AppColors.primary),
                const SizedBox(width: AppSizes.sm),
                ...NotificationType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: AppSizes.sm),
                      child: _Chip(label: t.label, selected: np.activeFilter == t, onTap: () => np.setFilter(t), color: _typeColor(t)),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: np.status == NotificationsStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : np.status == NotificationsStatus.error
                    ? ErrorStateWidget(onRetry: np.loadNotifications)
                    : np.notifications.isEmpty
                        ? const EmptyStateWidget(
                            icon: Icons.notifications_none_rounded,
                            title: 'No notifications',
                            subtitle: 'You\'re all caught up!',
                            iconColor: AppColors.primary,
                          )
                        : ListView.separated(
                            itemCount: np.notifications.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                            itemBuilder: (context, i) => _NotificationTile(
                              notification: np.notifications[i],
                              onTap: () => np.markAsRead(np.notifications[i].id),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(NotificationType t) {
    switch (t) {
      case NotificationType.sos:
        return AppColors.sosRed;
      case NotificationType.journey:
        return AppColors.info;
      case NotificationType.community:
        return AppColors.success;
      case NotificationType.safety:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, required this.color});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: selected ? color : AppColors.lightOutline),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? color : AppColors.textMutedLight, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 13),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final NotificationModel notification;
  final VoidCallback onTap;

  Color _color() {
    switch (notification.type) {
      case NotificationType.sos:
        return AppColors.sosRed;
      case NotificationType.journey:
        return AppColors.info;
      case NotificationType.community:
        return AppColors.success;
      case NotificationType.safety:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.sos:
        return Icons.sos_rounded;
      case NotificationType.journey:
        return Icons.route_rounded;
      case NotificationType.community:
        return Icons.people_rounded;
      case NotificationType.safety:
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color();

    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : (isDark ? AppColors.primary.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.03)),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(_icon(), color: color, size: 22),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 14),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notification.body, style: TextStyle(color: AppColors.textMutedLight, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(_timeAgo(notification.createdAt), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
