import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/historical_flood_baseline_calculator.dart';
import 'package:urban_resilience/features/risk/domain/rainfall_window_calculator.dart';

void main() {
  test('calculates median and percentile based baselines', () {
    const calculator =
        HistoricalFloodBaselineCalculator();

    final result = calculator.calculate(
      hourlyRainfallValues: [
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        8,
        10,
        12,
      ],
      sixHourRainfallValues: [
        6,
        10,
        14,
        18,
        22,
      ],
      riverDischargeValues: [
        100,
        120,
        150,
        180,
        250,
        300,
        400,
        500,
      ],
      referencePeriodStart:
          DateTime.utc(2021, 9, 1),
      referencePeriodEnd:
          DateTime.utc(2025, 9, 30),
    );

    expect(
      result.rainfallBaselineMmPerHour,
      4.5,
    );

    expect(
      result.rainfallCriticalMmPerHour,
      greaterThan(8),
    );

    expect(
      result.rainfallAccumulation6hBaselineMm,
      14,
    );

    expect(
      result.riverDischargeBaselineM3s,
      215,
    );

    expect(
      result.rainfallSampleCount,
      10,
    );

    expect(
      result.riverDischargeSampleCount,
      8,
    );
  });

  test('calculates rolling six-hour rainfall totals', () {
    const calculator = RainfallWindowCalculator();

    final result = calculator.rollingSixHourTotals([
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);

    expect(
      result,
      [21, 27],
    );
  });
}