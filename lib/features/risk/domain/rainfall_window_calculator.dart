class RainfallWindowCalculator {
  const RainfallWindowCalculator();

  /// Sums every complete six-hour window of [hourlyRainfall].
  ///
  /// When [times] is provided and aligned with the values, samples are
  /// considered in chronological order and a window only counts when its six
  /// samples are exactly one hour apart. This keeps gaps, duplicated or
  /// unexpected timestamps from silently producing totals that do not
  /// represent six hours of rainfall. Samples with non-finite values are
  /// never summed. Without timestamps the legacy index-based windows are
  /// used, still skipping non-finite samples.
  List<double> rollingSixHourTotals(
    List<double> hourlyRainfall, {
    List<DateTime>? times,
  }) {
    if (hourlyRainfall.length < 6) {
      return const <double>[];
    }

    final stamps =
        times != null && times.length == hourlyRainfall.length
        ? times
        : const <DateTime>[];
    final ordered = stamps.length == hourlyRainfall.length;

    final order = <int>[
      for (var index = 0; index < hourlyRainfall.length; index++) index,
    ];

    if (ordered) {
      order.sort((left, right) => stamps[left].compareTo(stamps[right]));
    }

    final totals = <double>[];

    for (var end = 5; end < order.length; end++) {
      var valid = true;
      var total = 0.0;

      for (var offset = end - 5; offset <= end; offset++) {
        final index = order[offset];
        final value = hourlyRainfall[index];

        if (!value.isFinite) {
          valid = false;
          break;
        }

        if (ordered && offset > end - 5) {
          final step = stamps[index].difference(stamps[order[offset - 1]]);

          if (step != const Duration(hours: 1)) {
            valid = false;
            break;
          }
        }

        total += value;
      }

      if (valid) {
        totals.add(total);
      }
    }

    return totals;
  }
}
