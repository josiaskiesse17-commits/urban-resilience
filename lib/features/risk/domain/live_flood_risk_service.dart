import '../../observations/domain/observation.dart';
import 'flood_environmental_data_source.dart';
import 'flood_historical_baseline.dart';
import 'flood_risk_context.dart';
import 'historical_flood_baseline_service.dart';
import 'risk_intelligence_service.dart';
import 'risk_result.dart';
import 'risk_result_repository.dart';

class LiveFloodRiskService {
  final FloodEnvironmentalDataSource dataSource;
  final RiskIntelligenceService riskIntelligenceService;
  final RiskResultRepository? riskResultRepository;
  final HistoricalFloodBaselineService? historicalBaselineService;

  const LiveFloodRiskService({
    required this.dataSource,
    this.riskIntelligenceService =
        const RiskIntelligenceService(),
    this.riskResultRepository,
    this.historicalBaselineService,
  });

  Future<RiskResult> calculate({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodHistoricalBaseline baseline,
    required double vulnerabilityScore,
    required double historicalExposureScore,
    required double observationScore,
    required int observationCount,
    required int confirmedObservationCount,
  }) async {
    final environmentalData = await dataSource.fetch(
      latitude: latitude,
      longitude: longitude,
    );

    final context = FloodRiskContext(
      rainfallBaselineMmPerHour:
          baseline.rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour:
          baseline.rainfallCriticalMmPerHour,
      rainfallAccumulation6hBaselineMm:
          baseline.rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          baseline.rainfallAccumulation6hCriticalMm,
      riverDischargeBaselineM3s:
          baseline.riverDischargeBaselineM3s,
      riverDischargeCriticalM3s:
          baseline.riverDischargeCriticalM3s,
      vulnerabilityScore: vulnerabilityScore,
      historicalExposureScore:
          historicalExposureScore,
      observationScore: observationScore,
      observationCount: observationCount,
      confirmedObservationCount:
          confirmedObservationCount,
    );

    return riskIntelligenceService
        .calculateFloodRiskFromEnvironmentalData(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      environmentalData: environmentalData,
      context: context,
    );
  }

  Future<RiskResult>
      calculateWithExposureAndObservations({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodHistoricalBaseline baseline,
    required List<Observation> observations,
  }) async {
    final environmentalData = await dataSource.fetch(
      latitude: latitude,
      longitude: longitude,
    );

    final context = FloodRiskContext(
      rainfallBaselineMmPerHour:
          baseline.rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour:
          baseline.rainfallCriticalMmPerHour,
      rainfallAccumulation6hBaselineMm:
          baseline.rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          baseline.rainfallAccumulation6hCriticalMm,
      riverDischargeBaselineM3s:
          baseline.riverDischargeBaselineM3s,
      riverDischargeCriticalM3s:
          baseline.riverDischargeCriticalM3s,
      vulnerabilityScore: 0,
      historicalExposureScore: 0,
      observationScore: 0,
      observationCount: 0,
      confirmedObservationCount: 0,
    );

    return riskIntelligenceService
        .calculateFloodRiskFromEnvironmentalDataWithExposureAndObservations(
      id: id,
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      environmentalData: environmentalData,
      context: context,
      observations: observations,
    );
  }

  Future<RiskResult>
      calculateWithExposureAndObservationsAndSave({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodHistoricalBaseline baseline,
    required List<Observation> observations,
  }) async {
    final result =
        await calculateWithExposureAndObservations(
      id: id,
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      baseline: baseline,
      observations: observations,
    );

    final repository = riskResultRepository;

    if (repository != null) {
      await repository.save(result);
    }

    return result;
  }

  /// Complete live-risk pipeline:
  ///
  /// Historical data
  /// → historical baseline
  /// → live environmental data
  /// → exposure
  /// → observations
  /// → RiskResult
  /// → Firestore
  Future<RiskResult>
      calculateLiveRiskAndSave({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required List<Observation> observations,
  }) async {
    final baselineService = historicalBaselineService;

    if (baselineService == null) {
      throw StateError(
        'HistoricalFloodBaselineService is required '
        'for calculateLiveRiskAndSave().',
      );
    }

    final baseline =
        await baselineService.generate(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    return calculateWithExposureAndObservationsAndSave(
      id: id,
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      baseline: baseline,
      observations: observations,
    );
  }
}