import 'hazard_series_utils.dart';
import 'hazard_type.dart';
import 'historical_distribution.dart';

/// Distribution used for one observation of a variable.
typedef HazardBaselineSlice = ({
  HistoricalDistribution distribution,
  int? month,
  bool usedSeasonalBucket,
});

/// Statistical reference of one hazard variable.
class HazardBaselineVariable {
  const HazardBaselineVariable({
    required this.name,
    required this.unit,
    required this.window,
    required this.overall,
    required this.byMonth,
    required this.seasonal,
  });

  /// Smallest number of samples a seasonal bucket needs to be preferred over
  /// the whole reference period.
  static const int minimumSeasonalSamples = 30;

  final String name;
  final String unit;
  final HazardWindow window;

  /// Reference distribution over the whole reference period.
  final HistoricalDistribution overall;

  /// Reference distribution per calendar month of the observation.
  final Map<int, HistoricalDistribution> byMonth;

  /// True when the hazard compares a value with the same calendar month.
  final bool seasonal;

  int get sampleCount => overall.sampleCount;

  /// Reference the hazard must use for a value observed at [observedAt].
  HazardBaselineSlice sliceFor(DateTime? observedAt) {
    if (!seasonal || observedAt == null) {
      return (
        distribution: overall,
        month: null,
        usedSeasonalBucket: false,
      );
    }

    final monthly = byMonth[observedAt.month];

    if (monthly == null ||
        monthly.sampleCount < minimumSeasonalSamples) {
      return (
        distribution: overall,
        month: observedAt.month,
        usedSeasonalBucket: false,
      );
    }

    return (
      distribution: monthly,
      month: observedAt.month,
      usedSeasonalBucket: true,
    );
  }
}

/// Historical reference of a hazard, built from the reference period.
class HazardBaseline {
  const HazardBaseline({
    required this.hazard,
    required this.variables,
    required this.referencePeriodStart,
    required this.referencePeriodEnd,
    required this.generatedAt,
    required this.source,
    this.notes = const <String>[],
  });

  final HazardType hazard;

  /// Reference per variable name.
  final Map<String, HazardBaselineVariable> variables;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;
  final DateTime generatedAt;
  final String source;

  /// What the historical source could not provide.
  final List<String> notes;

  HazardBaselineVariable? variableFor(String name) =>
      variables[name];
}
