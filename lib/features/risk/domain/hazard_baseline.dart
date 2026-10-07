import 'hazard_series_utils.dart';
import 'hazard_type.dart';
import 'historical_distribution.dart';

typedef HazardBaselineSlice = ({
  HistoricalDistribution distribution,
  int? month,
  bool usedSeasonalBucket,
});

class HazardBaselineVariable {
  const HazardBaselineVariable({
    required this.name,
    required this.unit,
    required this.window,
    required this.overall,
    required this.byMonth,
    required this.seasonal,
  });

  static const int minimumSeasonalSamples = 30;

  final String name;
  final String unit;
  final HazardWindow window;

  final HistoricalDistribution overall;

  final Map<int, HistoricalDistribution> byMonth;

  final bool seasonal;

  int get sampleCount => overall.sampleCount;

  HazardBaselineSlice sliceFor(DateTime? observedAt) {
    if (!seasonal || observedAt == null) {
      return (distribution: overall, month: null, usedSeasonalBucket: false);
    }

    final monthly = byMonth[observedAt.month];

    if (monthly == null || monthly.sampleCount < minimumSeasonalSamples) {
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

  final Map<String, HazardBaselineVariable> variables;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;
  final DateTime generatedAt;
  final String source;

  final List<String> notes;

  HazardBaselineVariable? variableFor(String name) => variables[name];
}
