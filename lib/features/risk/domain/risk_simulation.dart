import 'flood_risk_calculator.dart';
import 'flood_risk_input.dart';
import 'hazard_catalog.dart';
import 'hazard_risk_calculator.dart';
import 'hazard_risk_id.dart';
import 'hazard_risk_input.dart';
import 'hazard_type.dart';
import 'hazard_variable.dart';
import 'risk_factor_score.dart';
import 'risk_factors.dart';
import 'risk_measurement.dart';
import 'risk_measurement_label.dart';
import 'risk_result.dart';
import 'risk_zone.dart';

/// One control of the What-If simulation.
///
/// The variable carries the statistical reference of the real assessment, so
/// [scoreFor] applies the exact formula the stored result was computed with.
class RiskSimulationVariable {
  const RiskSimulationVariable({
    required this.name,
    required this.label,
    required this.unit,
    required this.currentValue,
    required this.weight,
    required this.inverted,
    this.referenceValue,
    this.criticalValue,
    this.informational = false,
  });

  final String name;
  final String label;
  final String unit;

  /// Value of the stored assessment.
  final double currentValue;

  final double weight;
  final bool inverted;
  final double? referenceValue;
  final double? criticalValue;
  final bool informational;

  /// True when the value can be varied and re-scored with the same engine.
  bool get isAdjustable {
    if (informational) {
      return false;
    }

    final central = referenceValue;
    final outer = criticalValue;

    if (central == null || outer == null) {
      return false;
    }

    return inverted ? central > outer : outer > central;
  }

  /// Lowest value of the simulation control: half of the smallest reference
  /// of the variable, never below zero.
  double get lowerBound {
    final lowest = _triple.reduce(
      (left, right) => left < right ? left : right,
    );
    final bound = lowest * 0.5;

    return bound < 0 ? 0 : bound;
  }

  /// Highest value of the simulation control: one and a half times the
  /// largest reference of the variable.
  double get upperBound {
    final highest = _triple.reduce(
      (left, right) => left > right ? left : right,
    );
    final bound = highest * 1.5;

    return bound <= 0 ? 1 : bound;
  }

  List<double> get _triple => <double>[
        currentValue,
        referenceValue ?? currentValue,
        criticalValue ?? currentValue,
      ];

  /// Score the hypothetical [value] would produce with the same formula as
  /// the real assessment.
  double? scoreFor(double value) {
    if (!isAdjustable) {
      return null;
    }

    return variableFor(value).score;
  }

  /// Rebuilds the hazard variable the engine consumes.
  HazardVariable variableFor(double value) {
    return HazardVariable(
      name: name,
      label: label,
      value: value,
      unit: unit,
      measurementPeriod: '',
      weight: weight,
      referenceValue: referenceValue,
      statisticalCriticalValue: criticalValue,
      inverted: inverted,
      informational: informational,
    );
  }
}

/// The adjustable inputs of one stored assessment.
class RiskSimulationModel {
  const RiskSimulationModel({
    required this.hazard,
    required this.variables,
    required this.currentScore,
    required this.currentLevel,
    required this.factorBreakdownMissing,
    this.unavailableReason,
    this.vulnerabilityScore,
    this.historicalExposureScore,
    this.observationScore = 0,
    this.observationCount = 0,
    this.confirmedObservationCount = 0,
  });

  final HazardType hazard;
  final List<RiskSimulationVariable> variables;

  /// Score and level actually stored, used as the comparison base.
  final double currentScore;
  final RiskLevel currentLevel;

  /// True when the stored document predates the factor breakdown, so the
  /// simulation can only re-run the environmental variables.
  final bool factorBreakdownMissing;

  /// Why no simulation can be run, in plain language.
  final String? unavailableReason;

  final double? vulnerabilityScore;
  final double? historicalExposureScore;
  final double observationScore;
  final int observationCount;
  final int confirmedObservationCount;

  List<RiskSimulationVariable> get adjustable => variables
      .where((variable) => variable.isAdjustable)
      .toList(growable: false);

  List<RiskSimulationVariable> get fixed => variables
      .where((variable) => !variable.isAdjustable)
      .toList(growable: false);

  List<String> get limitations => HazardCatalog.of(hazard).limitations;

  bool get isSimulatable =>
      unavailableReason == null && adjustable.isNotEmpty;
}

/// Deterministic outcome of one simulation.
///
/// Nothing here is saved: the outcome lives in the What-If section only, and
/// the stored assessment stays untouched.
class RiskSimulationOutcome {
  const RiskSimulationOutcome({
    required this.model,
    required this.values,
    required this.score,
    required this.level,
    required this.factors,
  });

  final RiskSimulationModel model;

  /// Hypothetical value used for every variable.
  final Map<String, double> values;

  final double score;
  final RiskLevel level;

  /// Factor scores the same engine produced for the hypothetical inputs.
  final List<RiskFactorScore> factors;

  double get difference => score - model.currentScore;

  bool get levelChanged => level != model.currentLevel;

  bool get riskIncreased => difference > 0;

  bool get riskDecreased => difference < 0;
}

/// Re-runs the stored assessment with hypothetical inputs.
///
/// The simulation consumes the same evidence, references and calculators as
/// the real pipeline: `HazardRiskCalculator` for the generic hazards and
/// `FloodRiskCalculator` for flooding. It performs no network call and no AI
/// request, so the same inputs always produce the same outcome.
class RiskSimulationService {
  const RiskSimulationService({
    HazardRiskCalculator? hazardRiskCalculator,
    FloodRiskCalculator? floodRiskCalculator,
  })  : _hazardRiskCalculator =
            hazardRiskCalculator ?? const HazardRiskCalculator(),
        _floodRiskCalculator =
            floodRiskCalculator ?? const FloodRiskCalculator();

  final HazardRiskCalculator _hazardRiskCalculator;
  final FloodRiskCalculator _floodRiskCalculator;

  /// Variables of the flooding pipeline with their weight inside the hazard
  /// factor. They mirror `FloodRiskCalculator`.
  static const List<({String name, double weight})> floodVariables =
      <({String name, double weight})>[
    (name: 'rainfallIntensity', weight: 0.40),
    (name: 'rainfallAccumulation6h', weight: 0.30),
    (name: 'riverDischarge', weight: 0.30),
  ];

  /// Builds the adjustable inputs of a stored assessment, or null when the
  /// hazard of the document cannot be determined.
  ///
  /// The controls come from the evidence measurements of the document, so a
  /// variable that was not measured never appears, and the statistical
  /// reference of each control is the reference of the real assessment.
  RiskSimulationModel? modelFrom(RiskResult result) {
    final hazard = _hazardOf(result);
    final definition = HazardCatalog.of(hazard);

    final measurements = <String, RiskMeasurement>{
      for (final measurement in result.evidence.measurements)
        measurement.name: measurement,
    };

    final variables = <RiskSimulationVariable>[];

    if (definition.legacyPipeline) {
      for (final spec in floodVariables) {
        final measurement = measurements[spec.name];

        if (measurement == null) {
          continue;
        }

        variables.add(
          _variableFrom(
            measurement: measurement,
            weight: spec.weight,
          ),
        );
      }
    } else {
      for (final spec in definition.variables) {
        final measurement = measurements[spec.name];

        if (measurement == null) {
          continue;
        }

        variables.add(
          _variableFrom(
            measurement: measurement,
            weight: spec.weight,
            inverted: spec.inverted,
            informational: spec.informational,
          ),
        );
      }
    }

    final entries = result.factors.entries;
    final factorScores = <String, RiskFactorScore>{
      for (final entry in entries) entry.name: entry,
    };

    final missingFloodReference = definition.legacyPipeline &&
        floodVariables.any((spec) {
          final measurement = measurements[spec.name];

          return measurement == null ||
              measurement.referenceValue == null ||
              measurement.statisticalCriticalValue == null;
        });

    final adjustableCount =
        variables.where((variable) => variable.isAdjustable).length;

    return RiskSimulationModel(
      hazard: hazard,
      variables: variables,
      currentScore: result.riskScore,
      currentLevel: result.riskLevel,
      factorBreakdownMissing: entries.isEmpty,
      unavailableReason: missingFloodReference
          ? 'The stored flooding assessment does not contain the complete '
              'rainfall and river reference, so it cannot be re-run.'
          : adjustableCount == 0
              ? 'None of the stored measurements of this hazard has a '
                  'statistical reference, so no simulated score can be '
                  'computed.'
              : null,
      vulnerabilityScore: _factorScore(
        name: 'geographicVulnerability',
        factors: result.factors,
        storedLegacyValue: result.factors.geographicVulnerability,
      ),
      historicalExposureScore: _factorScore(
        name: 'historicalExposure',
        factors: result.factors,
        storedLegacyValue: result.factors.historicalExposure,
      ),
      observationScore: _observationScore(
        factorScores: factorScores,
        result: result,
      ),
      observationCount: result.evidence.observationCount,
      confirmedObservationCount:
          result.evidence.confirmedObservationCount,
    );
  }

  /// Re-runs the assessment of [model] with [values] overriding the current
  /// value of the variables they name. Every other control keeps its stored
  /// value. Returns null when the model cannot be simulated.
  ///
  /// The outcome is a hypothetical score produced by the same engine as the
  /// stored result: it is never written to `risk_results` and never sent to
  /// the AI analyst.
  RiskSimulationOutcome? simulate({
    required RiskSimulationModel model,
    Map<String, double> values = const <String, double>{},
  }) {
    if (!model.isSimulatable) {
      return null;
    }

    final applied = <String, double>{
      for (final variable in model.variables)
        variable.name: values[variable.name] ?? variable.currentValue,
    };

    if (model.hazard == HazardType.flooding) {
      return _simulateFlood(model: model, values: applied);
    }

    final assessment = _hazardRiskCalculator.calculate(
      HazardRiskInput(
        hazard: model.hazard,
        primaryFactorLabel:
            HazardCatalog.of(model.hazard).primaryFactorLabel,
        variables: model.variables
            .map(
              (variable) => variable.variableFor(
                applied[variable.name]!,
              ),
            )
            .toList(growable: false),
        vulnerabilityScore: model.vulnerabilityScore,
        historicalExposureScore: model.historicalExposureScore,
        observationScore: model.observationScore,
        observationCount: model.observationCount,
        confirmedObservationCount: model.confirmedObservationCount,
      ),
    );

    return RiskSimulationOutcome(
      model: model,
      values: applied,
      score: assessment.overallScore,
      level: assessment.riskLevel,
      factors: assessment.factors.entries,
    );
  }

  RiskSimulationOutcome? _simulateFlood({
    required RiskSimulationModel model,
    required Map<String, double> values,
  }) {
    final input = _floodInput(model: model, values: values);

    if (input == null) {
      return null;
    }

    final calculation = _floodRiskCalculator.calculate(input);

    return RiskSimulationOutcome(
      model: model,
      values: values,
      score: calculation.overallScore,
      level: calculation.riskLevel,
      factors: calculation.factors.entries,
    );
  }

  /// Rebuilds the flooding input from the stored references.
  ///
  /// The three environmental variables come from the simulation values, their
  /// baseline and critical bound from the reference of the stored
  /// assessment. The exposure factors are the ones the stored flooding score
  /// used: the flooding calculator always applies all four factors, so an
  /// unavailable one was part of the stored score with the value it displays.
  FloodRiskInput? _floodInput({
    required RiskSimulationModel model,
    required Map<String, double> values,
  }) {
    final byName = <String, RiskSimulationVariable>{
      for (final variable in model.variables) variable.name: variable,
    };

    final rainfall = byName['rainfallIntensity'];
    final accumulation = byName['rainfallAccumulation6h'];
    final river = byName['riverDischarge'];

    if (rainfall == null || accumulation == null || river == null) {
      return null;
    }

    final rainfallBaseline = rainfall.referenceValue;
    final rainfallCritical = rainfall.criticalValue;
    final accumulationBaseline = accumulation.referenceValue;
    final accumulationCritical = accumulation.criticalValue;
    final riverBaseline = river.referenceValue;
    final riverCritical = river.criticalValue;

    if (rainfallBaseline == null ||
        rainfallCritical == null ||
        accumulationBaseline == null ||
        accumulationCritical == null ||
        riverBaseline == null ||
        riverCritical == null) {
      return null;
    }

    return FloodRiskInput(
      rainfallIntensityMmPerHour: values['rainfallIntensity']!,
      rainfallBaselineMmPerHour: rainfallBaseline,
      rainfallCriticalMmPerHour: rainfallCritical,
      rainfallAccumulation6hMm: values['rainfallAccumulation6h']!,
      rainfallAccumulation6hBaselineMm: accumulationBaseline,
      rainfallAccumulation6hCriticalMm: accumulationCritical,
      riverDischargeM3s: values['riverDischarge']!,
      riverDischargeBaselineM3s: riverBaseline,
      riverDischargeCriticalM3s: riverCritical,
      vulnerabilityScore: model.vulnerabilityScore ?? 0,
      historicalExposureScore: model.historicalExposureScore ?? 0,
      observationScore: model.observationScore,
      observationCount: model.observationCount,
      confirmedObservationCount: model.confirmedObservationCount,
    );
  }

  RiskSimulationVariable _variableFrom({
    required RiskMeasurement measurement,
    required double weight,
    bool inverted = false,
    bool informational = false,
  }) {
    return RiskSimulationVariable(
      name: measurement.name,
      label: RiskMeasurementLabel.of(
        name: measurement.name,
        measurementPeriod: measurement.measurementPeriod,
        unit: measurement.unit,
      ),
      unit: measurement.unit,
      currentValue: measurement.value,
      weight: weight,
      inverted: inverted,
      referenceValue: measurement.referenceValue,
      criticalValue: measurement.statisticalCriticalValue,
      informational: informational,
    );
  }

  /// Score of an exposure factor of the stored result.
  ///
  /// The factor breakdown of the document is authoritative. A document written
  /// before the breakdown existed only carries the four legacy scores: a
  /// positive score is then a real measurement, while a zero cannot be told
  /// apart from a factor that was never measured, so it is left out of the
  /// simulation instead of being counted as a zero.
  double? _factorScore({
    required String name,
    required RiskFactors factors,
    required double storedLegacyValue,
  }) {
    for (final entry in factors.entries) {
      if (entry.name == name) {
        return entry.usedInScore ? entry.score : null;
      }
    }

    return storedLegacyValue > 0 ? storedLegacyValue : null;
  }

  double _observationScore({
    required Map<String, RiskFactorScore> factorScores,
    required RiskResult result,
  }) {
    final entry = factorScores['citizenObservationRisk'];

    if (entry != null) {
      return entry.usedInScore ? entry.score ?? 0 : 0;
    }

    return result.evidence.observationCount > 0 ||
            result.factors.currentObservations > 0
        ? result.factors.currentObservations
        : 0;
  }

  /// Hazard of a stored result: the label written by the pipeline, then the
  /// suffix of the risk id, then flooding for a legacy document.
  HazardType _hazardOf(RiskResult result) {
    final fromLabel = HazardType.fromLabel(result.hazardType);

    if (fromLabel != null) {
      return fromLabel;
    }

    return HazardRiskId.hazardOf(result.id);
  }
}
