import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_baseline.dart';
import 'package:urban_resilience/features/risk/domain/hazard_definition.dart';
import 'package:urban_resilience/features/risk/domain/hazard_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_series_utils.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/hazard_variable_builder.dart';
import 'package:urban_resilience/features/risk/domain/historical_distribution.dart';

const HazardDefinition _definition = HazardDefinition(
  hazard: HazardType.heat,
  primaryFactorLabel: 'Test factor',
  description: 'Synthetic definition for the builder tests.',
  variables: <HazardVariableSpec>[
    HazardVariableSpec(
      name: 'soilMoisture',
      label: 'Soil moisture',
      apiField: 'soil',
      source: HazardVariableSource.openMeteoWeather,
      window: HazardWindow.instant,
      unit: 'x',
      weight: 0.6,
    ),
    HazardVariableSpec(
      name: 'rain6h',
      label: 'Rain (6 h)',
      apiField: 'rain',
      source: HazardVariableSource.openMeteoWeather,
      window: HazardWindow.sum6h,
      unit: 'mm',
      weight: 0.4,
      derived: true,
      derivationNote: 'sum of the last 6 hours',
    ),
    HazardVariableSpec(
      name: 'capeLike',
      label: 'CAPE-like',
      apiField: 'cape',
      source: HazardVariableSource.openMeteoWeather,
      window: HazardWindow.instant,
      unit: 'J/kg',
      weight: 0,
      informational: true,
      hasHistoricalReference: false,
    ),
  ],
);

HazardSeries _series(
  String field,
  List<DateTime> times,
  List<double?> values,
) {
  return HazardSeries(
    field: field,
    unit: 'u',
    times: times,
    values: values,
    source: 'test-provider',
  );
}

HazardBaseline _baseline({required bool seasonal}) {
  return HazardBaseline(
    hazard: HazardType.heat,
    variables: <String, HazardBaselineVariable>{
      'soilMoisture': HazardBaselineVariable(
        name: 'soilMoisture',
        unit: 'x',
        window: HazardWindow.instant,
        overall: HistoricalDistribution(
          List<double>.generate(60, (index) => index * 2.0),
        ),
        byMonth: <int, HistoricalDistribution>{
          1: HistoricalDistribution(
            List<double>.generate(30, (index) => index + 5.0),
          ),
        },
        seasonal: seasonal,
      ),
    },
    referencePeriodStart: DateTime.utc(2020, 1, 1),
    referencePeriodEnd: DateTime.utc(2024, 12, 31),
    generatedAt: DateTime.utc(2025, 1, 1),
    source: 'test-archive',
  );
}

void main() {
  const builder = HazardVariableBuilder();

  test(
    'scores a variable against its seasonal reference and reports gaps',
    () {
      final liveData = HazardLiveData(
        hazard: HazardType.heat,
        series: <String, HazardSeries>{
          'soil': _series(
            'soil',
            [
              DateTime.utc(2026, 1, 5, 10),
              DateTime.utc(2026, 1, 5, 11),
            ],
            <double?>[0.2, 0.3],
          ),
          // Only three hours: no complete 6-hour window.
          'rain': _series(
            'rain',
            [
              DateTime.utc(2026, 1, 5, 9),
              DateTime.utc(2026, 1, 5, 10),
              DateTime.utc(2026, 1, 5, 11),
            ],
            <double?>[1, 2, 3],
          ),
          'cape': _series(
            'cape',
            [DateTime.utc(2026, 1, 5, 11)],
            <double?>[400],
          ),
        },
        observedAt: DateTime.utc(2026, 1, 5, 11),
        sources: const <String>['test-provider'],
      );

      final result = builder.build(
        definition: _definition,
        liveData: liveData,
        baseline: _baseline(seasonal: true),
      );

      expect(
        result.variables.map((item) => item.name),
        <String>['soilMoisture', 'capeLike'],
      );

      final soil = result.variables.first;

      expect(soil.isScorable, isTrue);
      expect(soil.score, isNotNull);
      expect(soil.historicalPercentile, isNotNull);
      expect(soil.measurementPeriod, 'instant');
      expect(soil.source, 'test-provider');
      expect(
        soil.referenceLabel,
        contains('du mois de janvier'),
      );

      final cape = result.variables.last;

      expect(cape.informational, isTrue);
      expect(cape.score, isNull);
      expect(cape.observedAt, DateTime.utc(2026, 1, 5, 11));

      expect(
        result.gaps.map((gap) => gap.name),
        containsAll(<String>['rain6h']),
      );

      final windowGap = result.gaps.firstWhere(
        (gap) => gap.name == 'rain6h',
      );

      expect(
        windowGap.reason,
        contains('aucune fenêtre 6h complète'),
      );
    },
  );

  test(
    'a missing provider field becomes an explicit gap, never a zero',
    () {
      final liveData = HazardLiveData(
        hazard: HazardType.heat,
        series: <String, HazardSeries>{
          'soil': _series(
            'soil',
            [DateTime.utc(2026, 1, 5, 11)],
            <double?>[0.3],
          ),
          'cape': _series(
            'cape',
            [DateTime.utc(2026, 1, 5, 11)],
            <double?>[400],
          ),
        },
        observedAt: DateTime.utc(2026, 1, 5, 11),
        sources: const <String>['test-provider'],
        missingFields: const <String, String>{
          'rain': 'the live provider returned no value',
        },
      );

      final result = builder.build(
        definition: _definition,
        liveData: liveData,
        baseline: _baseline(seasonal: true),
      );

      expect(
        result.variables.map((item) => item.name),
        isNot(contains('rain6h')),
      );

      final gap = result.gaps.singleWhere(
        (item) => item.name == 'rain6h',
      );

      expect(gap.reason, contains('no value'));
    },
  );

  test(
    'falls back to the whole reference period without a seasonal bucket',
    () {
      final liveData = HazardLiveData(
        hazard: HazardType.heat,
        series: <String, HazardSeries>{
          'soil': _series(
            'soil',
            [DateTime.utc(2026, 1, 5, 11)],
            <double?>[0.3],
          ),
          'rain': _series(
            'rain',
            [
              DateTime.utc(2026, 1, 5, 6),
              DateTime.utc(2026, 1, 5, 7),
              DateTime.utc(2026, 1, 5, 8),
              DateTime.utc(2026, 1, 5, 9),
              DateTime.utc(2026, 1, 5, 10),
              DateTime.utc(2026, 1, 5, 11),
            ],
            <double?>[1, 1, 1, 1, 1, 1],
          ),
          'cape': _series(
            'cape',
            [DateTime.utc(2026, 1, 5, 11)],
            <double?>[400],
          ),
        },
        observedAt: DateTime.utc(2026, 1, 5, 11),
        sources: const <String>['test-provider'],
      );

      final result = builder.build(
        definition: _definition,
        liveData: liveData,
        baseline: _baseline(seasonal: false),
      );

      final soil = result.variables.first;

      expect(
        soil.referenceLabel,
        contains('toute la période de référence'),
      );
    },
  );
}