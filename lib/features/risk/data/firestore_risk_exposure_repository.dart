import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/flood_risk_exposure_profile.dart';
import '../domain/risk_exposure_repository.dart';

class FirestoreRiskExposureRepository implements RiskExposureRepository {
  FirestoreRiskExposureRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('risk_zones');

  @override
  Future<FloodRiskExposureProfile?> getProfile(String zoneId) async {
    final document = await _collection.doc(zoneId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return FloodRiskExposureProfile.fromJson(document.data()!);
  }

  @override
  Future<void> saveProfile(
    FloodRiskExposureProfile profile,
  ) async {
    await _collection.doc(profile.zoneId).set(
          profile.toJson(),
          SetOptions(merge: true),
        );
  }
}