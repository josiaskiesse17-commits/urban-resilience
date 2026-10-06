class HistoricalFloodData {
  final List<double> hourlyRainfallValues;

  /// Timestamps aligned with [hourlyRainfallValues], when the provider
  /// supplies them. Empty when unknown, in which case callers fall back to
  /// index-based hourly windows.
  final List<DateTime> hourlyRainfallTimes;

  final List<double> riverDischargeValues;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;

  final String rainfallSource;
  final String riverSource;

  const HistoricalFloodData({
    required this.hourlyRainfallValues,
    this.hourlyRainfallTimes = const <DateTime>[],
    required this.riverDischargeValues,
    required this.referencePeriodStart,
    required this.referencePeriodEnd,
    required this.rainfallSource,
    required this.riverSource,
  });
}
