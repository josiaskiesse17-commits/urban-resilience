class FloodEnvironmentalData {
  final double rainfallLastHourMm;
  final double rainfallAccumulation6hMm;
  final double riverDischargeM3s;
  final DateTime observedAt;

  final String rainfallSource;
  final String riverSource;

  final DateTime? rainfallObservedAt;

  final DateTime? riverObservedAt;

  final int rainfallAccumulationWindowHours;

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
