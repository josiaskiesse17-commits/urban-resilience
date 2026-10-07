import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/historical_flood_baseline_calculator.dart';
import 'package:urban_resilience/features/risk/domain/rainfall_window_calculator.dart';

void main() {
  test('calculates median and percentile based baselines', () {
    const calculator = HistoricalFloodBaselineCalculator();

    final result = calculator.calculate(
      hourlyRainfallValues: [0, 1, 2, 3, 4, 5, 6, 8, 10, 12],
      sixHourRainfallValues: [6, 10, 14, 18, 22],
      riverDischargeValues: [100, 120, 150, 180, 250, 300, 400, 500],
      referencePeriodStart: DateTime.utc(2021, 9, 1),
      referencePeriodEnd: DateTime.utc(2025, 9, 30),
    );

    expect(result.rainfallBaselineMmPerHour, 4.5);

    expect(result.rainfallCriticalMmPerHour, greaterThan(8));

    expect(result.rainfallAccumulation6hBaselineMm, 14);

    expect(result.riverDischargeBaselineM3s, 215);

    expect(result.rainfallSampleCount, 10);

    expect(result.riverDischargeSampleCount, 8);
  });

  test('calculates rolling six-hour rainfall totals', () {
    const calculator = RainfallWindowCalculator();

    final result = calculator.rollingSixHourTotals([1, 2, 3, 4, 5, 6, 7]);

    expect(result, [21, 27]);
  });

  test('rolling six-hour totals never bridge a gap in the series', () {
    const calculator = RainfallWindowCalculator();
    final start = DateTime.utc(2022, 1, 1);

    final times = <DateTime>[
      for (var hour = 0; hour < 6; hour++)
        start.add(Duration(hours: hour)),
      // 14 missing hours before the next run of hourly samples.
      for (var hour = 20; hour < 26; hour++)
        start.add(Duration(hours: hour)),
    ];

    final result = calculator.rollingSixHourTotals(
      List<double>.filled(12, 1),
      times: times,
    );

    // Only the two complete hourly runs count; the legacy index-based loop
    // would have produced seven windows, most spanning the gap.
    expect(result, [6, 6]);
  });

  test('rolling six-hour totals sort unordered timestamped samples', () {
    const calculator = RainfallWindowCalculator();
    final start = DateTime.utc(2022, 1, 1);

    final values = <double>[7, 6, 5, 4, 3, 2, 1];
    final times = <DateTime>[
      for (var hour = 6; hour >= 0; hour--)
        start.add(Duration(hours: hour)),
    ];

    final result = calculator.rollingSixHourTotals(values, times: times);

    expect(result, [21, 27]);
  });

  test('rolling six-hour totals refuse insufficient or invalid samples', () {
    const calculator = RainfallWindowCalculator();

    expect(calculator.rollingSixHourTotals([1, 2, 3]), isEmpty);

    expect(
      calculator.rollingSixHourTotals(List<double>.filled(7, double.nan)),
      isEmpty,
    );

    final start = DateTime.utc(2022, 1, 1);
    final times = <DateTime>[
      for (var hour in [0, 1, 2, 3, 4, 10]) start.add(Duration(hours: hour)),
    ];

    expect(
      calculator.rollingSixHourTotals(
        List<double>.filled(6, 1),
        times: times,
      ),
      isEmpty,
    );
  });
}
