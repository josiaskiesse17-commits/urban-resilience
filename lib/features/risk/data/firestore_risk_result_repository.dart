import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/risk_result.dart';
import '../domain/risk_result_repository.dart';

class FirestoreRiskResultRepository
    implements RiskResultRepository {
  FirestoreRiskResultRepository({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('risk_results');

  @override
  Future<void> save(RiskResult result) async {
    await _collection.doc(result.id).set(
          result.toJson(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<RiskResult?> get(String riskId) async {
    final document =
        await _collection.doc(riskId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return RiskResult.fromJson(
      document.data()!,
    );
  }

  @override
  Future<RiskResult?> getLatestForZone(
    String zoneId,
  ) async {
    return get(zoneId);
  }
}