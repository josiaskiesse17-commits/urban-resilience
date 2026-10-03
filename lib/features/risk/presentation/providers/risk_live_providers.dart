import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../data/firestore_risk_exposure_repository.dart';
import '../../data/firestore_risk_result_repository.dart';
import '../../data/open_meteo_hazard_data_source.dart';
import '../../data/open_meteo_hazard_historical_data_source.dart';
import '../../data/open_meteo_historical_flood_data_source.dart';
import '../../data/open_meteo_risk_data_source.dart';
import '../../data/risk_repository.dart';
import '../../domain/flood_environmental_data_source.dart';
import '../../domain/flood_risk_exposure_profile.dart';
import '../../domain/flood_risk_input_exposure_enricher.dart';
import '../../domain/hazard_environmental_data_source.dart';
import '../../domain/hazard_historical_data_source.dart';
import '../../domain/hazard_risk_id.dart';
import '../../domain/hazard_risk_service.dart';
import '../../domain/hazard_type.dart';
import '../../domain/historical_flood_baseline_service.dart';
import '../../domain/historical_flood_data_source.dart';
import '../../domain/live_flood_risk_service.dart';
import '../../domain/risk_exposure_repository.dart';
import '../../domain/risk_intelligence_service.dart';
import '../../domain/risk_result.dart';
import '../../domain/risk_result_repository.dart';
import '../../domain/zone_active_risk.dart';
import '../../../observations/domain/observation.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();

  ref.onDispose(client.close);

  return client;
});

final riskExposureRepositoryProvider = Provider<RiskExposureRepository>((ref) {
  return FirestoreRiskExposureRepository(firestore: FirebaseFirestore.instance);
});

final riskExposureEnricherProvider = Provider<FloodRiskInputExposureEnricher>((
  ref,
) {
  return FloodRiskInputExposureEnricher(
    repository: ref.read(riskExposureRepositoryProvider),
  );
});

final riskIntelligenceServiceProvider = Provider<RiskIntelligenceService>((
  ref,
) {
  return RiskIntelligenceService(
    exposureEnricher: ref.read(riskExposureEnricherProvider),
  );
});

final floodEnvironmentalDataSourceProvider =
    Provider<FloodEnvironmentalDataSource>((ref) {
      return OpenMeteoRiskDataSource(client: ref.read(httpClientProvider));
    });

final hazardEnvironmentalDataSourceProvider =
    Provider<HazardEnvironmentalDataSource>((ref) {
      return OpenMeteoHazardDataSource(client: ref.read(httpClientProvider));
    });

final hazardHistoricalDataSourceProvider = Provider<HazardHistoricalDataSource>(
  (ref) {
    return OpenMeteoHazardHistoricalDataSource(
      client: ref.read(httpClientProvider),
    );
  },
);

final historicalFloodDataSourceProvider = Provider<HistoricalFloodDataSource>((
  ref,
) {
  return OpenMeteoHistoricalFloodDataSource(
    client: ref.read(httpClientProvider),
  );
});

final historicalFloodBaselineServiceProvider =
    Provider<HistoricalFloodBaselineService>((ref) {
      return HistoricalFloodBaselineService(
        dataSource: ref.read(historicalFloodDataSourceProvider),
      );
    });

final riskResultRepositoryProvider = Provider<RiskResultRepository>((ref) {
  return FirestoreRiskResultRepository(firestore: FirebaseFirestore.instance);
});

final liveFloodRiskServiceProvider = Provider<LiveFloodRiskService>((ref) {
  return LiveFloodRiskService(
    dataSource: ref.read(floodEnvironmentalDataSourceProvider),
    riskIntelligenceService: ref.read(riskIntelligenceServiceProvider),
    riskResultRepository: ref.read(riskResultRepositoryProvider),
    historicalBaselineService: ref.read(historicalFloodBaselineServiceProvider),
  );
});

final hazardRiskServiceProvider = Provider<HazardRiskService>((ref) {
  return HazardRiskService(
    liveDataSource: ref.read(hazardEnvironmentalDataSourceProvider),
    historicalDataSource: ref.read(hazardHistoricalDataSourceProvider),
    referencePeriodStart: RiskZoneCatalog.historicalBaselineStart,
    referencePeriodEnd: RiskZoneCatalog.historicalBaselineEnd,
    exposureRepository: ref.read(riskExposureRepositoryProvider),
    riskResultRepository: ref.read(riskResultRepositoryProvider),
    riskIntelligenceService: ref.read(riskIntelligenceServiceProvider),
  );
});

final riskResultProvider = FutureProvider.family<RiskResult?, String>((
  ref,
  riskId,
) async {
  final repository = ref.read(riskResultRepositoryProvider);

  return repository.get(riskId);
});

final riskZoneCatalogProvider = Provider<List<RiskZoneTarget>>((ref) {
  return RiskZoneCatalog.zones;
});

final riskExposureProfileProvider =
    FutureProvider.family<FloodRiskExposureProfile?, String>((
      ref,
      zoneId,
    ) async {
      final repository = ref.read(riskExposureRepositoryProvider);

      return repository.getProfile(zoneId);
    });

final zoneHazardAssessmentsProvider = FutureProvider.autoDispose
    .family<List<ZoneHazardAssessment>, String>((ref, zoneId) async {
      final repository = ref.watch(riskResultRepositoryProvider);

      final storedByHazard = Map.fromEntries(
        await Future.wait(
          HazardType.values.map(
            (hazard) => repository
                .get(HazardRiskId.forZone(zoneId: zoneId, hazard: hazard))
                .then((result) => MapEntry(hazard, result)),
          ),
        ),
      );

      return zoneHazardAssessmentsFrom(zoneId, storedByHazard);
    });

final zoneActiveRisksProvider = Provider.autoDispose
    .family<List<ZoneActiveRisk>, String>((ref, zoneId) {
      final assessments = ref.watch(zoneHazardAssessmentsProvider(zoneId));

      return assessments.maybeWhen(
        data: identifiedRisksOf,
        orElse: () => const <ZoneActiveRisk>[],
      );
    });

typedef ZoneHazardRiskGenerator = Future<RiskResult> Function(
  RiskZoneTarget zone,
  HazardType hazard,
);

typedef ZoneRiskGenerator = Future<RiskResult> Function(RiskZoneTarget zone);

final zoneHazardRiskGeneratorProvider = Provider<ZoneHazardRiskGenerator>((
  ref,
) {
  final floodService = ref.watch(liveFloodRiskServiceProvider);
  final hazardService = ref.watch(hazardRiskServiceProvider);

  return (zone, hazard) {
    if (hazard == HazardType.flooding) {
      return floodService.calculateLiveRiskAndSave(
        id: zone.id,
        zoneId: zone.id,
        locationName: zone.name,
        latitude: zone.latitude,
        longitude: zone.longitude,
        startDate: RiskZoneCatalog.historicalBaselineStart,
        endDate: RiskZoneCatalog.historicalBaselineEnd,
        observations: const <Observation>[],
      );
    }

    return hazardService.calculateAndSave(
      zoneId: zone.id,
      locationName: zone.name,
      latitude: zone.latitude,
      longitude: zone.longitude,
      hazard: hazard,
    );
  };
});

final zoneRiskGeneratorProvider = Provider<ZoneRiskGenerator>((ref) {
  final generator = ref.watch(zoneHazardRiskGeneratorProvider);

  return (zone) => generator(zone, HazardType.flooding);
});
