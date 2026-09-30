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