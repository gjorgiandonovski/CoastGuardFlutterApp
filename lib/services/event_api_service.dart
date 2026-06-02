import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/beach.dart';
import '../models/event.dart';

class EventApiService {
  EventApiService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Event>> watchUpcomingEvents() {
    return _firestore
        .collection('events')
        .orderBy('dateEpochMs')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Event.fromDocument).toList(growable: false);
        });
  }

  Future<void> createCleanupEvent({
    required User user,
    required Beach beach,
    required String title,
    required DateTime date,
    required int maxParticipants,
  }) async {
    final now = DateTime.now();
    final eventRef = _firestore.collection('events').doc();
    final userRef = _firestore.collection('users').doc(user.uid);
    final notificationRef = _firestore.collection('notifications').doc();

    final batch = _firestore.batch();
    batch.set(eventRef, {
      'title': title,
      'type': 'cleanup',
      'beachId': beach.id,
      'beach': beach.name,
      'dateEpochMs': date.millisecondsSinceEpoch,
      'maxParticipants': maxParticipants,
      'participantCount': 1,
      'participantIds': [user.uid],
      'status': 'SCHEDULED',
      'createdBy': user.uid,
      'createdByEmail': user.email,
      'createdAt': Timestamp.fromDate(now),
      'createdAtEpochMs': now.millisecondsSinceEpoch,
    });

    batch.set(userRef, {
      'points': FieldValue.increment(150),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(notificationRef, {
      'userId': user.uid,
      'title': 'Cleanup event published',
      'message': 'Your event at ${beach.name} is live. You earned 150 points.',
      'type': 'event',
      'isRead': false,
      'eventId': eventRef.id,
      'createdAt': Timestamp.fromDate(now),
      'createdAtEpochMs': now.millisecondsSinceEpoch,
    });

    await batch.commit();
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String beachId,
    required String beachName,
    required DateTime date,
    required int maxParticipants,
  }) async {
    await _firestore.collection('events').doc(eventId).update({
      'title': title,
      'beachId': beachId,
      'beach': beachName,
      'dateEpochMs': date.millisecondsSinceEpoch,
      'maxParticipants': maxParticipants,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
}
