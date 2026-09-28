import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/firestore_risk_exposure_repository.dart';
import '../../data/firestore_risk_result_repository.dart';
import '../../data/open_meteo_historical_flood_data_source.dart';
import '../../data/open_meteo_risk_data_source.dart';
import '../../domain/flood_environmental_data_source.dart';
import '../../domain/flood_risk_input_exposure_enricher.dart';
import '../../domain/historical_flood_baseline_service.dart';
import '../../domain/historical_flood_data_source.dart';
import '../../domain/live_flood_risk_service.dart';
import '../../domain/risk_exposure_repository.dart';
import '../../domain/risk_intelligence_service.dart';
import '../../domain/risk_result.dart';
import '../../domain/risk_result_repository.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();

  ref.onDispose(client.close);

  return client;
});

final riskExposureRepositoryProvider =
    Provider<RiskExposureRepository>((ref) {
  return FirestoreRiskExposureRepository(
    firestore: FirebaseFirestore.instance,
  );
});

final riskExposureEnricherProvider =
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
      riskExposureEnricherProvider,
    ),
  );
});

final floodEnvironmentalDataSourceProvider =
    Provider<FloodEnvironmentalDataSource>((ref) {
  return OpenMeteoRiskDataSource(
    client: ref.read(httpClientProvider),
  );
});

final historicalFloodDataSourceProvider =
    Provider<HistoricalFloodDataSource>((ref) {
  return OpenMeteoHistoricalFloodDataSource(
    client: ref.read(httpClientProvider),
  );
});

final historicalFloodBaselineServiceProvider =
    Provider<HistoricalFloodBaselineService>((ref) {
  return HistoricalFloodBaselineService(
    dataSource: ref.read(
      historicalFloodDataSourceProvider,
    ),
  );
});

final riskResultRepositoryProvider =
    Provider<RiskResultRepository>((ref) {
  return FirestoreRiskResultRepository(
    firestore: FirebaseFirestore.instance,
  );
});

final liveFloodRiskServiceProvider =
    Provider<LiveFloodRiskService>((ref) {
  return LiveFloodRiskService(
    dataSource: ref.read(
      floodEnvironmentalDataSourceProvider,
    ),
    riskIntelligenceService: ref.read(
      riskIntelligenceServiceProvider,
    ),
    riskResultRepository: ref.read(
      riskResultRepositoryProvider,
    ),
    historicalBaselineService: ref.read(
      historicalFloodBaselineServiceProvider,
    ),
  );
});

final riskResultProvider =
    FutureProvider.family<RiskResult?, String>(
  (ref, riskId) async {
    final repository =
        ref.read(riskResultRepositoryProvider);

    return repository.get(riskId);
  },
);