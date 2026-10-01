import 'historical_statistics.dart';

/// Ordered sample of a measured or derived series.
///
/// It is the statistical reference behind every hazard variable. It is *not*
/// a validated danger threshold: only the percentile the hazard model asks
/// for is read from it, and the evidence always labels it as a statistical
/// reference with the period it was computed from.
class HistoricalDistribution {
  HistoricalDistribution(List<double> values)
      : _sorted = List<double>.unmodifiable(
          [...values]..sort(),
        ) {
    if (values.isEmpty) {
      throw ArgumentError(
        'A historical distribution cannot be empty.',
      );
    }
  }

  final List<double> _sorted;

  int get sampleCount => _sorted.length;

  double get minimum => _sorted.first;

  double get maximum => _sorted.last;

  /// Interpolated percentile, `0 <= percentile <= 100`.
  double percentile(double percentile) {
    return HistoricalStatistics.percentile(
      _sorted,
      percentile,
    );
  }

  double get median => percentile(50);

  /// Share of the reference samples at or below [value], in percent.
  ///
  /// Unlike [percentile] this asks where a *live* measurement sits inside the
  /// reference distribution, which is what makes a value comparable with the
  /// history of its own location instead of with a generic threshold.
  double percentileRankOf(double value) {
    var atOrBelow = 0;

    for (final sample in _sorted) {
      if (sample <= value) {
        atOrBelow++;
      } else {
        break;
      }
    }

    return (atOrBelow / _sorted.length) * 100;
  }
}
