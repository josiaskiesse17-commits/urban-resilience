import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore_risk_exposure_repository.dart';
import '../../domain/flood_risk_exposure_profile.dart';
import '../../domain/risk_exposure_repository.dart';

final riskExposureRepositoryProvider =
    Provider<RiskExposureRepository>((ref) {
  return FirestoreRiskExposureRepository(
    firestore: FirebaseFirestore.instance,
  );
});

final riskExposureProfileProvider = FutureProvider.family<
    FloodRiskExposureProfile?,
    String>((ref, zoneId) async {
  final repository = ref.read(riskExposureRepositoryProvider);

  return repository.getProfile(zoneId);
});