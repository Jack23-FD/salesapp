import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_screen.dart';

class NotificationIcon extends StatelessWidget {
  final Color iconColor;
  final double iconSize;
  final bool useContainerBackground;
  
  const NotificationIcon({
    super.key, 
    this.iconColor = const Color(0xFF1F1F1F),
    this.iconSize = 20,
    this.useContainerBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        useContainerBackground 
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                child: Icon(
                  Icons.notifications_outlined,
                  size: iconSize,
                  color: iconColor,
                ),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              color: iconColor,
            ),
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.hasUnreadNotifications) {
              return Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    notificationProvider.unreadCount > 9
                        ? '9+'
                        : notificationProvider.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }
} 