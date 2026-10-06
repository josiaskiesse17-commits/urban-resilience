import '../../observations/data/observations_repository.dart';
import '../../observations/domain/observation.dart';
import 'flood_environmental_data_source.dart';
import 'flood_historical_baseline.dart';
import 'flood_risk_context.dart';
import 'flood_risk_input_factory.dart';
import 'historical_flood_baseline_service.dart';
import 'hazard_type.dart';
import 'risk_intelligence_service.dart';
import 'risk_result.dart';
import 'risk_result_repository.dart';
import 'risk_scenario.dart';
import 'risk_scenario_result.dart';
import 'risk_scenario_service.dart';

class LiveFloodRiskService {
  final FloodEnvironmentalDataSource dataSource;
  final RiskIntelligenceService riskIntelligenceService;
  final RiskResultRepository? riskResultRepository;
  final HistoricalFloodBaselineService? historicalBaselineService;
  final ObservationsRepository? observationsRepository;

  const LiveFloodRiskService({
    required this.dataSource,
    this.riskIntelligenceService = const RiskIntelligenceService(),
    this.riskResultRepository,
    this.historicalBaselineService,
    this.observationsRepository,
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
      rainfallBaselineMmPerHour: baseline.rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour: baseline.rainfallCriticalMmPerHour,
      rainfallAccumulation6hBaselineMm:
          baseline.rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          baseline.rainfallAccumulation6hCriticalMm,
      riverDischargeBaselineM3s: baseline.riverDischargeBaselineM3s,
      riverDischargeCriticalM3s: baseline.riverDischargeCriticalM3s,
      vulnerabilityScore: vulnerabilityScore,
      historicalExposureScore: historicalExposureScore,
      observationScore: observationScore,
      observationCount: observationCount,
      confirmedObservationCount: confirmedObservationCount,
    );

    return riskIntelligenceService.calculateFloodRiskFromEnvironmentalData(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      environmentalData: environmentalData,
      context: context,
      baseline: baseline,
    );
  }

  Future<RiskResult> calculateWithExposureAndObservations({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodHistoricalBaseline baseline,
    List<Observation>? observations,
  }) async {
    final environmentalData = await dataSource.fetch(
      latitude: latitude,
      longitude: longitude,
    );

    final resolvedObservations =
        observations ?? await _getConfirmedObservations(zoneId);

    final context = FloodRiskContext(
      rainfallBaselineMmPerHour: baseline.rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour: baseline.rainfallCriticalMmPerHour,
      rainfallAccumulation6hBaselineMm:
          baseline.rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          baseline.rainfallAccumulation6hCriticalMm,
      riverDischargeBaselineM3s: baseline.riverDischargeBaselineM3s,
      riverDischargeCriticalM3s: baseline.riverDischargeCriticalM3s,
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
          observations: resolvedObservations,
          baseline: baseline,
        );
  }

  Future<RiskResult> calculateWithExposureAndObservationsAndSave({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodHistoricalBaseline baseline,
    List<Observation>? observations,
  }) async {
    final result = await calculateWithExposureAndObservations(
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

  Future<RiskResult> calculateLiveRiskAndSave({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    List<Observation>? observations,
  }) async {
    final baselineService = historicalBaselineService;

    if (baselineService == null) {
      throw StateError(
        'HistoricalFloodBaselineService is required '
        'for calculateLiveRiskAndSave().',
      );
    }

    final baseline = await baselineService.generate(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    final resolvedObservations =
        observations ?? await _getConfirmedObservations(zoneId);

    return calculateWithExposureAndObservationsAndSave(
      id: id,
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      baseline: baseline,
      observations: resolvedObservations,
    );
  }

  Future<RiskScenarioResult> simulateFloodScenario({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
    required RiskScenario scenario,
    required double vulnerabilityScore,
    required double historicalExposureScore,
    required double observationScore,
    required int observationCount,
    required int confirmedObservationCount,
  }) async {
    final baselineService = historicalBaselineService;

    if (baselineService == null) {
      throw StateError(
        'HistoricalFloodBaselineService is required '
        'for simulateFloodScenario().',
      );
    }

    final baseline = await baselineService.generate(
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    final environmentalData = await dataSource.fetch(
      latitude: latitude,
      longitude: longitude,
    );

    final context = FloodRiskContext(
      rainfallBaselineMmPerHour: baseline.rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour: baseline.rainfallCriticalMmPerHour,
      rainfallAccumulation6hBaselineMm:
          baseline.rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          baseline.rainfallAccumulation6hCriticalMm,
      riverDischargeBaselineM3s: baseline.riverDischargeBaselineM3s,
      riverDischargeCriticalM3s: baseline.riverDischargeCriticalM3s,
      vulnerabilityScore: vulnerabilityScore,
      historicalExposureScore: historicalExposureScore,
      observationScore: observationScore,
      observationCount: observationCount,
      confirmedObservationCount: confirmedObservationCount,
    );

    const factory = FloodRiskInputFactory();

    final input = factory.create(
      environmentalData: environmentalData,
      context: context,
    );

    return RiskScenarioService(
      riskIntelligenceService: riskIntelligenceService,
    ).simulateFloodRisk(
      scenario: scenario,
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      baselineInput: input,
      rainfallSource: environmentalData.rainfallSource,
      riverSource: environmentalData.riverSource,
      observedAt: environmentalData.observedAt,
      baseline: baseline,
    );
  }

  Future<List<Observation>> _getConfirmedObservations(
    String zoneId,
  ) async {
    final repository = observationsRepository;

    if (repository == null) {
      return const <Observation>[];
    }

    return repository.getConfirmedForContext(
      zoneId: zoneId,
      hazardType: HazardType.flooding.label,
    );
  }
}
