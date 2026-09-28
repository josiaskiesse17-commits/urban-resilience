import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/observations/domain/observation.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input_observation_enricher.dart';

void main() {
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
    vulnerabilityScore: 40,
    historicalExposureScore: 50,
    observationScore: 10,
    observationCount: 0,
    confirmedObservationCount: 0,
  );

  const enricher = FloodRiskInputObservationEnricher();

  test('applies observation risk to FloodRiskInput', () {
    final now = DateTime.now().toUtc();

    final observations = [
      Observation(
        id: 'obs-1',
        userId: 'user-1',
        latitude: 0,
        longitude: 0,
        type: ObservationType.flooding,
        status: ObservationStatus.confirmed,
        createdAt: now,
      ),
    ];

    final result = enricher.enrich(
      latitude: 0,
      longitude: 0,
      input: input,
      observations: observations,
    );

    expect(result.observationScore, greaterThan(0));
    expect(result.observationCount, 1);
    expect(result.confirmedObservationCount, 1);
  });

  test('preserves other risk inputs', () {
    final result = enricher.enrich(
      latitude: 0,
      longitude: 0,
      input: input,
      observations: const [],
    );

    expect(
      result.rainfallIntensityMmPerHour,
      input.rainfallIntensityMmPerHour,
    );

    expect(
      result.riverDischargeM3s,
      input.riverDischargeM3s,
    );

    expect(
      result.vulnerabilityScore,
      input.vulnerabilityScore,
    );

    expect(
      result.historicalExposureScore,
      input.historicalExposureScore,
    );

    expect(result.observationScore, 0);
    expect(result.observationCount, 0);
    expect(result.confirmedObservationCount, 0);
  });

  test('pending observations do not increase observation risk',
      () {
    final now = DateTime.now().toUtc();

    final observations = [
      Observation(
        id: 'obs-1',
        userId: 'user-1',
        latitude: 0,
        longitude: 0,
        type: ObservationType.flooding,
        status: ObservationStatus.pending,
        createdAt: now,
      ),
    ];

    final result = enricher.enrich(
      latitude: 0,
      longitude: 0,
      input: input,
      observations: observations,
    );

    expect(result.observationCount, 1);
    expect(result.confirmedObservationCount, 0);
    expect(result.observationScore, 0);
  });
}