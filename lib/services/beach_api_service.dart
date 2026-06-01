import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/beach.dart';

class BeachApiService {
  BeachApiService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Beach>> watchBeaches() {
    return _firestore.collection('beaches').snapshots().map((snapshot) {
      return snapshot.docs.map(Beach.fromDocument).toList(growable: false);
    });
  }

  Future<Beach?> getBeachById(String id) async {
    final snapshot = await _firestore.collection('beaches').doc(id).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return Beach.fromMap(snapshot.id, data);
  }
}
