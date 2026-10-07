import '../../observations/data/observations_repository.dart';
import '../../observations/domain/observation.dart';
import '../../observations/domain/observation_risk_calculator.dart';
import 'flood_risk_exposure_profile.dart';
import 'hazard_baseline.dart';
import 'hazard_baseline_service.dart';
import 'hazard_catalog.dart';
import 'hazard_definition.dart';
import 'hazard_environmental_data_source.dart';
import 'hazard_exposure_extractor.dart';
import 'hazard_historical_data_source.dart';
import 'hazard_risk_id.dart';
import 'hazard_risk_input.dart';
import 'hazard_type.dart';
import 'hazard_variable.dart';
import 'hazard_variable_builder.dart';
import 'risk_exposure_repository.dart';
import 'risk_intelligence_service.dart';
import 'risk_result.dart';
import 'risk_result_repository.dart';

class _CachedBaseline {
  const _CachedBaseline({required this.baseline, required this.cachedAt});

  final HazardBaseline baseline;
  final DateTime cachedAt;
}

class HazardRiskService {
  HazardRiskService({
    required this.liveDataSource,
    required this.historicalDataSource,
    required this.referencePeriodStart,
    required this.referencePeriodEnd,
    this.exposureRepository,
    this.riskResultRepository,
    this.observationsRepository,
    this.observationRiskCalculator = const ObservationRiskCalculator(),
    this.riskIntelligenceService = const RiskIntelligenceService(),
    this.variableBuilder = const HazardVariableBuilder(),
    this.exposureExtractor = const HazardExposureExtractor(),
    this.baselineMaxAge = const Duration(hours: 24),
  }) : _baselineService = HazardBaselineService(
         dataSource: historicalDataSource,
       );

  final HazardEnvironmentalDataSource liveDataSource;
  final HazardHistoricalDataSource historicalDataSource;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;

  final RiskExposureRepository? exposureRepository;
  final RiskResultRepository? riskResultRepository;

  final ObservationsRepository? observationsRepository;
  final ObservationRiskCalculator observationRiskCalculator;

  final RiskIntelligenceService riskIntelligenceService;
  final HazardVariableBuilder variableBuilder;
  final HazardExposureExtractor exposureExtractor;

  final Duration baselineMaxAge;

  final HazardBaselineService _baselineService;
  final Map<String, _CachedBaseline> _baselineCache =
      <String, _CachedBaseline>{};

  Future<RiskResult> calculate({
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required HazardType hazard,
    bool useBaselineCache = true,
    List<Observation>? observations,
  }) async {
    final definition = HazardCatalog.of(hazard);

    if (definition.legacyPipeline) {
      throw StateError(
        '${hazard.label} est évalué par son pipeline dédié '
        '(LiveFloodRiskService) ; HazardRiskService ne doit pas le scorer.',
      );
    }

    final live = await liveDataSource.fetch(
      hazard: hazard,
      latitude: latitude,
      longitude: longitude,
    );

    final baseline = await _baselineFor(
      hazard: hazard,
      latitude: latitude,
      longitude: longitude,
      useCache: useBaselineCache,
    );

    final build = variableBuilder.build(
      definition: definition,
      liveData: live,
      baseline: baseline,
    );

    FloodRiskExposureProfile? profile;
    final repository = exposureRepository;

    if (repository != null) {
      profile = await repository.getProfile(zoneId);
    }

    final exposure = exposureExtractor.extract(
      hazard: hazard,
      profile: profile,
    );

    final resolvedObservations =
        observations ?? await _getConfirmedObservations(
          zoneId: zoneId,
          hazard: hazard,
        );

    final observationCalculation = observationRiskCalculator.calculate(
      latitude: latitude,
      longitude: longitude,
      observations: resolvedObservations,
    );

    final notes = <String>[...live.providerNotes, ...baseline.notes];

    final input = HazardRiskInput(
      hazard: hazard,
      primaryFactorLabel: definition.primaryFactorLabel,
      variables: build.variables,
      gaps: build.gaps,
      vulnerabilityScore: exposure.vulnerabilityScore,
      historicalExposureScore: exposure.historicalExposureScore,
      observationScore: observationCalculation.score,
      observationCount: observationCalculation.observationCount,
      confirmedObservationCount:
          observationCalculation.confirmedObservationCount,
      exposureProfileMissing: profile == null,
      exposureNote: exposure.note,
      limitations: definition.limitations,
      notes: notes,
      referencePeriodStart: baseline.referencePeriodStart,
      referencePeriodEnd: baseline.referencePeriodEnd,
      referenceSource: baseline.source,
      partialReference: _partialReference(
        definition: definition,
        baseline: baseline,
        variables: build.variables,
      ),
    );

    return riskIntelligenceService.calculateHazardRisk(
      id: HazardRiskId.forZone(zoneId: zoneId, hazard: hazard),
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: input,
    );
  }

  Future<RiskResult> calculateAndSave({
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required HazardType hazard,
    bool useBaselineCache = true,
    List<Observation>? observations,
  }) async {
    final result = await calculate(
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      hazard: hazard,
      useBaselineCache: useBaselineCache,
      observations: observations,
    );

    final repository = riskResultRepository;

    if (repository != null) {
      await repository.save(result);
    }

    return result;
  }

  void clearBaselineCache() {
    _baselineCache.clear();
  }

  Future<List<Observation>> _getConfirmedObservations({
    required String zoneId,
    required HazardType hazard,
  }) async {
    final repository = observationsRepository;

    if (repository == null) {
      return const <Observation>[];
    }

    return repository.getConfirmedForContext(
      zoneId: zoneId,
      hazardType: _observationHazardType(hazard),
    );
  }

  String _observationHazardType(HazardType hazard) {
    // Observations are stored with the hazard label (see ObservationsScreen
    // and the alerts convention), so the query must use the same value.
    return hazard.label;
  }

  Future<HazardBaseline> _baselineFor({
    required HazardType hazard,
    required double latitude,
    required double longitude,
    required bool useCache,
  }) async {
    final key =
        '${hazard.id}|'
        '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}|'
        '${referencePeriodStart.toUtc().toIso8601String()}|'
        '${referencePeriodEnd.toUtc().toIso8601String()}';

    if (useCache) {
      final cached = _baselineCache[key];

      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) < baselineMaxAge) {
        return cached.baseline;
      }
    }

    final baseline = await _baselineService.generate(
      hazard: hazard,
      latitude: latitude,
      longitude: longitude,
      startDate: referencePeriodStart,
      endDate: referencePeriodEnd,
    );

    _baselineCache[key] = _CachedBaseline(
      baseline: baseline,
      cachedAt: DateTime.now(),
    );

    return baseline;
  }

  bool _partialReference({
    required HazardDefinition definition,
    required HazardBaseline baseline,
    required List<HazardVariable> variables,
  }) {
    if (!definition.seasonalReference) {
      return false;
    }

    for (final variable in variables) {
      if (variable.informational) {
        continue;
      }

      final reference = baseline.variableFor(variable.name);

      if (reference == null) {
        continue;
      }

      final slice = reference.sliceFor(variable.observedAt);

      if (!slice.usedSeasonalBucket) {
        return true;
      }
    }

    return false;
  }
}