import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/observation.dart';

class ObservationsRepository {
  ObservationsRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('observations');

  Stream<List<Observation>> watchForContext({
    required String zoneId,
    required String hazardType,
  }) {
    return _collection
        .where('zoneId', isEqualTo: zoneId)
        .where('hazardType', isEqualTo: hazardType)
        .where('status', isEqualTo: ObservationStatus.confirmed.name)
        .snapshots()
        .map(_mapSnapshots);
  }

  Stream<List<Observation>> watchPending() {
    return _collection
        .where('status', isEqualTo: ObservationStatus.pending.name)
        .snapshots()
        .map(_mapSnapshots);
  }

  Future<void> create({
    required String zoneId,
    required String hazardType,
    required double latitude,
    required double longitude,
    required ObservationType type,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Utilisateur non connecté');

    final reference = _collection.doc();
    final observation = Observation(
      id: reference.id,
      userId: user.uid,
      zoneId: zoneId,
      hazardType: hazardType,
      latitude: latitude,
      longitude: longitude,
      type: type,
      description: description,
      createdAt: DateTime.now().toUtc(),
    );
    await reference.set(observation.toJson());
  }

  Future<void> setStatus(String id, ObservationStatus status) {
    return _collection.doc(id).update({'status': status.name});
  }

  List<Observation> _mapSnapshots(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final observations = snapshot.docs.map((document) {
      final data = document.data();
      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        data['createdAt'] = createdAt.toDate().toIso8601String();
      }
      return Observation.fromJson(data);
    }).toList();

    observations.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );

    return observations;
  }
}
