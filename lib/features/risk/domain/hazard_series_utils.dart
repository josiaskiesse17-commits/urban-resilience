/// One timestamped sample of an environmental series.
typedef HazardSample = ({DateTime time, double value});

/// Time window a hazard variable is derived over.
///
/// Every window is *trailing*: the value describes the last [hours] hours
/// ending at the timestamp of the sample. Live values and historical
/// reference values are derived with the same window, so they are directly
/// comparable.
enum HazardWindow {
  instant(hours: 1, label: 'instant'),
  sum6h(hours: 6, label: '6h'),
  sum24h(hours: 24, label: '24h'),
  sum72h(hours: 72, label: '72h'),
  sum14d(hours: 24 * 14, label: '14d'),
  sum30d(hours: 24 * 30, label: '30d'),
  max6h(hours: 6, label: '6h'),
  max24h(hours: 24, label: '24h'),
  min24h(hours: 24, label: '24h');

  const HazardWindow({
    required this.hours,
    required this.label,
  });

  /// Length of the window in hours.
  final int hours;

  /// Measurement period written to the evidence (`6h`, `24h`, ...).
  final String label;

  /// How many days of hourly data the live request needs for this window.
  int get requiredLookbackDays => (hours / 24).ceil() + 1;
}

/// Window arithmetic over hourly series.
///
/// Integrity rules enforced here:
///
/// * missing values are never replaced by a fabricated number; they simply
///   remove the affected windows;
/// * a window is only produced when its hours are contiguous, so a gap is
///   reported instead of being summed as if the missing hours were dry;
/// * samples are read with their timestamp, never by list position, because
///   the providers return leading or trailing nulls.
class HazardSeriesUtils {
  const HazardSeriesUtils._();

  static const Duration _oneHour = Duration(hours: 1);

  /// Pairs timestamps with values and drops the entries that are missing.
  ///
  /// A timestamp may arrive as the raw provider string or already parsed as
  /// a [DateTime]; both are normalised to UTC. The result is sorted by time
  /// so a gap stays visible as a time difference instead of silently
  /// shifting the following values.
  static List<HazardSample> align({
    required List<Object?> times,
    required List<Object?> values,
  }) {
    final length =
        times.length < values.length ? times.length : values.length;

    final samples = <HazardSample>[];

    for (var index = 0; index < length; index++) {
      final time = times[index];
      final value = values[index];

      if (value is! num) {
        continue;
      }

      DateTime? parsed;

      if (time is DateTime) {
        parsed = time.toUtc();
      } else if (time is String) {
        parsed = DateTime.tryParse(time);
      }

      if (parsed == null) {
        continue;
      }

      samples.add(
        (
          time: parsed.toUtc(),
          value: value.toDouble(),
        ),
      );
    }

    samples.sort(
      (first, second) => first.time.compareTo(second.time),
    );

    return samples;
  }

  /// Number of consecutive hourly steps ending at each index.
  ///
  /// A window of `hours` samples ending at index `i` is contiguous when
  /// `runs[i] >= hours - 1`. The array is computed once per series so the
  /// window helpers stay linear even on the ~39 000 hourly samples of a
  /// reference period.
  static List<int> _runLengths(List<HazardSample> hourly) {
    final runs = List<int>.filled(hourly.length, 0);

    for (var index = 1; index < hourly.length; index++) {
      final gap = hourly[index].time.difference(
        hourly[index - 1].time,
      );

      runs[index] = gap == _oneHour ? runs[index - 1] + 1 : 0;
    }

    return runs;
  }

  /// Trailing sums over [window] hours, in the unit of the series.
  static List<HazardSample> trailingSums({
    required List<HazardSample> hourly,
    required int window,
  }) {
    final results = <HazardSample>[];

    final runs = _runLengths(hourly);

    var windowSum = 0.0;

    for (var index = 0; index < hourly.length; index++) {
      windowSum += hourly[index].value;

      if (index >= window) {
        windowSum -= hourly[index - window].value;
      }

      if (index < window - 1) {
        continue;
      }

      if (runs[index] < window - 1) {
        continue;
      }

      results.add(
        (
          time: hourly[index].time,
          value: windowSum,
        ),
      );
    }

    return results;
  }

  /// Trailing maxima over [window] hours.
  static List<HazardSample> trailingMaxima({
    required List<HazardSample> hourly,
    required int window,
  }) {
    return _trailingExtreme(
      hourly: hourly,
      window: window,
      keepHigher: true,
    );
  }

  /// Trailing minima over [window] hours.
  static List<HazardSample> trailingMinima({
    required List<HazardSample> hourly,
    required int window,
  }) {
    return _trailingExtreme(
      hourly: hourly,
      window: window,
      keepHigher: false,
    );
  }

  static List<HazardSample> _trailingExtreme({
    required List<HazardSample> hourly,
    required int window,
    required bool keepHigher,
  }) {
    final results = <HazardSample>[];

    final runs = _runLengths(hourly);

    for (var index = window - 1;
        index < hourly.length;
        index++) {
      if (runs[index] < window - 1) {
        continue;
      }

      final start = index - window + 1;

      var extreme = hourly[start].value;

      for (var i = start + 1; i <= index; i++) {
        final value = hourly[i].value;

        if (keepHigher ? value > extreme : value < extreme) {
          extreme = value;
        }
      }

      results.add(
        (
          time: hourly[index].time,
          value: extreme,
        ),
      );
    }

    return results;
  }

  /// Applies [window] to an hourly series.
  static List<HazardSample> applyWindow({
    required List<HazardSample> hourly,
    required HazardWindow window,
  }) {
    switch (window) {
      case HazardWindow.instant:
        final last = lastSample(hourly);

        return last == null
            ? const <HazardSample>[]
            : <HazardSample>[last];

      case HazardWindow.sum6h:
        return trailingSums(hourly: hourly, window: 6);

      case HazardWindow.sum24h:
        return trailingSums(hourly: hourly, window: 24);

      case HazardWindow.sum72h:
        return trailingSums(hourly: hourly, window: 72);

      case HazardWindow.sum14d:
        return trailingSums(hourly: hourly, window: 24 * 14);

      case HazardWindow.sum30d:
        return trailingSums(hourly: hourly, window: 24 * 30);

      case HazardWindow.max6h:
        return trailingMaxima(hourly: hourly, window: 6);

      case HazardWindow.max24h:
        return trailingMaxima(hourly: hourly, window: 24);

      case HazardWindow.min24h:
        return trailingMinima(hourly: hourly, window: 24);
    }
  }

  static HazardSample? lastSample(
    List<HazardSample> samples,
  ) {
    if (samples.isEmpty) {
      return null;
    }

    return samples.last;
  }

  /// Splits a series into per calendar month buckets of the sample time.
  static Map<int, List<double>> byMonth(
    List<HazardSample> samples,
  ) {
    final buckets = <int, List<double>>{};

    for (final sample in samples) {
      buckets
          .putIfAbsent(
            sample.time.month,
            () => <double>[],
          )
          .add(sample.value);
    }

    return buckets;
  }
}
