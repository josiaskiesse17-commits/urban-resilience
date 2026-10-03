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

typedef _FloodReference = ({
  double? median,
  double? critical,
  String label,
  RiskReferenceType type,
  double? percentile,
});

const String _statisticalBoundNote =
    'référence statistique du même endroit et de la même période de '
    'référence, et non un seuil de sécurité officiel.';

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
  }) : _floodRiskCalculator =
           floodRiskCalculator ?? const FloodRiskCalculator(),
       _hazardRiskCalculator =
           hazardRiskCalculator ?? const HazardRiskCalculator(),
       _observationEnricher =
           observationEnricher ?? const FloodRiskInputObservationEnricher();

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

    final riverReference = _riverReference(input: input, baseline: baseline);

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
              rainfallReference.median != null && rainfallReference.median! > 0
              ? input.rainfallIntensityMmPerHour / rainfallReference.median!
              : null,
          differenceFromReference: rainfallReference.median == null
              ? null
              : input.rainfallIntensityMmPerHour - rainfallReference.median!,
          historicalPercentile: rainfallReference.percentile,
          statisticalCriticalValue: rainfallReference.critical,
          statisticalCriticalLabel: rainfallReference.critical == null
              ? null
              : '95e centile de la même période de référence. '
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
              ? input.rainfallAccumulation6hMm / accumulationReference.median!
              : null,
          differenceFromReference: accumulationReference.median == null
              ? null
              : input.rainfallAccumulation6hMm - accumulationReference.median!,
          historicalPercentile: accumulationReference.percentile,
          statisticalCriticalValue: accumulationReference.critical,
          statisticalCriticalLabel: accumulationReference.critical == null
              ? null
              : '95e centile de la même période de référence. '
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
              riverReference.median != null && riverReference.median! > 0
              ? input.riverDischargeM3s / riverReference.median!
              : null,
          differenceFromReference: riverReference.median == null
              ? null
              : input.riverDischargeM3s - riverReference.median!,
          historicalPercentile: riverReference.percentile,
          statisticalCriticalValue: riverReference.critical,
          statisticalCriticalLabel: riverReference.critical == null
              ? null
              : '95e centile de la même période de référence. '
                    '$_statisticalBoundNote',
          source: riverSource,
          observedAt: riverTime,
        ),
        RiskMeasurement(
          name: 'geographicVulnerability',
          value: input.vulnerabilityScore,
          unit: 'score/100',
          referenceLabel: 'Score de vulnérabilité géographique',
          referenceType: RiskReferenceType.threshold,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
        RiskMeasurement(
          name: 'historicalExposure',
          value: input.historicalExposureScore,
          unit: 'score/100',
          referenceLabel: 'Score d’exposition historique',
          referenceType: RiskReferenceType.historicalAverage,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
      ],
      qualitativeIndicators: [
        if (exposureProfileMissing)
          'Aucun profil d’exposition enregistré n’a été trouvé pour cette '
              'zone. La vulnérabilité géographique et l’exposition '
              'historique n’ont pas pu être évaluées et sont absentes de '
              'ce score.',
        if (baseline != null)
          'Référence statistique : '
              '${_formatPeriod(baseline.referencePeriodStart)} – '
              '${_formatPeriod(baseline.referencePeriodEnd)} '
              '(${baseline.rainfallSampleCount} échantillons horaires de '
              'pluie, ${baseline.riverDischargeSampleCount} échantillons '
              'journaliers de débit fluvial). Les valeurs de référence sont '
              'les centiles de cette période pour les mêmes cellules de '
              'grille ; ce ne sont pas des seuils de sécurité officiels.',
        if (baseline == null)
          'La référence statistique de cet endroit n’a pas été fournie '
              'avec cette évaluation : les valeurs de référence proviennent '
              'uniquement des valeurs de repli.',
        ...dataNotes,
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

  _FloodReference _rainfallReference({
    required FloodRiskInput input,
    required FloodHistoricalBaseline? baseline,
  }) {
    final distribution = baseline?.rainfallHourlyDistribution;

    if (baseline == null || distribution == null) {
      return (
        median: input.rainfallBaselineMmPerHour,
        critical: input.rainfallCriticalMmPerHour,
        label: 'Référence pluviométrique locale fournie avec l’évaluation',
        type: RiskReferenceType.localBaseline,
        percentile: null,
      );
    }

    return (
      median: distribution.median,
      critical: distribution.percentile(95),
      label:
          'Médiane de la référence pluviométrique horaire ERA5 '
          '${_periodLabel(baseline)} '
          '(${distribution.sampleCount} échantillons)',
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
        label: 'Référence pluviométrique 6 h fournie avec l’évaluation',
        type: RiskReferenceType.historicalAverage,
        percentile: null,
      );
    }

    return (
      median: distribution.median,
      critical: distribution.percentile(95),
      label:
          'Médiane de la référence pluviométrique 6 h ERA5 '
          '${_periodLabel(baseline)} '
          '(${distribution.sampleCount} échantillons)',
      type: RiskReferenceType.historicalMedian,
      percentile: distribution.percentileRankOf(input.rainfallAccumulation6hMm),
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
        label: 'Référence de débit fluvial fournie avec l’évaluation',
        type: RiskReferenceType.historicalMedian,
        percentile: null,
      );
    }

    return (
      median: distribution.median,
      critical: distribution.percentile(95),
      label:
          'Médiane de la référence de débit journalier GloFAS '
          '${_periodLabel(baseline)} '
          '(${distribution.sampleCount} échantillons)',
      type: RiskReferenceType.historicalMedian,
      percentile: distribution.percentileRankOf(input.riverDischargeM3s),
    );
  }

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

    final measurements = <RiskMeasurement>[
      ...hazardMeasurements,
      if (input.vulnerabilityScore != null)
        RiskMeasurement(
          name: 'geographicVulnerability',
          value: input.vulnerabilityScore!,
          unit: 'score/100',
          referenceLabel:
              'Vulnérabilité du profil de zone enregistré '
              '(population, infrastructures, équipements critiques)',
          referenceType: RiskReferenceType.threshold,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
      if (input.historicalExposureScore != null)
        RiskMeasurement(
          name: 'historicalExposure',
          value: input.historicalExposureScore!,
          unit: 'score/100',
          referenceLabel: 'Exposition historique enregistrée de cette zone',
          referenceType: RiskReferenceType.historicalAverage,
          source: 'Risk Intelligence',
          observedAt: timestamp,
        ),
    ];

    final indicators = <String>[];

    if (input.hasReferencePeriod) {
      final source = input.referenceSource;

      indicators.add(
        'Référence statistique : '
        '${_formatPeriod(input.referencePeriodStart!)} – '
        '${_formatPeriod(input.referencePeriodEnd!)}'
        '${source == null ? '' : ' ($source)'}. '
        'Les valeurs de référence sont les centiles du même mois calendaire '
        'de cette période ; ce ne sont pas des seuils de sécurité officiels.',
      );
    }

    if (input.partialReference) {
      indicators.add(
        'Au moins une variable avait trop peu d’échantillons dans le mois '
        'calendaire de l’observation : ses statistiques sur toute la '
        'période ont été utilisées à la place.',
      );
    }

    if (input.exposureNote.isNotEmpty) {
      indicators.add(input.exposureNote);
    }

    for (final gap in input.gaps) {
      indicators.add(
        'Non mesuré : ${gap.label} — ${gap.reason}. Il est signalé comme '
        'manquant du score, jamais comme un zéro.',
      );
    }

    for (final variable in input.variables) {
      if (variable.score != null) {
        continue;
      }

      indicators.add(
        'Non pris en compte : '
        '${RiskMeasurementLabel.of(name: variable.name, measurementPeriod: variable.measurementPeriod, unit: variable.unit)} — sa valeur mesurée reste dans les preuves, mais '
        '${variable.informational ? 'aucune référence statistique n’existe pour cette variable' : 'aucune référence statistique exploitable n’a pu être '
                  'construite pour cet endroit'}, elle est donc exclue du '
        'score au lieu d’être comptée comme un zéro.',
      );
    }

    if (!assessment.hazardAvailable) {
      indicators.add(
        'Aucune variable environnementale de ce risque n’a pu être évaluée '
        'pour cet endroit : le facteur de risque est indisponible et '
        'l’évaluation repose uniquement sur les facteurs d’exposition '
        'disponibles.',
      );
    }

    if (assessment.excludedWeight > 0) {
      indicators.add(
        'Des variables représentant '
        '${(assessment.excludedWeight * 100).toStringAsFixed(0)} % du poids '
        'du risque n’avaient pas de référence exploitable et ont été '
        'exclues ; les poids restants ont été renormalisés sur les '
        'variables disponibles.',
      );
    }

    if (assessment.factorWeights.isNotEmpty) {
      final weights = assessment.factorWeights.entries
          .map(
            (entry) =>
                '${_factorWeightLabel(entry.key)} '
                '${entry.value.toStringAsFixed(2)}',
          )
          .join(', ');

      indicators.add(
        'Poids du score appliqués après renormalisation : $weights.',
      );
    }

    indicators.addAll(input.notes);

    for (final limitation in input.limitations) {
      indicators.add('Limite du modèle : $limitation');
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
        confirmedObservationCount: input.confirmedObservationCount,
        collectedAt: timestamp,
      ),
      updatedAt: timestamp,
    );
  }

  String _periodLabel(FloodHistoricalBaseline baseline) {
    return '${_formatPeriod(baseline.referencePeriodStart)} – '
        '${_formatPeriod(baseline.referencePeriodEnd)}';
  }

  String _factorWeightLabel(String key) {
    return switch (key) {
      'hazard' => 'risque',
      'vulnerability' => 'vulnérabilité',
      'historicalExposure' => 'exposition historique',
      _ => key,
    };
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
        rainfallAccumulationWindowHours: rainfallAccumulationWindowHours,
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
      rainfallAccumulationWindowHours: rainfallAccumulationWindowHours,
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
      rainfallAccumulationWindowHours: rainfallAccumulationWindowHours,
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
      final enrichment = await exposureEnricher.enrichWithProfile(
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
      rainfallAccumulationWindowHours: rainfallAccumulationWindowHours,
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

  Future<RiskResult> calculateFloodRiskFromEnvironmentalDataWithExposure({
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
