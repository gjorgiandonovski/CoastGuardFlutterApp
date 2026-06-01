import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_api_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  static final NotificationApiService _notificationApiService =
      NotificationApiService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationApiService.watchUserNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? const <AppNotification>[];
          if (notifications.isEmpty) return const Center(child: Text('No alerts found.'));

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: notification.isRead ? Colors.grey : Colors.red,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: Text(notification.type),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
