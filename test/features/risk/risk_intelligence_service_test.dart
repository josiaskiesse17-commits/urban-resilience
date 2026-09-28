import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/risk_intelligence_service.dart';

void main() {
  test('builds a complete flood RiskResult', () {
    const input = FloodRiskInput(
      rainfallIntensityMmPerHour: 15,
      rainfallBaselineMmPerHour: 5,
      rainfallCriticalMmPerHour: 50,
      rainfallAccumulation6hMm: 40,
      rainfallAccumulation6hBaselineMm: 20,
      rainfallAccumulation6hCriticalMm: 100,
      riverDischargeM3s: 120,
      riverDischargeBaselineM3s: 80,
      riverDischargeCriticalM3s: 300,
      vulnerabilityScore: 60,
      historicalExposureScore: 70,
      observationScore: 0,
      observationCount: 0,
      confirmedObservationCount: 0,
    );

    final service = RiskIntelligenceService();

    final result = service.calculateFloodRisk(
      id: 'risk-1',
      locationName: 'Test Zone',
      latitude: -4.325,
      longitude: 15.322,
      input: input,
      rainfallSource: 'test-rainfall',
      riverSource: 'test-river',
    );

    expect(result.id, 'risk-1');
    expect(result.locationName, 'Test Zone');
    expect(result.latitude, -4.325);
    expect(result.longitude, 15.322);
    expect(result.hazardType, 'Flooding');

    expect(
      result.evidence.measurements.length,
      6,
    );

    expect(
      result.evidence.measurements
          .map((measurement) => measurement.name),
      containsAll(<String>[
        'rainfallIntensity',
        'rainfallAccumulation6h',
        'riverDischarge',
        'geographicVulnerability',
        'historicalExposure',
        'citizenObservationRisk',
      ]),
    );

    final rainfallMeasurement =
        result.evidence.measurements.firstWhere(
      (measurement) =>
          measurement.name == 'rainfallIntensity',
    );

    final rainfallAccumulationMeasurement =
        result.evidence.measurements.firstWhere(
      (measurement) =>
          measurement.name == 'rainfallAccumulation6h',
    );

    final riverMeasurement =
        result.evidence.measurements.firstWhere(
      (measurement) =>
          measurement.name == 'riverDischarge',
    );

    final vulnerabilityMeasurement =
        result.evidence.measurements.firstWhere(
      (measurement) =>
          measurement.name == 'geographicVulnerability',
    );

    final historicalExposureMeasurement =
        result.evidence.measurements.firstWhere(
      (measurement) =>
          measurement.name == 'historicalExposure',
    );

    final observationMeasurement =
        result.evidence.measurements.firstWhere(
      (measurement) =>
          measurement.name == 'citizenObservationRisk',
    );

    expect(
      rainfallMeasurement.value,
      input.rainfallIntensityMmPerHour,
    );

    expect(
      rainfallAccumulationMeasurement.value,
      input.rainfallAccumulation6hMm,
    );

    expect(
      riverMeasurement.value,
      input.riverDischargeM3s,
    );

    expect(
      vulnerabilityMeasurement.value,
      input.vulnerabilityScore,
    );

    expect(
      historicalExposureMeasurement.value,
      input.historicalExposureScore,
    );

    expect(
      observationMeasurement.value,
      input.observationScore,
    );

    expect(
      result.evidence.observationCount,
      input.observationCount,
    );

    expect(
      result.evidence.confirmedObservationCount,
      input.confirmedObservationCount,
    );

    expect(
      result.updatedAt,
      isNotNull,
    );
  });

  test(
    'parses historical rainfall and river discharge',
    () {
      const input = FloodRiskInput(
        rainfallIntensityMmPerHour: 8,
        rainfallBaselineMmPerHour: 4,
        rainfallCriticalMmPerHour: 40,
        rainfallAccumulation6hMm: 25,
        rainfallAccumulation6hBaselineMm: 15,
        rainfallAccumulation6hCriticalMm: 80,
        riverDischargeM3s: 90,
        riverDischargeBaselineM3s: 70,
        riverDischargeCriticalM3s: 250,
        vulnerabilityScore: 30,
        historicalExposureScore: 45,
        observationScore: 0,
        observationCount: 0,
        confirmedObservationCount: 0,
      );

      final service = RiskIntelligenceService();

      final result = service.calculateFloodRisk(
        id: 'risk-2',
        locationName: 'Historical Test Zone',
        latitude: -4.325,
        longitude: 15.322,
        input: input,
      );

      expect(
        result.evidence.measurements.length,
        6,
      );

      final rainfallMeasurement =
          result.evidence.measurements.firstWhere(
        (measurement) =>
            measurement.name == 'rainfallIntensity',
      );

      final accumulationMeasurement =
          result.evidence.measurements.firstWhere(
        (measurement) =>
            measurement.name == 'rainfallAccumulation6h',
      );

      final riverMeasurement =
          result.evidence.measurements.firstWhere(
        (measurement) =>
            measurement.name == 'riverDischarge',
      );

      expect(
        rainfallMeasurement.referenceValue,
        input.rainfallBaselineMmPerHour,
      );

      expect(
        accumulationMeasurement.referenceValue,
        input.rainfallAccumulation6hBaselineMm,
      );

      expect(
        riverMeasurement.referenceValue,
        input.riverDischargeBaselineM3s,
      );
    },
  );
}