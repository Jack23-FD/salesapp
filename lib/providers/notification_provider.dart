import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../models/item.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  bool _hasUnreadNotifications = false;

  List<NotificationItem> get notifications => _notifications;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void addNotification(NotificationItem notification) {
    // Check if a similar notification already exists
    final existingNotification = _notifications.firstWhere(
      (n) =>
          n.actionId == notification.actionId &&
          n.actionType == notification.actionType,
      orElse: () => NotificationItem(
        id: '',
        title: '',
        message: '',
        timestamp: DateTime.now(),
      ),
    );

    if (existingNotification.id.isEmpty) {
      _notifications.add(notification);
      if (!notification.isRead) {
        _hasUnreadNotifications = true;
      }
      notifyListeners();
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications
        .indexWhere((notification) => notification.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timestamp: notification.timestamp,
        isRead: true,
        actionType: notification.actionType,
        actionId: notification.actionId,
      );

      _updateUnreadStatus();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      _notifications[i] = NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        timestamp: notification.timestamp,
        isRead: true,
        actionType: notification.actionType,
        actionId: notification.actionId,
      );
    }

    _hasUnreadNotifications = false;
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications
        .removeWhere((notification) => notification.id == notificationId);
    _updateUnreadStatus();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  void _updateUnreadStatus() {
    _hasUnreadNotifications =
        _notifications.any((notification) => !notification.isRead);
  }

  // Check stock levels and create notifications
  void checkStockLevels(List<Item> items) {
    for (final item in items) {
      // Check for out of stock first
      if (item.quantity <= 0) {
        addNotification(
          NotificationItem(
            id: 'out_of_stock_${item.id}',
            title: 'Out of Stock Alert',
            message:
                '${item.name} is out of stock (${item.quantity} ${item.unit}).',
            timestamp: DateTime.now(),
            actionType: 'item',
            actionId: item.id,
          ),
        );
      }
      // Only check for low stock if the item is not out of stock and has a minimum level set
      else if (item.minLevel != null && item.quantity <= item.minLevel!) {
        addNotification(
          NotificationItem(
            id: 'low_stock_${item.id}',
            title: 'Low Stock Alert',
            message:
                '${item.name} is running low on stock (${item.quantity} ${item.unit} remaining, minimum level: ${item.minLevel} ${item.unit}).',
            timestamp: DateTime.now(),
            actionType: 'item',
            actionId: item.id,
          ),
        );
      }
    }
  }
}
