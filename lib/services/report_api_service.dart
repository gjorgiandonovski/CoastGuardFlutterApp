import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/beach.dart';
import '../models/report.dart';

class ReportApiService {
  ReportApiService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Report>> watchRecentReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAtEpochMs', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Report.fromDocument).toList(growable: false);
        });
  }

  Future<void> submitReport({
    required User user,
    required Beach beach,
    required String category,
    required String severity,
    required String description,
    required bool hasPhoto,
  }) async {
    final now = DateTime.now();
    final reportRef = _firestore.collection('reports').doc();
    final userRef = _firestore.collection('users').doc(user.uid);
    final notificationRef = _firestore.collection('notifications').doc();
    final beachRef = _firestore.collection('beaches').doc(beach.id);

    final batch = _firestore.batch();
    batch.set(reportRef, {
      'beachId': beach.id,
      'beach': beach.name,
      'category': category,
      'severity': severity,
      'description': description.trim(),
      'hasPhoto': hasPhoto,
      'latitude': beach.latitude,
      'longitude': beach.longitude,
      'status': 'UNDER_REVIEW',
      'userId': user.uid,
      'userEmail': user.email,
      'createdAt': Timestamp.fromDate(now),
      'createdAtEpochMs': now.millisecondsSinceEpoch,
    });

    batch.set(beachRef, {
      'reportTypes': FieldValue.arrayUnion([category]),
      'reportCount': FieldValue.increment(1),
      'latestIssueSeverity': severity,
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'email': user.email,
      'points': FieldValue.increment(100),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(notificationRef, {
      'userId': user.uid,
      'title': 'Report submitted',
      'message':
          'Your report for ${beach.name} is under review. You earned 100 points.',
      'type': 'report',
      'isRead': false,
      'reportId': reportRef.id,
      'createdAt': Timestamp.fromDate(now),
      'createdAtEpochMs': now.millisecondsSinceEpoch,
    });

    await batch.commit();
  }
}
