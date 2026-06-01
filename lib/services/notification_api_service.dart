import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';

class NotificationApiService {
  NotificationApiService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAtEpochMs', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(AppNotification.fromDocument)
              .toList(growable: false);
        });
  }

  Future<void> markAsRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}
