import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input_exposure_extension.dart';

void main() {
  group('FloodRiskInputExposureExtension', () {
    test('applies exposure profile to risk input', () {
      const input = FloodRiskInput(
        rainfallIntensityMmPerHour: 10,
        rainfallBaselineMmPerHour: 5,
        rainfallCriticalMmPerHour: 50,
        rainfallAccumulation6hMm: 30,
        rainfallAccumulation6hBaselineMm: 20,
        rainfallAccumulation6hCriticalMm: 100,
        riverDischargeM3s: 100,
        riverDischargeBaselineM3s: 80,
        riverDischargeCriticalM3s: 300,
        vulnerabilityScore: 20,
        historicalExposureScore: 10,
        observationScore: 40,
        observationCount: 2,
        confirmedObservationCount: 1,
      );

      const profile = FloodRiskExposureProfile(
        zoneId: 'zone-1',
        populationExposureScore: 80,
        infrastructureExposureScore: 60,
        drainageVulnerabilityScore: 90,
        criticalFacilityExposureScore: 50,
        historicalFloodExposureScore: 75,
      );

      final enriched = input.withExposureProfile(profile);

      expect(enriched.vulnerabilityScore, 71.5);
      expect(enriched.historicalExposureScore, 75);

      expect(
        enriched.rainfallIntensityMmPerHour,
        input.rainfallIntensityMmPerHour,
      );

      expect(
        enriched.riverDischargeM3s,
        input.riverDischargeM3s,
      );

      expect(
        enriched.observationCount,
        input.observationCount,
      );

      expect(
        enriched.confirmedObservationCount,
        input.confirmedObservationCount,
      );
    });

    test('does not modify environmental risk measurements', () {
      const input = FloodRiskInput(
        rainfallIntensityMmPerHour: 25,
        rainfallBaselineMmPerHour: 10,
        rainfallCriticalMmPerHour: 60,
        rainfallAccumulation6hMm: 50,
        rainfallAccumulation6hBaselineMm: 25,
        rainfallAccumulation6hCriticalMm: 120,
        riverDischargeM3s: 150,
        riverDischargeBaselineM3s: 100,
        riverDischargeCriticalM3s: 400,
        vulnerabilityScore: 10,
        historicalExposureScore: 20,
        observationScore: 30,
        observationCount: 5,
        confirmedObservationCount: 3,
      );

      const profile = FloodRiskExposureProfile(
        zoneId: 'zone-2',
        populationExposureScore: 90,
        infrastructureExposureScore: 80,
        drainageVulnerabilityScore: 70,
        criticalFacilityExposureScore: 60,
        historicalFloodExposureScore: 55,
      );

      final enriched = input.withExposureProfile(profile);

      expect(enriched.rainfallIntensityMmPerHour, 25);
      expect(enriched.rainfallBaselineMmPerHour, 10);
      expect(enriched.rainfallCriticalMmPerHour, 60);

      expect(enriched.rainfallAccumulation6hMm, 50);
      expect(enriched.rainfallAccumulation6hBaselineMm, 25);
      expect(enriched.rainfallAccumulation6hCriticalMm, 120);

      expect(enriched.riverDischargeM3s, 150);
      expect(enriched.riverDischargeBaselineM3s, 100);
      expect(enriched.riverDischargeCriticalM3s, 400);

      expect(enriched.vulnerabilityScore, 76.5);
      expect(enriched.historicalExposureScore, 55);

      expect(enriched.observationScore, 30);
      expect(enriched.observationCount, 5);
      expect(enriched.confirmedObservationCount, 3);
    });
  });
}