class FloodRiskInput {
  final double rainfallIntensityMmPerHour;
  final double rainfallBaselineMmPerHour;
  final double rainfallCriticalMmPerHour;

  final double rainfallAccumulation6hMm;
  final double rainfallAccumulation6hBaselineMm;
  final double rainfallAccumulation6hCriticalMm;

  final double riverDischargeM3s;
  final double riverDischargeBaselineM3s;
  final double riverDischargeCriticalM3s;

  final double vulnerabilityScore;
  final double historicalExposureScore;
  final double observationScore;

  final int observationCount;
  final int confirmedObservationCount;

  const FloodRiskInput({
    required this.rainfallIntensityMmPerHour,
    required this.rainfallBaselineMmPerHour,
    required this.rainfallCriticalMmPerHour,
    required this.rainfallAccumulation6hMm,
    required this.rainfallAccumulation6hBaselineMm,
    required this.rainfallAccumulation6hCriticalMm,
    required this.riverDischargeM3s,
    required this.riverDischargeBaselineM3s,
    required this.riverDischargeCriticalM3s,
    required this.vulnerabilityScore,
    required this.historicalExposureScore,
    required this.observationScore,
    required this.observationCount,
    required this.confirmedObservationCount,
  });

  FloodRiskInput copyWith({
    double? rainfallIntensityMmPerHour,
    double? rainfallAccumulation6hMm,
    double? riverDischargeM3s,
    double? vulnerabilityScore,
    double? historicalExposureScore,
    double? observationScore,
    int? observationCount,
    int? confirmedObservationCount,
  }) {
    return FloodRiskInput(
      rainfallIntensityMmPerHour:
          rainfallIntensityMmPerHour ??
              this.rainfallIntensityMmPerHour,
      rainfallBaselineMmPerHour:
          rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour:
          rainfallCriticalMmPerHour,
      rainfallAccumulation6hMm:
          rainfallAccumulation6hMm ??
              this.rainfallAccumulation6hMm,
      rainfallAccumulation6hBaselineMm:
          rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          rainfallAccumulation6hCriticalMm,
      riverDischargeM3s:
          riverDischargeM3s ??
              this.riverDischargeM3s,
      riverDischargeBaselineM3s:
          riverDischargeBaselineM3s,
      riverDischargeCriticalM3s:
          riverDischargeCriticalM3s,
      vulnerabilityScore:
          vulnerabilityScore ??
              this.vulnerabilityScore,
      historicalExposureScore:
          historicalExposureScore ??
              this.historicalExposureScore,
      observationScore:
          observationScore ??
              this.observationScore,
      observationCount:
          observationCount ??
              this.observationCount,
      confirmedObservationCount:
          confirmedObservationCount ??
              this.confirmedObservationCount,
    );
  }
}