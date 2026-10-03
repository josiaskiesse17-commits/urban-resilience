class FloodRiskContext {
  final double rainfallBaselineMmPerHour;
  final double rainfallCriticalMmPerHour;

  final double rainfallAccumulation6hBaselineMm;
  final double rainfallAccumulation6hCriticalMm;

  final double riverDischargeBaselineM3s;
  final double riverDischargeCriticalM3s;

  final double vulnerabilityScore;
  final double historicalExposureScore;
  final double observationScore;

  final int observationCount;
  final int confirmedObservationCount;

  const FloodRiskContext({
    required this.rainfallBaselineMmPerHour,
    required this.rainfallCriticalMmPerHour,
    required this.rainfallAccumulation6hBaselineMm,
    required this.rainfallAccumulation6hCriticalMm,
    required this.riverDischargeBaselineM3s,
    required this.riverDischargeCriticalM3s,
    required this.vulnerabilityScore,
    required this.historicalExposureScore,
    required this.observationScore,
    required this.observationCount,
    required this.confirmedObservationCount,
  });
}
