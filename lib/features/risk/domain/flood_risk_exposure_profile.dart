class FloodRiskExposureProfile {
  const FloodRiskExposureProfile({
    required this.zoneId,
    required this.populationExposureScore,
    required this.infrastructureExposureScore,
    required this.drainageVulnerabilityScore,
    required this.criticalFacilityExposureScore,
    required this.historicalFloodExposureScore,
    this.source,
    this.updatedAt,
  });

  final String zoneId;

  final double populationExposureScore;

  final double infrastructureExposureScore;

  final double drainageVulnerabilityScore;

  final double criticalFacilityExposureScore;

  final double historicalFloodExposureScore;

  final String? source;
  final DateTime? updatedAt;

  double get vulnerabilityScore {
    final score =
        (populationExposureScore * 0.30) +
        (infrastructureExposureScore * 0.25) +
        (drainageVulnerabilityScore * 0.25) +
        (criticalFacilityExposureScore * 0.20);

    return score.clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneId': zoneId,
      'populationExposureScore': populationExposureScore,
      'infrastructureExposureScore': infrastructureExposureScore,
      'drainageVulnerabilityScore': drainageVulnerabilityScore,
      'criticalFacilityExposureScore': criticalFacilityExposureScore,
      'historicalFloodExposureScore': historicalFloodExposureScore,
      'source': source,
      'updatedAt': updatedAt?.toIso8601String(),
      'vulnerabilityScore': vulnerabilityScore,
    };
  }

  factory FloodRiskExposureProfile.fromJson(Map<String, dynamic> json) {
    return FloodRiskExposureProfile(
      zoneId: json['zoneId'] as String,
      populationExposureScore:
          (json['populationExposureScore'] as num?)?.toDouble() ?? 0,
      infrastructureExposureScore:
          (json['infrastructureExposureScore'] as num?)?.toDouble() ?? 0,
      drainageVulnerabilityScore:
          (json['drainageVulnerabilityScore'] as num?)?.toDouble() ?? 0,
      criticalFacilityExposureScore:
          (json['criticalFacilityExposureScore'] as num?)?.toDouble() ?? 0,
      historicalFloodExposureScore:
          (json['historicalFloodExposureScore'] as num?)?.toDouble() ?? 0,
      source: json['source'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
    );
  }
}
