import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/firestore_risk_exposure_repository.dart';
import '../../domain/flood_risk_input_exposure_enricher.dart';
import '../../domain/risk_exposure_repository.dart';
import '../../domain/risk_intelligence_service.dart';

final riskExposureRepositoryProvider =
    Provider<RiskExposureRepository>((ref) {
  return FirestoreRiskExposureRepository(
    firestore: FirebaseFirestore.instance,
  );
});

final floodRiskInputExposureEnricherProvider =
    Provider<FloodRiskInputExposureEnricher>((ref) {
  return FloodRiskInputExposureEnricher(
    repository: ref.read(
      riskExposureRepositoryProvider,
    ),
  );
});

final riskIntelligenceServiceProvider =
    Provider<RiskIntelligenceService>((ref) {
  return RiskIntelligenceService(
    exposureEnricher: ref.read(
      floodRiskInputExposureEnricherProvider,
    ),
  );
});