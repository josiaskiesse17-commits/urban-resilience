import 'risk_zone.dart';

class RiskScoreUtils {
  const RiskScoreUtils._();

  static double clamp(
    double value, {
    double min = 0,
    double max = 100,
  }) {
    if (value < min) {
      return min;
    }

    if (value > max) {
      return max;
    }

    return value;
  }

  static double linearScore({
    required double value,
    required double baseline,
    required double critical,
  }) {
    if (critical <= baseline) {
      throw ArgumentError(
        'Critical value must be greater than baseline.',
      );
    }

    if (value <= baseline) {
      return 0;
    }

    if (value >= critical) {
      return 100;
    }

    return clamp(
      ((value - baseline) / (critical - baseline)) * 100,
    );
  }

  /// Score of a variable where a *low* value is the risk (soil moisture,
  /// rainfall deficit, ...).
  ///
  /// The two bounds are statistical references of the same kind as the ones
  /// used by [linearScore]: [statisticalHigh] is the central reference of the
  /// variable and [statisticalLow] its outer reference (typically the 5th
  /// percentile of the reference period). The result is 0 at or above the
  /// central reference and 100 at or below the outer one.
  static double invertedLinearScore({
    required double value,
    required double statisticalLow,
    required double statisticalHigh,
  }) {
    return 100 -
        linearScore(
          value: value,
          baseline: statisticalLow,
          critical: statisticalHigh,
        );
  }

  static double weightedAverage(
    List<({double value, double weight})> components,
  ) {
    if (components.isEmpty) {
      return 0;
    }

    final totalWeight = components.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );

    if (totalWeight <= 0) {
      return 0;
    }

    final weightedTotal = components.fold<double>(
      0,
      (sum, item) => sum + item.value * item.weight,
    );

    return clamp(weightedTotal / totalWeight);
  }

  static RiskLevel riskLevelFromScore(double score) {
    final normalized = clamp(score);

    if (normalized >= 75) {
      return RiskLevel.critical;
    }

    if (normalized >= 50) {
      return RiskLevel.high;
    }

    if (normalized >= 25) {
      return RiskLevel.medium;
    }

    return RiskLevel.low;
  }
}