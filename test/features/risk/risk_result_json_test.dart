import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';

void main() {
  test(
    'survives the Firestore JSON round trip',
    () {
      const input = FloodRiskInput(
        rainfallIntensityMmPerHour: 12,
        rainfallBaselineMmPerHour: 4,
        rainfallCriticalMmPerHour: 40,
        rainfallAccumulation6hMm: 30,
        rainfallAccumulation6hBaselineMm: 15,
        rainfallAccumulation6hCriticalMm: 80,
        riverDischargeM3s: 240,
        riverDischargeBaselineM3s: 160,
        riverDischargeCriticalM3s: 280,
        vulnerabilityScore: 70,
        historicalExposureScore: 65,
        observationScore: 40,
        observationCount: 4,
        confirmedObservationCount: 2,
      );

      final service = RiskIntelligenceService();

      final result = service.calculateFloodRisk(
        id: 'zone-masina',
        locationName: 'Masina',
        latitude: -4.30,
        longitude: 15.35,
        input: input,
        rainfallSource: 'Open-Meteo',
        riverSource: 'Open-Meteo',
        observedAt: DateTime.utc(2026, 9, 28, 8),
      );

      final restored = RiskResult.fromJson(
        result.toJson(),
      );

      expect(restored.id, result.id);
      expect(restored.locationName, result.locationName);
      expect(restored.latitude, result.latitude);
      expect(restored.longitude, result.longitude);
      expect(restored.hazardType, result.hazardType);
      expect(restored.riskScore, result.riskScore);
      expect(restored.riskLevel, result.riskLevel);
      expect(restored.updatedAt, result.updatedAt);

      expect(
        restored.factors.rainfall,
        result.factors.rainfall,
      );

      expect(
        restored.factors.geographicVulnerability,
        result.factors.geographicVulnerability,
      );

      expect(
        restored.factors.historicalExposure,
        result.factors.historicalExposure,
      );

      expect(
        restored.factors.currentObservations,
        result.factors.currentObservations,
      );

      expect(
        restored.evidence.measurements.length,
        result.evidence.measurements.length,
      );

      expect(
        restored.evidence.observationCount,
        result.evidence.observationCount,
      );

      expect(
        restored
            .evidence
            .confirmedObservationCount,
        result.evidence.confirmedObservationCount,
      );

      expect(
        restored.evidence.collectedAt,
        result.evidence.collectedAt,
      );

      final restoredRiver = restored.evidence.measurements
          .firstWhere(
        (measurement) =>
            measurement.name == 'riverDischarge',
      );

      final originalRiver = result.evidence.measurements
          .firstWhere(
        (measurement) =>
            measurement.name == 'riverDischarge',
      );

      expect(restoredRiver.value, originalRiver.value);
      expect(restoredRiver.unit, originalRiver.unit);
      expect(
        restoredRiver.referenceValue,
        originalRiver.referenceValue,
      );
      expect(
        restoredRiver.referenceType,
        originalRiver.referenceType,
      );
      expect(
        restoredRiver.ratioToReference,
        originalRiver.ratioToReference,
      );
      expect(
        restoredRiver.source,
        originalRiver.source,
      );
    },
  );
}
