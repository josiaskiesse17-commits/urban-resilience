import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_calculator.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_input.dart';

void main() {
  test('calculates flood risk', () {
    const input = FloodRiskInput(
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

    const calculator = FloodRiskCalculator();

    final result = calculator.calculate(input);

    expect(result.hazardScore, greaterThan(0));

    expect(result.overallScore, greaterThan(0));

    expect(result.riskLevel, isNotNull);

    expect(result.overallScore, lessThanOrEqualTo(100));
  });
}
