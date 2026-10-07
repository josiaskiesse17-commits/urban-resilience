import 'historical_distribution.dart';
import 'risk_measurement.dart';
import 'risk_score_utils.dart';

class HazardVariable {
  const HazardVariable({
    required this.name,
    required this.label,
    required this.value,
    required this.unit,
    required this.measurementPeriod,
    required this.weight,
    this.referenceValue,
    this.statisticalCriticalValue,
    this.referenceLabel,
    this.referenceType,
    this.historicalPercentile,
    this.inverted = false,
    this.source,
    this.observedAt,
    this.isDerived = false,
    this.derivationNote,
    this.informational = false,
  });

  final String name;

  final String label;

  final double value;
  final String unit;

  final String measurementPeriod;

  final double weight;

  final double? referenceValue;

  final double? statisticalCriticalValue;

  final String? referenceLabel;
  final RiskReferenceType? referenceType;

  final double? historicalPercentile;

  final bool inverted;

  final String? source;
  final DateTime? observedAt;

  final bool isDerived;
  final String? derivationNote;

  final bool informational;

  bool get isScorable {
    if (informational) {
      return false;
    }

    final central = referenceValue;
    final outer = statisticalCriticalValue;

    if (central == null || outer == null) {
      return false;
    }

    return inverted ? central > outer : outer > central;
  }

  double? get score {
    if (!isScorable) {
      return null;
    }

    final central = referenceValue!;
    final outer = statisticalCriticalValue!;

    if (inverted) {
      return RiskScoreUtils.invertedLinearScore(
        value: value,
        statisticalLow: outer,
        statisticalHigh: central,
      );
    }

    return RiskScoreUtils.linearScore(
      value: value,
      baseline: central,
      critical: outer,
    );
  }

  static HazardVariable fromDistribution({
    required String name,
    required String label,
    required double value,
    required String unit,
    required String measurementPeriod,
    required double weight,
    required HistoricalDistribution distribution,
    required double centralPercentile,
    required double outerPercentile,
    required String referenceLabel,
    required RiskReferenceType referenceType,
    bool inverted = false,
    String? source,
    DateTime? observedAt,
    bool isDerived = false,
    String? derivationNote,
  }) {
    return HazardVariable(
      name: name,
      label: label,
      value: value,
      unit: unit,
      measurementPeriod: measurementPeriod,
      weight: weight,
      referenceValue: distribution.percentile(centralPercentile),
      statisticalCriticalValue: distribution.percentile(outerPercentile),
      referenceLabel: referenceLabel,
      referenceType: referenceType,
      historicalPercentile: distribution.percentileRankOf(value),
      inverted: inverted,
      source: source,
      observedAt: observedAt,
      isDerived: isDerived,
      derivationNote: derivationNote,
    );
  }
}

class HazardVariableGap {
  const HazardVariableGap({
    required this.name,
    required this.label,
    required this.reason,
  });

  final String name;
  final String label;

  final String reason;
}
