class FloodEnvironmentalData {
  final double rainfallLastHourMm;
  final double rainfallAccumulation6hMm;
  final double riverDischargeM3s;
  final DateTime observedAt;

  final String rainfallSource;
  final String riverSource;

  const FloodEnvironmentalData({
    required this.rainfallLastHourMm,
    required this.rainfallAccumulation6hMm,
    required this.riverDischargeM3s,
    required this.observedAt,
    required this.rainfallSource,
    required this.riverSource,
  });
}