import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  IconData getIcon() {
    switch (notification.type) {
      case "offer":
        return Icons.local_offer;
      case "progress":
        return Icons.handyman;
      case "done":
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  Color getColor() {
    switch (notification.type) {
      case "offer":
        return Colors.green;
      case "progress":
        return Colors.orange;
      case "done":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xffE5E7EB),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),

        leading: CircleAvatar(
          backgroundColor: getColor().withOpacity(0.15),
          child: Icon(
            getIcon(),
            color: getColor(),
          ),
        ),

        title: Text(
          notification.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(notification.message),
        ),

        trailing: Text(
          notification.time,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}