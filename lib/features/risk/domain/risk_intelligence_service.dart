import '../../observations/domain/observation.dart';
import 'flood_environmental_data.dart';
import 'flood_risk_calculator.dart';
import 'flood_risk_context.dart';
import 'flood_risk_input.dart';
import 'flood_risk_input_exposure_enricher.dart';
import 'flood_risk_input_factory.dart';
import 'flood_risk_input_observation_enricher.dart';
import 'risk_evidence.dart';
import 'risk_measurement.dart';
import 'risk_result.dart';

class RiskIntelligenceService {
  final FloodRiskCalculator _floodRiskCalculator;
  final FloodRiskInputExposureEnricher? _exposureEnricher;
  final FloodRiskInputObservationEnricher _observationEnricher;

  const RiskIntelligenceService({
    FloodRiskCalculator? floodRiskCalculator,
    this._exposureEnricher,
    FloodRiskInputObservationEnricher? observationEnricher,
  })  : _floodRiskCalculator =
            floodRiskCalculator ?? const FloodRiskCalculator(),
        _observationEnricher =
            observationEnricher ??
            const FloodRiskInputObservationEnricher();

  RiskResult calculateFloodRisk({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodRiskInput input,
    String? rainfallSource,
    String? riverSource,
    DateTime? observedAt,
  }) {
    final calculation = _floodRiskCalculator.calculate(input);
    final timestamp = observedAt ?? DateTime.now().toUtc();

    final evidence = RiskEvidence(
      measurements: [
        RiskMeasurement(
          name: 'rainfallIntensity',
          value: input.rainfallIntensityMmPerHour,
          unit: 'mm/h',
          measurementPeriod: '1h',
          referenceValue: input.rainfallBaselineMmPerHour,
          referenceUnit: 'mm/h',
          referenceLabel: 'Local rainfall baseline',
          referenceType: RiskReferenceType.localBaseline,
          ratioToReference:
              input.rainfallBaselineMmPerHour > 0
                  ? input.rainfallIntensityMmPerHour /
                      input.rainfallBaselineMmPerHour
                  : null,
          differenceFromReference:
              input.rainfallIntensityMmPerHour -
                  input.rainfallBaselineMmPerHour,
          source: rainfallSource,
          observedAt: timestamp,
        ),
        RiskMeasurement(
          name: 'rainfallAccumulation6h',
          value: input.rainfallAccumulation6hMm,
          unit: 'mm',
          measurementPeriod: '6h',
          referenceValue: input.rainfallAccumulation6hBaselineMm,
          referenceUnit: 'mm',
          referenceLabel: 'Historical 6-hour rainfall baseline',
          referenceType: RiskReferenceType.historicalAverage,
          ratioToReference:
              input.rainfallAccumulation6hBaselineMm > 0
                  ? input.rainfallAccumulation6hMm /
                      input.rainfallAccumulation6hBaselineMm
                  : null,
          differenceFromReference:
              input.rainfallAccumulation6hMm -
                  input.rainfallAccumulation6hBaselineMm,
          source: rainfallSource,
          observedAt: timestamp,
        ),
        RiskMeasurement(
          name: 'riverDischarge',
          value: input.riverDischargeM3s,
          unit: 'm³/s',
          measurementPeriod: 'daily',
          referenceValue: input.riverDischargeBaselineM3s,
          referenceUnit: 'm³/s',
          referenceLabel: 'River discharge baseline',
          referenceType: RiskReferenceType.threshold,
          ratioToReference:
              input.riverDischargeBaselineM3s > 0
                  ? input.riverDischargeM3s /
                      input.riverDischargeBaselineM3s
                  : null,
          differenceFromReference:
              input.riverDischargeM3s -
                  input.riverDischargeBaselineM3s,
          source: riverSource,
          observedAt: timestamp,
        ),
        RiskMeasurement(
          name: 'geographicVulnerability',
          value: input.vulnerabilityScore,
          unit: 'score/100',
          referenceLabel: 'Geographic vulnerability score',
          referenceType: RiskReferenceType.threshold,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
        RiskMeasurement(
          name: 'historicalExposure',
          value: input.historicalExposureScore,
          unit: 'score/100',
          referenceLabel: 'Historical exposure score',
          referenceType: RiskReferenceType.historicalAverage,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
        RiskMeasurement(
          name: 'citizenObservationRisk',
          value: input.observationScore,
          unit: 'score/100',
          referenceLabel: 'Recent citizen observation risk',
          referenceType: RiskReferenceType.threshold,
          source: 'Citizen Observations',
          observedAt: timestamp,
        ),
      ],
      qualitativeIndicators: [
        if (input.observationCount > 0)
          '${input.observationCount} citizen observations received.',
        if (input.confirmedObservationCount > 0)
          '${input.confirmedObservationCount} citizen observations confirmed.',
      ],
      observationCount: input.observationCount,
      confirmedObservationCount: input.confirmedObservationCount,
      collectedAt: timestamp,
    );

    return RiskResult(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      hazardType: 'Flooding',
      riskScore: calculation.overallScore,
      riskLevel: calculation.riskLevel,
      factors: calculation.factors,
      evidence: evidence,
      updatedAt: timestamp,
    );
  }

  Future<RiskResult> calculateFloodRiskWithExposure({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodRiskInput input,
    String? rainfallSource,
    String? riverSource,
    DateTime? observedAt,
  }) async {
    final enricher = _exposureEnricher;

    if (enricher == null) {
      return calculateFloodRisk(
        id: id,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        input: input,
        rainfallSource: rainfallSource,
        riverSource: riverSource,
        observedAt: observedAt,
      );
    }

    final enrichedInput = await enricher.enrich(
      zoneId: zoneId,
      input: input,
    );

    return calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: enrichedInput,
      rainfallSource: rainfallSource,
      riverSource: riverSource,
      observedAt: observedAt,
    );
  }

  Future<RiskResult> calculateFloodRiskWithObservations({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodRiskInput input,
    required List<Observation> observations,
    String? rainfallSource,
    String? riverSource,
    DateTime? observedAt,
  }) async {
    final enrichedInput = _observationEnricher.enrich(
      latitude: latitude,
      longitude: longitude,
      input: input,
      observations: observations,
    );

    return calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: enrichedInput,
      rainfallSource: rainfallSource,
      riverSource: riverSource,
      observedAt: observedAt,
    );
  }

  Future<RiskResult> calculateFloodRiskWithExposureAndObservations({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodRiskInput input,
    required List<Observation> observations,
    String? rainfallSource,
    String? riverSource,
    DateTime? observedAt,
  }) async {
    var enrichedInput = input;

    final exposureEnricher = _exposureEnricher;

    if (exposureEnricher != null) {
      enrichedInput = await exposureEnricher.enrich(
        zoneId: zoneId,
        input: enrichedInput,
      );
    }

    enrichedInput = _observationEnricher.enrich(
      latitude: latitude,
      longitude: longitude,
      input: enrichedInput,
      observations: observations,
    );

    return calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: enrichedInput,
      rainfallSource: rainfallSource,
      riverSource: riverSource,
      observedAt: observedAt,
    );
  }

  RiskResult calculateFloodRiskFromEnvironmentalData({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodEnvironmentalData environmentalData,
    required FloodRiskContext context,
  }) {
    const factory = FloodRiskInputFactory();

    final input = factory.create(
      environmentalData: environmentalData,
      context: context,
    );

    return calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: input,
      rainfallSource: environmentalData.rainfallSource,
      riverSource: environmentalData.riverSource,
      observedAt: environmentalData.observedAt,
    );
  }

  Future<RiskResult>
      calculateFloodRiskFromEnvironmentalDataWithExposure({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodEnvironmentalData environmentalData,
    required FloodRiskContext context,
  }) async {
    const factory = FloodRiskInputFactory();

    final input = factory.create(
      environmentalData: environmentalData,
      context: context,
    );

    return calculateFloodRiskWithExposure(
      id: id,
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: input,
      rainfallSource: environmentalData.rainfallSource,
      riverSource: environmentalData.riverSource,
      observedAt: environmentalData.observedAt,
    );
  }

  Future<RiskResult>
      calculateFloodRiskFromEnvironmentalDataWithExposureAndObservations({
    required String id,
    required String zoneId,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodEnvironmentalData environmentalData,
    required FloodRiskContext context,
    required List<Observation> observations,
  }) async {
    const factory = FloodRiskInputFactory();

    final input = factory.create(
      environmentalData: environmentalData,
      context: context,
    );

    return calculateFloodRiskWithExposureAndObservations(
      id: id,
      zoneId: zoneId,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: input,
      observations: observations,
      rainfallSource: environmentalData.rainfallSource,
      riverSource: environmentalData.riverSource,
      observedAt: environmentalData.observedAt,
    );
  }
}