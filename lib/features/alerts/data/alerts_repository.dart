import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/risk_alert.dart';

class AlertsRepository {
  AlertsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('alerts');

  String newId() => _collection.doc().id;

  Future<void> create(RiskAlert alert) {
    if (alert.expiresAt == null) {
      throw ArgumentError(
        'La date d’expiration est obligatoire pour une alerte.',
      );
    }

    if (!alert.expiresAt!.isAfter(DateTime.now().toUtc())) {
      throw ArgumentError('La date d’expiration doit être dans le futur.');
    }

    return _collection.doc(alert.id).set(alert.toJson());
  }

  Stream<List<RiskAlert>> watchForContext({
    required String zoneId,
    required String hazardType,
  }) {
    late final StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    firestoreSubscription;
    late final Timer expiryTimer;
    final controller = StreamController<List<RiskAlert>>();

    List<RiskAlert> latestAlerts = const [];

    void emitVisibleAlerts() {
      if (!controller.isClosed) {
        controller.add(_visibleOf(latestAlerts));
      }
    }

    firestoreSubscription = _collection
        .where('zoneId', isEqualTo: zoneId)
        .where('hazardType', isEqualTo: hazardType)
        .where('active', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          latestAlerts = _mapSnapshots(snapshot);
          emitVisibleAlerts();
        }, onError: controller.addError);

    expiryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => emitVisibleAlerts(),
    );

    controller.onCancel = () async {
      expiryTimer.cancel();
      await firestoreSubscription.cancel();
    };

    return controller.stream;
  }

   Stream<List<RiskAlert>> watchAll() {
     return _collection.snapshots().map(_mapSnapshots);
   }

  Stream<List<RiskAlert>> watchAllActive() {
    return _collection
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => _visibleOf(_mapSnapshots(snapshot)));
  }

   Future<void> setActive({required String id, required bool active}) {
    return _collection.doc(id).update({'active': active});
  }

  Future<void> delete({required String id}) {
    return _collection.doc(id).delete();
  }

  List<RiskAlert> _visibleOf(List<RiskAlert> alerts) {
    final now = DateTime.now().toUtc();

    return alerts
        .where(
          (alert) =>
              alert.active &&
              alert.expiresAt != null &&
              alert.expiresAt!.isAfter(now),
        )
        .toList();
  }

  List<RiskAlert> _mapSnapshots(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final alerts = snapshot.docs.map((document) {
      final data = Map<String, dynamic>.from(document.data());

      data['id'] ??= document.id;

      final createdAt = data['createdAt'];
      if (createdAt is Timestamp) {
        data['createdAt'] = createdAt.toDate().toIso8601String();
      }

      final expiresAt = data['expiresAt'];
      if (expiresAt is Timestamp) {
        data['expiresAt'] = expiresAt.toDate().toIso8601String();
      }

      return RiskAlert.fromJson(data);
    }).toList();

    alerts.sort((left, right) => right.createdAt.compareTo(left.createdAt));

    return alerts;
  }
}
