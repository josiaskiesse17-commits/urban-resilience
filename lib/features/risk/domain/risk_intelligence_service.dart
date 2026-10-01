import '../../observations/domain/observation.dart';
import 'flood_environmental_data.dart';
import 'flood_historical_baseline.dart';
import 'flood_risk_calculator.dart';
import 'flood_risk_context.dart';
import 'flood_risk_input.dart';
import 'flood_risk_input_exposure_enricher.dart';
import 'flood_risk_input_factory.dart';
import 'flood_risk_input_observation_enricher.dart';
import 'hazard_evidence_builder.dart';
import 'hazard_risk_calculator.dart';
import 'hazard_risk_input.dart';
import 'risk_evidence.dart';
import 'risk_measurement.dart';
import 'risk_measurement_label.dart';
import 'risk_result.dart';

/// Statistical reference used by one flooding variable.
typedef _FloodReference = ({
  double? median,
  double? critical,
  String label,
  RiskReferenceType type,
  double? percentile,
});

/// Statistical disclaimer attached to every flooding bound.
const String _statisticalBoundNote =
    'Statistical reference of the same location and reference period, '
    'not an official safety threshold.';

class RiskIntelligenceService {
  final FloodRiskCalculator _floodRiskCalculator;
  final HazardRiskCalculator _hazardRiskCalculator;
  final FloodRiskInputExposureEnricher? _exposureEnricher;
  final FloodRiskInputObservationEnricher _observationEnricher;

  const RiskIntelligenceService({
    FloodRiskCalculator? floodRiskCalculator,
    HazardRiskCalculator? hazardRiskCalculator,
    this._exposureEnricher,
    FloodRiskInputObservationEnricher? observationEnricher,
  })  : _floodRiskCalculator =
            floodRiskCalculator ?? const FloodRiskCalculator(),
        _hazardRiskCalculator =
            hazardRiskCalculator ?? const HazardRiskCalculator(),
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
    bool exposureProfileMissing = false,
    FloodHistoricalBaseline? baseline,
    DateTime? rainfallObservedAt,
    DateTime? riverObservedAt,
    List<String> dataNotes = const <String>[],
    int rainfallAccumulationWindowHours = 6,
  }) {
    final calculation = _floodRiskCalculator.calculate(input);
    final timestamp = observedAt ?? DateTime.now().toUtc();
    final rainfallTime = rainfallObservedAt ?? timestamp;
    final riverTime = riverObservedAt ?? timestamp;

    final rainfallReference = _rainfallReference(
      input: input,
      baseline: baseline,
    );

    final accumulationReference = _accumulationReference(
      input: input,
      baseline: baseline,
    );

    final riverReference = _riverReference(
      input: input,
      baseline: baseline,
    );

    final evidence = RiskEvidence(
      measurements: [
        RiskMeasurement(
          name: 'rainfallIntensity',
          value: input.rainfallIntensityMmPerHour,
          unit: 'mm/h',
          measurementPeriod: '1h',
          referenceValue: rainfallReference.median,
          referenceUnit: 'mm/h',
          referenceLabel: rainfallReference.label,
          referenceType: rainfallReference.type,
          ratioToReference:
              rainfallReference.median != null &&
                      rainfallReference.median! > 0
                  ? input.rainfallIntensityMmPerHour /
                      rainfallReference.median!
                  : null,
          differenceFromReference:
              rainfallReference.median == null
                  ? null
                  : input.rainfallIntensityMmPerHour -
                      rainfallReference.median!,
          historicalPercentile:
              rainfallReference.percentile,
          statisticalCriticalValue:
              rainfallReference.critical,
          statisticalCriticalLabel:
              rainfallReference.critical == null
                  ? null
                  : '95th percentile of the same reference period. '
                      '$_statisticalBoundNote',
          source: rainfallSource,
          observedAt: rainfallTime,
        ),
        RiskMeasurement(
          name: 'rainfallAccumulation6h',
          value: input.rainfallAccumulation6hMm,
          unit: 'mm',
          measurementPeriod: '${rainfallAccumulationWindowHours}h',
          referenceValue: accumulationReference.median,
          referenceUnit: 'mm',
          referenceLabel: accumulationReference.label,
          referenceType: accumulationReference.type,
          ratioToReference:
              accumulationReference.median != null &&
                      accumulationReference.median! > 0
                  ? input.rainfallAccumulation6hMm /
                      accumulationReference.median!
                  : null,
          differenceFromReference:
              accumulationReference.median == null
                  ? null
                  : input.rainfallAccumulation6hMm -
                      accumulationReference.median!,
          historicalPercentile:
              accumulationReference.percentile,
          statisticalCriticalValue:
              accumulationReference.critical,
          statisticalCriticalLabel:
              accumulationReference.critical == null
                  ? null
                  : '95th percentile of the same reference period. '
                      '$_statisticalBoundNote',
          source: rainfallSource,
          observedAt: rainfallTime,
        ),
        RiskMeasurement(
          name: 'riverDischarge',
          value: input.riverDischargeM3s,
          unit: 'm³/s',
          measurementPeriod: 'daily',
          referenceValue: riverReference.median,
          referenceUnit: 'm³/s',
          referenceLabel: riverReference.label,
          referenceType: riverReference.type,
          ratioToReference:
              riverReference.median != null &&
                      riverReference.median! > 0
                  ? input.riverDischargeM3s /
                      riverReference.median!
                  : null,
          differenceFromReference:
              riverReference.median == null
                  ? null
                  : input.riverDischargeM3s -
                      riverReference.median!,
          historicalPercentile: riverReference.percentile,
          statisticalCriticalValue: riverReference.critical,
          statisticalCriticalLabel:
              riverReference.critical == null
                  ? null
                  : '95th percentile of the same reference period. '
                      '$_statisticalBoundNote',
          source: riverSource,
          observedAt: riverTime,
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
        if (exposureProfileMissing)
          'No stored exposure profile was found for this zone. '
              'Geographic vulnerability and historical exposure could '
              'not be evaluated and are missing from this score.',
        if (baseline != null)
          'Statistical reference: '
              '${_formatPeriod(baseline.referencePeriodStart)} – '
              '${_formatPeriod(baseline.referencePeriodEnd)} '
              '(${baseline.rainfallSampleCount} hourly rainfall samples, '
              '${baseline.riverDischargeSampleCount} daily river discharge '
              'samples). The reference values are percentiles of that '
              'period of the same grid cells; they are not official '
              'safety thresholds.',
        if (baseline == null)
          'The statistical reference of this location was not supplied '
              'with this assessment, so the reference values come from the '
              'fallback input only.',
        if (input.observationCount > 0)
          '${input.observationCount} citizen observations received.',
        if (input.confirmedObservationCount > 0)
          '${input.confirmedObservationCount} citizen observations '
              'confirmed.',
        ...dataNotes,
        'Citizen observations are not connected to this release: the '
            'observation factor is excluded from the score instead of being '
            'counted as zero.',
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

  /// Flooding reference of one measurement.
  ///
  /// The statistical distribution of the reference period is used when it is
  /// available: it gives both the central reference and the percentile of the
  /// live value. Without it the values already carried by the input are kept,
  /// so a caller that supplies its own baseline still produces a complete
  /// assessment.
  _FloodReference _rainfallReference({
    required FloodRiskInput input,
    required FloodHistoricalBaseline? baseline,
  }) {
    final distribution = baseline?.rainfallHourlyDistribution;

    if (baseline == null || distribution == null) {
      return (
        median: input.rainfallBaselineMmPerHour,
        critical: input.rainfallCriticalMmPerHour,
        label: 'Local rainfall baseline supplied with the assessment',
        type: RiskReferenceType.localBaseline,
        percentile: null,
      );
    }

    return (
      median: distribution.median,
      critical: distribution.percentile(95),
      label: 'Median of the ${_periodLabel(baseline)} ERA5 hourly rainfall '
          'reference (${distribution.sampleCount} samples)',
      type: RiskReferenceType.historicalMedian,
      percentile: distribution.percentileRankOf(
        input.rainfallIntensityMmPerHour,
      ),
    );
  }

  _FloodReference _accumulationReference({
    required FloodRiskInput input,
    required FloodHistoricalBaseline? baseline,
  }) {
    final distribution = baseline?.rainfallSixHourDistribution;

    if (baseline == null || distribution == null) {
      return (
        median: input.rainfallAccumulation6hBaselineMm,
        critical: input.rainfallAccumulation6hCriticalMm,
        label: 'Historical 6-hour rainfall baseline supplied with the '
            'assessment',
        type: RiskReferenceType.historicalAverage,
        percentile: null,
      );
    }

    return (
      median: distribution.median,
      critical: distribution.percentile(95),
      label: 'Median of the ${_periodLabel(baseline)} ERA5 6-hour rainfall '
          'reference (${distribution.sampleCount} samples)',
      type: RiskReferenceType.historicalMedian,
      percentile: distribution.percentileRankOf(
        input.rainfallAccumulation6hMm,
      ),
    );
  }

  _FloodReference _riverReference({
    required FloodRiskInput input,
    required FloodHistoricalBaseline? baseline,
  }) {
    final distribution = baseline?.riverDischargeDistribution;

    if (baseline == null || distribution == null) {
      return (
        median: input.riverDischargeBaselineM3s,
        critical: input.riverDischargeCriticalM3s,
        label: 'River discharge baseline supplied with the assessment',
        type: RiskReferenceType.historicalMedian,
        percentile: null,
      );
    }

    return (
      median: distribution.median,
      critical: distribution.percentile(95),
      label: 'Median of the ${_periodLabel(baseline)} GloFAS daily river '
          'discharge reference (${distribution.sampleCount} samples)',
      type: RiskReferenceType.historicalMedian,
      percentile: distribution.percentileRankOf(
        input.riverDischargeM3s,
      ),
    );
  }

  /// Builds the stored risk result of a hazard assessed by the generic
  /// hazard engine.
  ///
  /// The engine only scores variables that carry a usable statistical
  /// reference; every variable that could not be measured, and every factor
  /// that is unavailable, is reported in the evidence instead of being
  /// counted as a zero.
  RiskResult calculateHazardRisk({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required HazardRiskInput input,
  }) {
    final assessment = _hazardRiskCalculator.calculate(input);

    final hazardMeasurements = HazardEvidenceBuilder.measurementsFrom(
      input.variables,
    );

    DateTime? newest;

    for (final measurement in hazardMeasurements) {
      final observedAt = measurement.observedAt;

      if (observedAt != null &&
          (newest == null || observedAt.isAfter(newest))) {
        newest = observedAt;
      }
    }

    final timestamp = newest ?? DateTime.now().toUtc();

    // The exposure factors of the score are part of the evidence too: a
    // factor is never named in the Risk Factors section without the
    // measurement it was computed from. A factor that is unavailable stays
    // out of this list and is therefore never presented as a value.
    final measurements = <RiskMeasurement>[
      ...hazardMeasurements,
      if (input.vulnerabilityScore != null)
        RiskMeasurement(
          name: 'geographicVulnerability',
          value: input.vulnerabilityScore!,
          unit: 'score/100',
          referenceLabel:
              'Vulnerability of the stored zone profile '
              '(population, infrastructure, critical facilities)',
          referenceType: RiskReferenceType.threshold,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
      if (input.historicalExposureScore != null)
        RiskMeasurement(
          name: 'historicalExposure',
          value: input.historicalExposureScore!,
          unit: 'score/100',
          referenceLabel: 'Stored historical exposure of this zone',
          referenceType: RiskReferenceType.historicalAverage,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
      if (input.observationCount > 0 || input.observationScore > 0)
        RiskMeasurement(
          name: 'citizenObservationRisk',
          value: input.observationScore,
          unit: 'score/100',
          referenceLabel: 'Recent citizen observation risk',
          referenceType: RiskReferenceType.threshold,
          source: 'Citizen Observations',
          observedAt: timestamp,
        ),
    ];

    final indicators = <String>[];

    if (input.hasReferencePeriod) {
      final source = input.referenceSource;

      indicators.add(
        'Statistical reference: '
        '${_formatPeriod(input.referencePeriodStart!)} – '
        '${_formatPeriod(input.referencePeriodEnd!)}'
        '${source == null ? '' : ' ($source)'}. '
        'Reference values are percentiles of the same calendar month of '
        'that period; they are not official safety thresholds.',
      );
    }

    if (input.partialReference) {
      indicators.add(
        'At least one variable had too few samples in the calendar month of '
        'the observation, so its whole-period statistics were used instead.',
      );
    }

    if (input.exposureNote.isNotEmpty) {
      indicators.add(input.exposureNote);
    }

    for (final gap in input.gaps) {
      indicators.add(
        'Not measured: ${gap.label} — ${gap.reason}. It is reported as '
        'missing from the hazard score, not as zero.',
      );
    }

    // A variable that was measured but carries no usable statistical
    // reference stays in the evidence with its real value; it is not part of
    // the factor breakdown because it played no role in the score. The
    // exclusion is reported here so it is never silently dropped.
    for (final variable in input.variables) {
      if (variable.score != null) {
        continue;
      }

      indicators.add(
        'Not scored: '
        '${RiskMeasurementLabel.of(
          name: variable.name,
          measurementPeriod: variable.measurementPeriod,
          unit: variable.unit,
        )} — its measured value stays in the evidence, but '
        '${variable.informational
            ? 'no statistical reference exists for it'
            : 'no usable statistical reference could be built for this '
                'location'}, so it is excluded from the score instead of '
        'being counted as zero.',
      );
    }

    if (!assessment.hazardAvailable) {
      indicators.add(
        'No environmental variable of this hazard could be scored for this '
        'location, so the hazard factor is unavailable and the assessment '
        'relies on the available exposure factors only.',
      );
    }

    if (assessment.excludedWeight > 0) {
      indicators.add(
        'Variables representing '
        '${(assessment.excludedWeight * 100).toStringAsFixed(0)}% of the '
        'hazard weight had no usable reference and were excluded; the '
        'remaining weights were renormalised over the available variables.',
      );
    }

    if (assessment.factorWeights.isNotEmpty) {
      final weights = assessment.factorWeights.entries
          .map(
            (entry) =>
                '${entry.key} ${entry.value.toStringAsFixed(2)}',
          )
          .join(', ');

      indicators.add(
        'Overall score weights applied after renormalisation: $weights.',
      );
    }

    indicators.add(
      'Citizen observations are not connected in this release: the '
      'observation factor is excluded from the score instead of being '
      'counted as zero.',
    );

    indicators.addAll(input.notes);

    for (final limitation in input.limitations) {
      indicators.add('Model limitation: $limitation');
    }

    return RiskResult(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      hazardType: input.hazard.label,
      riskScore: assessment.overallScore,
      riskLevel: assessment.riskLevel,
      factors: assessment.factors,
      evidence: RiskEvidence(
        measurements: measurements,
        qualitativeIndicators: indicators,
        observationCount: input.observationCount,
        confirmedObservationCount:
            input.confirmedObservationCount,
        collectedAt: timestamp,
      ),
      updatedAt: timestamp,
    );
  }

  String _periodLabel(FloodHistoricalBaseline baseline) {
    return '${_formatPeriod(baseline.referencePeriodStart)} – '
        '${_formatPeriod(baseline.referencePeriodEnd)}';
  }

  String _formatPeriod(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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
    FloodHistoricalBaseline? baseline,
    DateTime? rainfallObservedAt,
    DateTime? riverObservedAt,
    List<String> dataNotes = const <String>[],
    int rainfallAccumulationWindowHours = 6,
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
        baseline: baseline,
        rainfallObservedAt: rainfallObservedAt,
        riverObservedAt: riverObservedAt,
        dataNotes: dataNotes,
        rainfallAccumulationWindowHours:
            rainfallAccumulationWindowHours,
      );
    }

    final enrichment = await enricher.enrichWithProfile(
      zoneId: zoneId,
      input: input,
    );

    return calculateFloodRisk(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      input: enrichment.input,
      rainfallSource: rainfallSource,
      riverSource: riverSource,
      observedAt: observedAt,
      exposureProfileMissing: enrichment.profile == null,
      baseline: baseline,
      rainfallObservedAt: rainfallObservedAt,
      riverObservedAt: riverObservedAt,
      dataNotes: dataNotes,
      rainfallAccumulationWindowHours:
          rainfallAccumulationWindowHours,
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
    FloodHistoricalBaseline? baseline,
    DateTime? rainfallObservedAt,
    DateTime? riverObservedAt,
    List<String> dataNotes = const <String>[],
    int rainfallAccumulationWindowHours = 6,
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
      baseline: baseline,
      rainfallObservedAt: rainfallObservedAt,
      riverObservedAt: riverObservedAt,
      dataNotes: dataNotes,
      rainfallAccumulationWindowHours:
          rainfallAccumulationWindowHours,
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
    FloodHistoricalBaseline? baseline,
    DateTime? rainfallObservedAt,
    DateTime? riverObservedAt,
    List<String> dataNotes = const <String>[],
    int rainfallAccumulationWindowHours = 6,
  }) async {
    var enrichedInput = input;
    var exposureProfileMissing = false;

    final exposureEnricher = _exposureEnricher;

    if (exposureEnricher != null) {
      final enrichment =
          await exposureEnricher.enrichWithProfile(
        zoneId: zoneId,
        input: enrichedInput,
      );

      enrichedInput = enrichment.input;
      exposureProfileMissing = enrichment.profile == null;
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
      exposureProfileMissing: exposureProfileMissing,
      baseline: baseline,
      rainfallObservedAt: rainfallObservedAt,
      riverObservedAt: riverObservedAt,
      dataNotes: dataNotes,
      rainfallAccumulationWindowHours:
          rainfallAccumulationWindowHours,
    );
  }

  RiskResult calculateFloodRiskFromEnvironmentalData({
    required String id,
    required String locationName,
    required double latitude,
    required double longitude,
    required FloodEnvironmentalData environmentalData,
    required FloodRiskContext context,
    FloodHistoricalBaseline? baseline,
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
      baseline: baseline,
      rainfallObservedAt: environmentalData.rainfallObservedAt,
      riverObservedAt: environmentalData.riverObservedAt,
      dataNotes: environmentalData.dataNotes,
      rainfallAccumulationWindowHours:
          environmentalData.rainfallAccumulationWindowHours,
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
    FloodHistoricalBaseline? baseline,
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
      baseline: baseline,
      rainfallObservedAt: environmentalData.rainfallObservedAt,
      riverObservedAt: environmentalData.riverObservedAt,
      dataNotes: environmentalData.dataNotes,
      rainfallAccumulationWindowHours:
          environmentalData.rainfallAccumulationWindowHours,
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
    FloodHistoricalBaseline? baseline,
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
      baseline: baseline,
      rainfallObservedAt: environmentalData.rainfallObservedAt,
      riverObservedAt: environmentalData.riverObservedAt,
      dataNotes: environmentalData.dataNotes,
      rainfallAccumulationWindowHours:
          environmentalData.rainfallAccumulationWindowHours,
    );
  }
}