class HistoricalStatistics {
  const HistoricalStatistics._();

  static double median(List<double> values) {
    if (values.isEmpty) {
      throw ArgumentError('Cannot calculate median of an empty list.');
    }

    final sorted = [...values]..sort();

    final middle = sorted.length ~/ 2;

    if (sorted.length.isOdd) {
      return sorted[middle];
    }

    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double percentile(List<double> values, double percentile) {
    if (values.isEmpty) {
      throw ArgumentError('Cannot calculate percentile of an empty list.');
    }

    if (percentile < 0 || percentile > 100) {
      throw ArgumentError('Percentile must be between 0 and 100.');
    }

    final sorted = [...values]..sort();

    if (sorted.length == 1) {
      return sorted.first;
    }

    final position = (percentile / 100) * (sorted.length - 1);

    final lower = position.floor();
    final upper = position.ceil();

    if (lower == upper) {
      return sorted[lower];
    }

    final fraction = position - lower;

    return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction;
  }
}
