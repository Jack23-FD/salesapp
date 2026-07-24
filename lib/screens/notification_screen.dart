import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';
import '../providers/item_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);

    // Check stock levels when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allItems = itemProvider.getAllItems();
      notificationProvider.checkStockLevels(allItems);
    });

    final notifications = notificationProvider.notifications;
    final hasNotifications = notifications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: hasNotifications
            ? [
                TextButton(
                  onPressed: () {
                    notificationProvider.markAllAsRead();
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: const Color(0xFF00BBF9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: hasNotifications
          ? ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    notificationProvider.deleteNotification(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification deleted'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: NotificationItemWidget(
                    notification: notification,
                    onTap: () {
                      notificationProvider.markAsRead(notification.id);
                      // Handle notification tap based on action type
                      if (notification.actionType == 'item') {
                        // Navigate to the item details screen
                        // This would be implemented based on your app's navigation needs
                      }
                    },
                  ),
                );
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Empty notification bell icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BBF9),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Bell shape
                        Icon(
                          Icons.notifications_outlined,
                          size: 60,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        // Number 0 badge
                        Positioned(
                          right: 35,
                          top: 40,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '0',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Indicator bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BBF9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // No notifications text
                  const Text(
                    'No Notifications Yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Subtitle text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'You will receive notifications about low stock, out of stock items, and other important updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Widget to display notification items when they exist
class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF5F5FF),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: const Color(0xFF00BBF9),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: const Color(0xFF00BBF9),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
