import 'historical_statistics.dart';







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

  
  double percentile(double percentile) {
    return HistoricalStatistics.percentile(
      _sorted,
      percentile,
    );
  }

  double get median => percentile(50);

  
  
  
  
  
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
