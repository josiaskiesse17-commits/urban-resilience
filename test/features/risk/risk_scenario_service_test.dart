import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';
import 'package:urban_resilience/features/risk/domain/risk_scenario.dart';
import 'package:urban_resilience/features/risk/domain/risk_scenario_service.dart';

void main() {
  test('simulates increased rainfall and river discharge', () {
    const baselineInput = FloodRiskInput(
      rainfallIntensityMmPerHour: 6.4,
      rainfallBaselineMmPerHour: 1.2,
      rainfallCriticalMmPerHour: 8.0,
      rainfallAccumulation6hMm: 36,
      rainfallAccumulation6hBaselineMm: 12,
      rainfallAccumulation6hCriticalMm: 50,
      riverDischargeM3s: 500,
      riverDischargeBaselineM3s: 300,
      riverDischargeCriticalM3s: 700,
      vulnerabilityScore: 76,
      historicalExposureScore: 68,
      observationScore: 74,
      observationCount: 8,
      confirmedObservationCount: 5,
    );

    const scenario = RiskScenario(
      name: 'Heavy rainfall scenario',
      rainfallMultiplier: 1.5,
      rainfallAccumulationMultiplier: 1.5,
      riverDischargeDeltaM3s: 100,
    );

    const service = RiskScenarioService();

    final result = service.simulateFloodRisk(
      scenario: scenario,
      id: 'zone-masina',
      locationName: 'Masina',
      latitude: -4.30,
      longitude: 15.35,
      baselineInput: baselineInput,
    );

    expect(
      result.scenario.riskScore,
      greaterThan(result.baseline.riskScore),
    );

    expect(
      result.scoreDifference,
      greaterThan(0),
    );
  });
}