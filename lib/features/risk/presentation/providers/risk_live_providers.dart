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
import '../../domain/hazard_risk_service.dart';
import '../../domain/hazard_type.dart';
import '../../domain/historical_flood_baseline_service.dart';
import '../../domain/historical_flood_data_source.dart';
import '../../domain/live_flood_risk_service.dart';
import '../../domain/risk_exposure_repository.dart';
import '../../domain/risk_intelligence_service.dart';
import '../../domain/risk_result.dart';
import '../../domain/risk_result_repository.dart';
import '../../../observations/domain/observation.dart';

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

/// Live series of the generic hazards (landslide, drought, heat, wildfire,
/// storm) from the Open-Meteo forecast API.
final hazardEnvironmentalDataSourceProvider =
    Provider<HazardEnvironmentalDataSource>((ref) {
  return OpenMeteoHazardDataSource(
    client: ref.read(httpClientProvider),
  );
});

/// ERA5 historical series the generic hazards build their statistical
/// reference from.
final hazardHistoricalDataSourceProvider =
    Provider<HazardHistoricalDataSource>((ref) {
  return OpenMeteoHazardHistoricalDataSource(
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

final hazardRiskServiceProvider =
    Provider<HazardRiskService>((ref) {
  return HazardRiskService(
    liveDataSource: ref.read(
      hazardEnvironmentalDataSourceProvider,
    ),
    historicalDataSource: ref.read(
      hazardHistoricalDataSourceProvider,
    ),
    referencePeriodStart:
        RiskZoneCatalog.historicalBaselineStart,
    referencePeriodEnd:
        RiskZoneCatalog.historicalBaselineEnd,
    exposureRepository: ref.read(
      riskExposureRepositoryProvider,
    ),
    riskResultRepository: ref.read(
      riskResultRepositoryProvider,
    ),
    riskIntelligenceService: ref.read(
      riskIntelligenceServiceProvider,
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

/// Zones shared by the citizen home screen and the admin risk screen.
final riskZoneCatalogProvider =
    Provider<List<RiskZoneTarget>>((ref) {
  return RiskZoneCatalog.zones;
});

/// Stored exposure / vulnerability profile of a zone, read from
/// `risk_zones/{zoneId}`.
///
/// A null value means the zone has no exposure data yet. Screens must report
/// that explicitly instead of reading it as "no vulnerability".
final riskExposureProfileProvider =
    FutureProvider.family<FloodRiskExposureProfile?, String>(
  (ref, zoneId) async {
    final repository =
        ref.read(riskExposureRepositoryProvider);

    return repository.getProfile(zoneId);
  },
);

/// Runs the Risk Intelligence pipeline of a zone for one hazard and persists
/// the result. Flooding is served by its dedicated pipeline, the other
/// hazards by [HazardRiskService]; both write to `risk_results` with the
/// hazard-aware id built by `HazardRiskId`.
typedef ZoneHazardRiskGenerator = Future<RiskResult> Function(
  RiskZoneTarget zone,
  HazardType hazard,
);

/// Runs the Risk Intelligence pipeline of a zone and persists the result.
typedef ZoneRiskGenerator = Future<RiskResult> Function(
  RiskZoneTarget zone,
);

/// Single entry point for hazard risk generation, shared by the citizen
/// screens and the admin screens so both use the exact same pipeline.
final zoneHazardRiskGeneratorProvider =
    Provider<ZoneHazardRiskGenerator>((ref) {
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

/// Single entry point for flood risk generation, shared by the citizen
/// screens and the admin screens so both use the exact same pipeline and
/// write to the same `risk_results/{zoneId}` document.
final zoneRiskGeneratorProvider =
    Provider<ZoneRiskGenerator>((ref) {
  final generator = ref.watch(zoneHazardRiskGeneratorProvider);

  return (zone) => generator(zone, HazardType.flooding);
});