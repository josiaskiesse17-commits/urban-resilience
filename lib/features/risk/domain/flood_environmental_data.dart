class FloodEnvironmentalData {
  final double rainfallLastHourMm;
  final double rainfallAccumulation6hMm;
  final double riverDischargeM3s;
  final DateTime observedAt;

  final String rainfallSource;
  final String riverSource;

  /// Timestamp of the rainfall measurement returned by the provider.
  final DateTime? rainfallObservedAt;

  /// Date of the daily river discharge value that was used.
  final DateTime? riverObservedAt;

  /// Number of hours the accumulation actually covers. It is smaller than the
  /// nominal 6 hours only when the provider series has a gap, which is then
  /// reported in [dataNotes] instead of being summed as if the missing hours
  /// were dry.
  final int rainfallAccumulationWindowHours;

  /// Facts about the live data that must reach the evidence.
  final List<String> dataNotes;

  const FloodEnvironmentalData({
    required this.rainfallLastHourMm,
    required this.rainfallAccumulation6hMm,
    required this.riverDischargeM3s,
    required this.observedAt,
    required this.rainfallSource,
    required this.riverSource,
    this.rainfallObservedAt,
    this.riverObservedAt,
    this.rainfallAccumulationWindowHours = 6,
    this.dataNotes = const <String>[],
  });
}