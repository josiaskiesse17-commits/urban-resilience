import 'hazard_risk_input.dart';
import 'hazard_variable.dart';
import 'risk_factor_score.dart';
import 'risk_factors.dart';
import 'risk_measurement_label.dart';
import 'risk_score_utils.dart';
import 'risk_zone.dart';

class HazardVariableScore {
  const HazardVariableScore({
    required this.name,
    required this.label,
    required this.weight,
    required this.usedInScore,
    this.score,
  });

  final String name;
  final String label;

  final double weight;

  final bool usedInScore;

  final double? score;
}

class HazardRiskAssessment {
  const HazardRiskAssessment({
    required this.hazardScore,
    required this.overallScore,
    required this.hazardAvailable,
    required this.riskLevel,
    required this.factors,
    required this.variableScores,
    required this.excludedWeight,
    required this.factorWeights,
  });

  final double hazardScore;
  final bool hazardAvailable;
  final double overallScore;
  final RiskLevel riskLevel;
  final RiskFactors factors;
  final List<HazardVariableScore> variableScores;

  final double excludedWeight;

  final Map<String, double> factorWeights;
}

class HazardRiskCalculator {
  const HazardRiskCalculator();

  static const double hazardWeight = 0.40;
  static const double vulnerabilityWeight = 0.25;
  static const double historicalExposureWeight = 0.15;
  static const double observationWeight = 0.20;

  HazardRiskAssessment calculate(HazardRiskInput input) {
    final variableScores = <HazardVariableScore>[];
    final hazardComponents = <({double value, double weight})>[];
    final variableEntries = <RiskFactorScore>[];

    var excludedWeight = 0.0;

    for (final variable in input.variables) {
      final score = variable.score;

      if (score == null) {
        excludedWeight += variable.weight;

        variableScores.add(
          HazardVariableScore(
            name: variable.name,
            label: variable.label,
            weight: variable.weight,
            usedInScore: false,
          ),
        );

        continue;
      }

      hazardComponents.add((value: score, weight: variable.weight));

      variableScores.add(
        HazardVariableScore(
          name: variable.name,
          label: variable.label,
          weight: variable.weight,
          usedInScore: true,
          score: score,
        ),
      );

      variableEntries.add(
        RiskFactorScore(
          name: variable.name,
          label: _factorLabel(variable),
          score: score,
          weight: variable.weight,
          usedInScore: true,
        ),
      );
    }

    final variableNames = input.variables
        .map((variable) => variable.name)
        .toSet();

    for (final gap in input.gaps) {
      if (!variableNames.add(gap.name)) {
        continue;
      }

      variableEntries.add(
        RiskFactorScore(
          name: gap.name,
          label: RiskMeasurementLabel.of(name: gap.name),
          weight: 0,
          usedInScore: false,
          unavailableReason: gap.reason,
        ),
      );
    }

    final hazardAvailable = hazardComponents.isNotEmpty;

    final hazardScore = hazardAvailable
        ? RiskScoreUtils.weightedAverage(hazardComponents)
        : 0.0;

    final overallComponents = <({double value, double weight})>[];

    final factorWeights = <String, double>{};

    if (hazardAvailable) {
      overallComponents.add(
        (value: hazardScore, weight: hazardWeight),
      );

      factorWeights['hazard'] = hazardWeight;
    }

    final vulnerability = input.vulnerabilityScore;

    if (vulnerability != null) {
      overallComponents.add(
        (
          value: RiskScoreUtils.clamp(vulnerability),
          weight: vulnerabilityWeight,
        ),
      );

      factorWeights['vulnerability'] = vulnerabilityWeight;
    }

    final historicalExposure = input.historicalExposureScore;

    if (historicalExposure != null) {
      overallComponents.add(
        (
          value: RiskScoreUtils.clamp(historicalExposure),
          weight: historicalExposureWeight,
        ),
      );

      factorWeights['historicalExposure'] = historicalExposureWeight;
    }

    final observationScore = RiskScoreUtils.clamp(input.observationScore);

    overallComponents.add(
      (
        value: observationScore,
        weight: observationWeight,
      ),
    );

    factorWeights['currentObservations'] = observationWeight;

    final overallScore = RiskScoreUtils.weightedAverage(overallComponents);

    final entries = <RiskFactorScore>[
      RiskFactorScore(
        name: 'hazard',
        label: input.primaryFactorLabel,
        score: hazardAvailable ? hazardScore : null,
        weight: hazardAvailable ? hazardWeight : 0,
        usedInScore: hazardAvailable,
        componentNames: variableEntries
            .where((entry) => entry.usedInScore)
            .map((entry) => entry.name)
            .toList(growable: false),
        unavailableReason: hazardAvailable
            ? null
            : 'none of the environmental variables of '
                  '${input.hazard.label.toLowerCase()} could be scored for '
                  'this location',
      ),
      ...variableEntries,
      RiskFactorScore(
        name: 'geographicVulnerability',
        label: RiskMeasurementLabel.of(name: 'geographicVulnerability'),
        score: vulnerability,
        weight: vulnerability == null ? 0 : vulnerabilityWeight,
        usedInScore: vulnerability != null,
        unavailableReason: vulnerability == null
            ? 'the stored exposure profile of this zone did not provide a '
                  'vulnerability score'
            : null,
      ),
      RiskFactorScore(
        name: 'historicalExposure',
        label: RiskMeasurementLabel.of(name: 'historicalExposure'),
        score: historicalExposure,
        weight: historicalExposure == null ? 0 : historicalExposureWeight,
        usedInScore: historicalExposure != null,
        unavailableReason: historicalExposure == null
            ? 'no historical exposure of this zone is stored for '
                  '${input.hazard.label.toLowerCase()}, and the flood exposure '
                  'of the same zone is not a measurement of this hazard'
            : null,
      ),
      RiskFactorScore(
        name: 'currentObservations',
        label: RiskMeasurementLabel.of(name: 'currentObservations'),
        score: observationScore,
        weight: observationWeight,
        usedInScore: true,
        unavailableReason: null,
      ),
    ];

    return HazardRiskAssessment(
      hazardScore: hazardScore,
      hazardAvailable: hazardAvailable,
      overallScore: overallScore,
      riskLevel: RiskScoreUtils.riskLevelFromScore(overallScore),
      factors: RiskFactors(
        rainfall: hazardScore,
        geographicVulnerability: vulnerability,
        historicalExposure: historicalExposure,
        currentObservations: observationScore,
        primaryFactorLabel: input.primaryFactorLabel,
        entries: entries,
      ),
      variableScores: variableScores,
      excludedWeight: excludedWeight,
      factorWeights: factorWeights,
    );
  }

  static String _factorLabel(HazardVariable variable) {
    return RiskMeasurementLabel.of(
      name: variable.name,
      measurementPeriod: variable.measurementPeriod,
      unit: variable.unit,
    );
  }
}