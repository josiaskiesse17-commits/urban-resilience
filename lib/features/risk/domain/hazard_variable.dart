import 'historical_distribution.dart';
import 'risk_measurement.dart';
import 'risk_score_utils.dart';

/// One hazard variable the model actually received a value for.
///
/// Every field is either measured/derived from a real source or explicitly
/// absent. The class never holds a placeholder: a variable that could not be
/// obtained is reported as a [HazardVariableGap] instead.
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

  /// Name written to the evidence (`windGusts10mMax6h`).
  final String name;

  /// Human readable label used by the explanations.
  final String label;

  final double value;
  final String unit;

  /// `instant`, `6h`, `24h`, `72h`, `14d`, `30d`.
  final String measurementPeriod;

  /// Share of the hazard score of this hazard. See the hazard catalog.
  final double weight;

  /// Central statistical reference of the variable (median of the reference
  /// period, or of the same calendar month when the hazard needs a seasonal
  /// reference).
  final double? referenceValue;

  /// Outer statistical reference used to bound the score: the 95th percentile
  /// for a variable where a high value is the risk, the 5th percentile for an
  /// inverted one. It is a statistical reference, never an official safety
  /// threshold.
  final double? statisticalCriticalValue;

  final String? referenceLabel;
  final RiskReferenceType? referenceType;

  /// Where [value] sits inside the reference distribution, in percent.
  final double? historicalPercentile;

  /// True when a *low* value means *high* risk (soil moisture, rainfall
  /// deficit).
  final bool inverted;

  final String? source;
  final DateTime? observedAt;

  /// True when the value is computed from measurements (accumulation over a
  /// window, apparent temperature, ...) instead of being read directly.
  final bool isDerived;
  final String? derivationNote;

  /// True for a variable that is reported in the evidence but deliberately
  /// excluded from the score because no historical reference exists for it.
  final bool informational;

  /// Whether the variable can be scored against a statistical reference.
  bool get isScorable {
    if (informational) {
      return false;
    }

    final central = referenceValue;
    final outer = statisticalCriticalValue;

    if (central == null || outer == null) {
      return false;
    }

    // A reference whose two bounds are equal carries no information; scoring
    // it would turn a flat historical series into a fabricated gradient.
    return inverted ? central > outer : outer > central;
  }

  /// Risk score of this variable, `0` (at or below reference) to `100`
  /// (at or beyond the statistical critical reference).
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

  /// Builds a distribution-backed variable, filling the percentile of the
  /// live value inside the reference distribution.
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
      statisticalCriticalValue:
          distribution.percentile(outerPercentile),
      referenceLabel: referenceLabel,
      referenceType: referenceType,
      historicalPercentile:
          distribution.percentileRankOf(value),
      inverted: inverted,
      source: source,
      observedAt: observedAt,
      isDerived: isDerived,
      derivationNote: derivationNote,
    );
  }
}

/// A hazard variable the model needed but could not obtain.
///
/// It is kept in the result so a missing input is reported as missing instead
/// of silently contributing a zero to the score.
class HazardVariableGap {
  const HazardVariableGap({
    required this.name,
    required this.label,
    required this.reason,
  });

  final String name;
  final String label;

  /// Why the value is absent, in plain language.
  final String reason;
}
