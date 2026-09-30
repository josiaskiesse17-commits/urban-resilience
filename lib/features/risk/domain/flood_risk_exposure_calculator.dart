class FloodRiskExposureCalculator {
  const FloodRiskExposureCalculator();

  double calculateWeightedScore({
    required double populationExposureScore,
    required double infrastructureExposureScore,
    required double drainageVulnerabilityScore,
    required double criticalFacilityExposureScore,
  }) {
    final score =
        (populationExposureScore * 0.30) +
        (infrastructureExposureScore * 0.25) +
        (drainageVulnerabilityScore * 0.25) +
        (criticalFacilityExposureScore * 0.20);

    return score.clamp(0.0, 100.0);
  }
}