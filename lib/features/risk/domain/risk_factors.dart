class RiskFactors {
  final double rainfall;
  final double geographicVulnerability;
  final double historicalExposure;
  final double currentObservations;

  const RiskFactors({
    required this.rainfall,
    required this.geographicVulnerability,
    required this.historicalExposure,
    required this.currentObservations,
  });

  Map<String, double> toJson() {
    return {
      'rainfall': rainfall,
      'geographicVulnerability': geographicVulnerability,
      'historicalExposure': historicalExposure,
      'currentObservations': currentObservations,
    };
  }
}