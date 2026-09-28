class HistoricalFloodData {
  final List<double> hourlyRainfallValues;
  final List<double> riverDischargeValues;

  final DateTime referencePeriodStart;
  final DateTime referencePeriodEnd;

  final String rainfallSource;
  final String riverSource;

  const HistoricalFloodData({
    required this.hourlyRainfallValues,
    required this.riverDischargeValues,
    required this.referencePeriodStart,
    required this.referencePeriodEnd,
    required this.rainfallSource,
    required this.riverSource,
  });
}