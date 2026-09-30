class RiskScenario {
  final String name;

  final double rainfallMultiplier;
  final double rainfallAccumulationMultiplier;
  final double riverDischargeDeltaM3s;

  final double vulnerabilityDelta;
  final double observationScoreDelta;

  final int additionalObservationCount;
  final int additionalConfirmedObservationCount;

  const RiskScenario({
    required this.name,
    this.rainfallMultiplier = 1.0,
    this.rainfallAccumulationMultiplier = 1.0,
    this.riverDischargeDeltaM3s = 0.0,
    this.vulnerabilityDelta = 0.0,
    this.observationScoreDelta = 0.0,
    this.additionalObservationCount = 0,
    this.additionalConfirmedObservationCount = 0,
  });
}