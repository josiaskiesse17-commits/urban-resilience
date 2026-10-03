import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_series_utils.dart';

HazardSample sample(int hour, double value) {
  return (
    time: DateTime.utc(2026, 1, 1, hour),
    value: value,
  );
}

void main() {
  test(
    'align drops unusable entries and sorts by time',
    () {
      final samples = HazardSeriesUtils.align(
        times: [
          '2026-01-01T02:00Z',
          'not-a-date',
          '2026-01-01T01:00Z',
        ],
        values: [2.0, null, 1.0],
      );

      expect(samples, hasLength(2));
      expect(samples.first.time.hour, 1);
      expect(samples.first.value, 1.0);
      expect(samples.last.time.hour, 2);
      expect(samples.last.value, 2.0);
    },
  );

  test('trailingSums sums contiguous windows only', () {
    final contiguous = HazardSeriesUtils.trailingSums(
      hourly: [
        sample(0, 1),
        sample(1, 2),
        sample(2, 3),
        sample(3, 4),
        sample(4, 5),
      ],
      window: 3,
    );

    expect(contiguous, hasLength(3));
    expect(contiguous.first.value, 6);
    expect(contiguous.first.time.hour, 2);
    expect(contiguous.last.value, 12);
    expect(contiguous.last.time.hour, 4);
  });

  test('trailingSums never spans a gap', () {
    final gapped = HazardSeriesUtils.trailingSums(
      hourly: [
        sample(0, 1),
        sample(1, 2),
        sample(2, 3),
        
        sample(4, 4),
        sample(5, 5),
        sample(6, 6),
      ],
      window: 3,
    );

    expect(gapped, hasLength(2));
    expect(gapped.first.time.hour, 2);
    expect(gapped.first.value, 6);
    expect(gapped.last.time.hour, 6);
    expect(gapped.last.value, 15);
  });

  test('trailing maxima and minima respect the window', () {
    final maxima = HazardSeriesUtils.trailingMaxima(
      hourly: [
        sample(0, 3),
        sample(1, 9),
        sample(2, 4),
      ],
      window: 3,
    );

    expect(maxima.single.value, 9);

    final minima = HazardSeriesUtils.trailingMinima(
      hourly: [
        sample(0, 3),
        sample(1, 9),
        sample(2, 4),
      ],
      window: 3,
    );

    expect(minima.single.value, 3);
  });

  test(
    'applyWindow returns the last sample for an instant window',
    () {
      final last = HazardSeriesUtils.applyWindow(
        hourly: [sample(0, 1), sample(1, 7)],
        window: HazardWindow.instant,
      );

      expect(last.single.value, 7);
      expect(last.single.time.hour, 1);
    },
  );

  test('applyWindow produces nothing without a full window', () {
    expect(
      HazardSeriesUtils.applyWindow(
        hourly: [sample(0, 1), sample(1, 2)],
        window: HazardWindow.sum6h,
      ),
      isEmpty,
    );
  });

  test('byMonth buckets samples per calendar month', () {
    final buckets = HazardSeriesUtils.byMonth([
      sample(0, 1),
      (
        time: DateTime.utc(2026, 2, 3),
        value: 5,
      ),
      (
        time: DateTime.utc(2026, 1, 15),
        value: 3,
      ),
    ]);

    expect(buckets.keys, {1, 2});
    expect(buckets[1], [1, 3]);
    expect(buckets[2], [5]);
  });

  test('lastSample returns null for an empty series', () {
    expect(
      HazardSeriesUtils.lastSample(const <HazardSample>[]),
      isNull,
    );
  });
}