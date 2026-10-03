import 'hazard_risk_input.dart';
import 'hazard_variable.dart';
import 'risk_factor_score.dart';
import 'risk_factors.dart';
import 'risk_measurement_label.dart';
import 'risk_score_utils.dart';
import 'risk_zone.dart';

/// Contribution of one hazard variable to the hazard score.
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

  /// Nominal weight of the variable inside the hazard score.
  final double weight;

  /// False when the variable had no usable statistical reference (or no
  /// value), in which case it is reported but does not affect the score.
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

  /// Total weight of the variables that carried no usable reference.
  final double excludedWeight;

  /// Weights actually applied to the overall score, keyed by factor name.
  final Map<String, double> factorWeights;
}

/// Generic hazard engine.
///
/// It reuses the shared risk formula of the flooding calculator
/// (`hazard 0.40`, `vulnerability 0.25`, `historical exposure 0.15` —
/// citizen observations are not a risk factor) but averages only the factors
/// that are actually available: a factor that could not be measured is
/// excluded instead of entering the score as a fabricated zero, and its
/// weight is redistributed over the remaining factors.
class HazardRiskCalculator {
  const HazardRiskCalculator();

  static const double hazardWeight = 0.40;
  static const double vulnerabilityWeight = 0.25;
  static const double historicalExposureWeight = 0.15;

  HazardRiskAssessment calculate(HazardRiskInput input) {
    final variableScores = <HazardVariableScore>[];
    final hazardComponents =
        <({double value, double weight})>[];
    final variableEntries = <RiskFactorScore>[];

    var excludedWeight = 0.0;

    for (final variable in input.variables) {
      final score = variable.score;

      if (score == null) {
        // The variable was measured, so its real value stays in the evidence,
        // but it carries no usable statistical reference: it is excluded from
        // the score instead of being counted as zero, and it is not presented
        // as a factor either. The evidence reports the exclusion explicitly
        // ("Not scored: ..."), so a variable that played no role in the score
        // is never shown as an unavailable number.
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

      hazardComponents.add(
        (
          value: score,
          weight: variable.weight,
        ),
      );

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

    // A variable the hazard model needed but never received becomes an
    // explicit factor entry with no score and the reason why: a missing
    // measurement is reported as missing (never as zero, never silently
    // dropped) and has no evidence measurement of its own.
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

    final overallComponents =
        <({double value, double weight})>[];

    final factorWeights = <String, double>{};

    if (hazardAvailable) {
      overallComponents.add(
        (
          value: hazardScore,
          weight: hazardWeight,
        ),
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

    final historicalExposure =
        input.historicalExposureScore;

    if (historicalExposure != null) {
      overallComponents.add(
        (
          value: RiskScoreUtils.clamp(historicalExposure),
          weight: historicalExposureWeight,
        ),
      );

      factorWeights['historicalExposure'] =
          historicalExposureWeight;
    }

    final overallScore =
        RiskScoreUtils.weightedAverage(overallComponents);

    // The factors the user sees, in the order the section renders them: the
    // weighted hazard factor first, then the environmental variables it is
    // built from (measured and scored, plus the explicitly missing ones),
    // then the exposure factors. A factor that could not be scored keeps a
    // null score and the reason why; a variable that was measured but has no
    // usable reference is reported in the evidence only, never as a factor.
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
        weight: historicalExposure == null
            ? 0
            : historicalExposureWeight,
        usedInScore: historicalExposure != null,
        unavailableReason: historicalExposure == null
            ? 'no historical exposure of this zone is stored for '
                '${input.hazard.label.toLowerCase()}, and the flood exposure '
                'of the same zone is not a measurement of this hazard'
            : null,
      ),
    ];

    return HazardRiskAssessment(
      hazardScore: hazardScore,
      hazardAvailable: hazardAvailable,
      overallScore: overallScore,
      riskLevel: RiskScoreUtils.riskLevelFromScore(overallScore),
      factors: RiskFactors(
        rainfall: hazardScore,
        geographicVulnerability: vulnerability ?? 0,
        historicalExposure: historicalExposure ?? 0,
        currentObservations: 0,
        primaryFactorLabel: input.primaryFactorLabel,
        entries: entries,
      ),
      variableScores: variableScores,
      excludedWeight: excludedWeight,
      factorWeights: factorWeights,
    );
  }

  /// Wording shared with the Evidence section: the same variable must not be
  /// named differently in the factors and in the evidence.
  static String _factorLabel(HazardVariable variable) {
    return RiskMeasurementLabel.of(
      name: variable.name,
      measurementPeriod: variable.measurementPeriod,
      unit: variable.unit,
    );
  }
}
