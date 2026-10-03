import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_baseline_calculator.dart';
import 'package:urban_resilience/features/risk/domain/hazard_catalog.dart';
import 'package:urban_resilience/features/risk/domain/hazard_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_historical_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_series_utils.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';

HazardHistoricalData buildRainfallData() {
  final times = <DateTime>[];
  final values = <double?>[];

  var cursor = DateTime.utc(2021, 1, 1);

  for (var hour = 0; hour < 24 * 45; hour++) {
    times.add(cursor);
    values.add((hour % 10).toDouble());
    cursor = cursor.add(const Duration(hours: 1));
  }

  return HazardHistoricalData(
    hazard: HazardType.landslide,
    series: <String, HazardSeries>{
      'rain': HazardSeries(
        field: 'rain',
        unit: 'mm',
        times: times,
        values: values,
        source: 'test',
      ),
    },
    referencePeriodStart: DateTime.utc(2021, 1, 1),
    referencePeriodEnd: DateTime.utc(2021, 2, 14),
    source: 'test',
  );
}

void main() {
  const calculator = HazardBaselineCalculator();
  final definition = HazardCatalog.landslide;

  test('builds seasonal references over matching windows', () {
    final data = buildRainfallData();
    final baseline = calculator.calculate(definition: definition, data: data);

    expect(
      baseline.variables.keys,
      containsAll(<String>[
        'rainfallAccumulation24h',
        'rainfallAccumulation72h',
      ]),
    );

    final rainfall24h = baseline.variableFor('rainfallAccumulation24h')!;

    expect(rainfall24h.unit, 'mm');
    expect(rainfall24h.window, HazardWindow.sum24h);
    expect(rainfall24h.overall.sampleCount, 24 * 45 - 23);
    expect(rainfall24h.seasonal, isTrue);
    expect(rainfall24h.byMonth.keys, <int>{1, 2});

    final rainfall72h = baseline.variableFor('rainfallAccumulation72h')!;

    expect(rainfall72h.overall.sampleCount, 24 * 45 - 71);

    expect(baseline.referencePeriodStart, data.referencePeriodStart);
    expect(baseline.referencePeriodEnd, data.referencePeriodEnd);
    expect(baseline.source, 'test');
    expect(baseline.hazard, HazardType.landslide);
  });

  test('slices prefer the same calendar month and fall back outside it', () {
    final baseline = calculator.calculate(
      definition: definition,
      data: buildRainfallData(),
    );

    final reference = baseline.variableFor('rainfallAccumulation24h')!;

    final february = reference.sliceFor(DateTime.utc(2021, 2, 10));

    expect(february.usedSeasonalBucket, isTrue);
    expect(february.month, 2);
    expect(february.distribution, same(reference.byMonth[2]));

    final july = reference.sliceFor(DateTime.utc(2021, 7, 10));

    expect(july.usedSeasonalBucket, isFalse);
    expect(july.distribution, same(reference.overall));
  });

  test('a variable without a historical series becomes a note, not a zero', () {
    final baseline = calculator.calculate(
      definition: definition,
      data: buildRainfallData(),
    );

    expect(baseline.variableFor('soilMoisture0to7cm'), isNull);
    expect(baseline.notes.join(' '), contains('soil_moisture_0_to_7cm'));
  });

  test('reports when no month is large enough for a seasonal reference', () {
    final baseline = calculator.calculate(
      definition: definition,
      data: buildRainfallData(),
      minimumSeasonalSamples: 100000,
    );

    final reference = baseline.variableFor('rainfallAccumulation24h')!;

    expect(reference.seasonal, isFalse);
    expect(reference.byMonth, isEmpty);
    expect(baseline.notes.join(' '), contains('whole-period statistics'));
    expect(
      reference.sliceFor(DateTime.utc(2021, 2, 10)).usedSeasonalBucket,
      isFalse,
    );
  });

  test('a definition without a seasonal reference stays whole-period', () {
    final baseline = calculator.calculate(
      definition: HazardCatalog.flooding,
      data: HazardHistoricalData(
        hazard: HazardType.flooding,
        series: <String, HazardSeries>{},
        referencePeriodStart: DateTime.utc(2018, 1, 1),
        referencePeriodEnd: DateTime.utc(2022, 7, 31),
        source: 'test',
      ),
    );

    expect(baseline.variables, isEmpty);
    expect(HazardCatalog.flooding.seasonalReference, isFalse);
  });
}
