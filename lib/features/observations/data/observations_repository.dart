import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  Stream<List<Observation>> watchMine(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
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

    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }

    final reference = _collection.doc();

    final observation = Observation(
      id: reference.id,
      userId: user.uid,
      zoneId: zoneId,
      hazardType: hazardType,
      latitude: latitude,
      longitude: longitude,
      type: type,
      description: description.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    await reference.set(observation.toJson());
  }

  Future<void> approve({required String id, required String reviewerId}) {
    return _collection.doc(id).update({
      'status': ObservationStatus.confirmed.name,
      'reviewedAt': DateTime.now().toUtc().toIso8601String(),
      'reviewedBy': reviewerId,
    });
  }

  Future<void> delete({required String id}) {
    return _collection.doc(id).delete();
  }

  List<Observation> _mapSnapshots(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final observations = <Observation>[];

    for (final document in snapshot.docs) {
      final data = Map<String, dynamic>.from(document.data());

      data['id'] ??= document.id;

      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        data['createdAt'] = createdAt.toDate().toIso8601String();
      }

      final reviewedAt = data['reviewedAt'];
      if (reviewedAt is Timestamp) {
        data['reviewedAt'] = reviewedAt.toDate().toIso8601String();
      }

      try {
        observations.add(Observation.fromJson(data));
      } catch (error, stackTrace) {
        debugPrint('Observation invalide ignorée [${document.id}]: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    observations.sort(
      (left, right) => right.createdAt.compareTo(left.createdAt),
    );

    return observations;
  }
}
