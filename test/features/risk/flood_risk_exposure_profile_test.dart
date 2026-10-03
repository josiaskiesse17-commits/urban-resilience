import 'package:flutter_test/flutter_test.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';

void main() {
  test('calculates vulnerability score from exposure factors', () {
    const profile = FloodRiskExposureProfile(
      zoneId: 'zone-1',
      populationExposureScore: 80,
      infrastructureExposureScore: 60,
      drainageVulnerabilityScore: 90,
      criticalFacilityExposureScore: 50,
      historicalFloodExposureScore: 65,
    );

    expect(profile.vulnerabilityScore, 71.5);
  });

  test('clamps scores above 100', () {
    const profile = FloodRiskExposureProfile(
      zoneId: 'zone-1',
      populationExposureScore: 100,
      infrastructureExposureScore: 100,
      drainageVulnerabilityScore: 100,
      criticalFacilityExposureScore: 100,
      historicalFloodExposureScore: 100,
    );

    expect(profile.vulnerabilityScore, 100);
  });

  test('supports JSON serialization', () {
    final original = FloodRiskExposureProfile(
      zoneId: 'zone-1',
      populationExposureScore: 70,
      infrastructureExposureScore: 60,
      drainageVulnerabilityScore: 80,
      criticalFacilityExposureScore: 50,
      historicalFloodExposureScore: 40,
      source: 'zone-profile',
      updatedAt: DateTime.utc(2026, 9, 28),
    );

    final restored = FloodRiskExposureProfile.fromJson(original.toJson());

    expect(restored.zoneId, original.zoneId);
    expect(restored.populationExposureScore, original.populationExposureScore);
    expect(restored.vulnerabilityScore, original.vulnerabilityScore);
    expect(restored.historicalFloodExposureScore, 40);
  });
}
