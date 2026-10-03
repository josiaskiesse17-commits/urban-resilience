import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/hazard_catalog.dart';
import 'package:urban_resilience/features/risk/domain/hazard_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_environmental_data_source.dart';
import 'package:urban_resilience/features/risk/domain/hazard_historical_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_historical_data_source.dart';
import 'package:urban_resilience/features/risk/domain/hazard_risk_service.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_factors.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement_label.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';

class _FakeLive implements HazardEnvironmentalDataSource {
  _FakeLive(this.data);

  final HazardLiveData data;

  @override
  Future<HazardLiveData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
  }) async => data;
}

class _FakeHistorical implements HazardHistoricalDataSource {
  _FakeHistorical(this.data);

  final HazardHistoricalData data;

  @override
  Future<HazardHistoricalData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async => data;
}

class _FakeExposure implements RiskExposureRepository {
  @override
  Future<FloodRiskExposureProfile?> getProfile(String zoneId) async =>
      const FloodRiskExposureProfile(
        zoneId: 'zone-test',
        populationExposureScore: 40,
        infrastructureExposureScore: 50,
        drainageVulnerabilityScore: 70,
        criticalFacilityExposureScore: 60,
        historicalFloodExposureScore: 55,
      );

  @override
  Future<void> saveProfile(FloodRiskExposureProfile profile) async {}
}

/// Plausible value of every field the catalog reads.
const Map<String, double> _fieldBase = <String, double>{
  'rain': 0.8,
  'soil_moisture_0_to_7cm': 0.30,
  'temperature_2m': 30,
  'apparent_temperature': 34,
  'vapour_pressure_deficit': 1.5,
  'wind_gusts_10m': 25,
  'wind_speed_10m': 10,
  'et0_fao_evapotranspiration': 0.15,
  'cape': 900,
};

HazardSeries _series({
  required String field,
  required DateTime start,
  required int hours,
  required double amplitude,
}) {
  final times = <DateTime>[];
  final values = <double?>[];
  final base = _fieldBase[field]!;

  for (var hour = 0; hour < hours; hour++) {
    times.add(start.add(Duration(hours: hour)));
    values.add(base * (1 + amplitude * ((hour % 24) / 24)));
  }

  return HazardSeries(
    field: field,
    unit: _units[field]!,
    times: times,
    values: values,
    source: 'fake-provider',
  );
}

const Map<String, String> _units = <String, String>{
  'rain': 'mm',
  'soil_moisture_0_to_7cm': 'm³/m³',
  'temperature_2m': '°C',
  'apparent_temperature': '°C',
  'vapour_pressure_deficit': 'kPa',
  'wind_gusts_10m': 'km/h',
  'wind_speed_10m': 'km/h',
  'et0_fao_evapotranspiration': 'mm',
  'cape': 'J/kg',
};

HazardLiveData _liveData(
  HazardType hazard, {
  Set<String> omit = const <String>{},
}) {
  final series = <String, HazardSeries>{};
  final missing = <String, String>{};

  for (final field in _fieldBase.keys) {
    if (omit.contains(field)) {
      missing[field] = 'the provider returned no value for this field';
      continue;
    }

    series[field] = _series(
      field: field,
      start: DateTime.utc(2026, 1, 5),
      hours: 24 * 31,
      amplitude: 0.6,
    );
  }

  return HazardLiveData(
    hazard: hazard,
    series: series,
    observedAt: DateTime.utc(2026, 2, 4, 23),
    sources: const <String>['fake-provider'],
    missingFields: missing,
  );
}

HazardHistoricalData _historicalData(HazardType hazard) {
  final series = <String, HazardSeries>{};

  for (final field in _fieldBase.keys) {
    series[field] = _series(
      field: field,
      start: DateTime.utc(2021, 1, 1),
      hours: 24 * 45,
      amplitude: 0.25,
    );
  }

  return HazardHistoricalData(
    hazard: hazard,
    series: series,
    referencePeriodStart: DateTime.utc(2021, 1, 1),
    referencePeriodEnd: DateTime.utc(2021, 2, 14),
    source: 'fake-archive',
  );
}

Future<RiskResult> _assess(
  HazardType hazard, {
  Set<String> omit = const <String>{},
}) {
  final service = HazardRiskService(
    liveDataSource: _FakeLive(_liveData(hazard, omit: omit)),
    historicalDataSource: _FakeHistorical(_historicalData(hazard)),
    referencePeriodStart: DateTime.utc(2021, 1, 1),
    referencePeriodEnd: DateTime.utc(2021, 2, 14),
    exposureRepository: _FakeExposure(),
  );

  return service.calculate(
    zoneId: 'zone-test',
    locationName: 'Test Zone',
    latitude: -4.30,
    longitude: 15.35,
    hazard: hazard,
  );
}

void main() {
  test('DIAGNOSTIC', () async {
    for (final hazard in HazardType.values) {
      if (hazard == HazardType.flooding) {
        continue;
      }

      final result = await _assess(hazard);
      // ignore: avoid_print
      print('=== ${hazard.label} riskScore=${result.riskScore}');

      for (final entry in result.factors.entries) {
        // ignore: avoid_print
        print(
          '  factor ${entry.name} used=${entry.usedInScore} '
          'score=${entry.score} reason=${entry.unavailableReason}',
        );
      }

      for (final measurement in result.evidence.measurements) {
        // ignore: avoid_print
        print('  evidence ${measurement.name} value=${measurement.value}');
      }
    }

    for (final hazard in <HazardType>[HazardType.landslide, HazardType.heat]) {
      for (final field in _fieldBase.keys) {
        final result = await _assess(hazard, omit: <String>{field});

        // ignore: avoid_print
        print(
          '=== ${hazard.label} omit $field -> riskScore=${result.riskScore} '
          'scored=${result.factors.entries.where((entry) => entry.usedInScore).map((entry) => entry.name).toList()} '
          'indicators=${result.evidence.qualitativeIndicators.where((item) => item.startsWith('Not measured')).toList()}',
        );
      }
    }
  });

  test('every used factor of every hazard has its own evidence', () async {
    for (final hazard in HazardCatalog.genericHazards) {
      final result = await _assess(hazard);
      final measurements = <String, RiskMeasurement>{
        for (final measurement in result.evidence.measurements)
          measurement.name: measurement,
      };

      expect(
        result.factors.entries,
        isNotEmpty,
        reason: '${hazard.label} produced no factor',
      );

      for (final entry in result.factors.entries) {
        if (!entry.usedInScore) {
          continue;
        }

        expect(entry.score, isNotNull, reason: '${hazard.label}/${entry.name}');

        for (final name in entry.evidenceNames) {
          final measurement = measurements[name];

          expect(
            measurement,
            isNotNull,
            reason:
                'the factor ${entry.name} of ${hazard.label} is '
                'displayed without an evidence measurement named $name',
          );

          expect(measurement!.unit, isNotEmpty, reason: '$name has no unit');

          expect(
            measurement.value.isFinite,
            isTrue,
            reason: '$name has no real value',
          );
        }

        if (entry.evidenceNames.length == 1) {
          final measurement = measurements[entry.name]!;

          expect(
            entry.label,
            RiskMeasurementLabel.of(
              name: measurement.name,
              measurementPeriod: measurement.measurementPeriod,
              unit: measurement.unit,
            ),
            reason: 'the risk factor and its evidence must read the same',
          );
        }
      }
    }
  });

  test('an unavailable factor is never presented as a measured zero', () async {
    for (final hazard in HazardCatalog.genericHazards) {
      final result = await _assess(hazard);
      final measurements = result.evidence.measurements
          .map((measurement) => measurement.name)
          .toSet();

      for (final entry in result.factors.entries) {
        if (entry.usedInScore) {
          continue;
        }

        expect(entry.score, isNull, reason: entry.name);
        expect(entry.unavailableReason, isNotNull, reason: entry.name);
        expect(
          measurements,
          isNot(contains(entry.name)),
          reason:
              '${entry.name} has no measured value, so it must not appear '
              'in the evidence as a number',
        );
      }
    }
  });

  test('no variable of another hazard is displayed', () async {
    for (final hazard in HazardCatalog.genericHazards) {
      final own = HazardCatalog.of(hazard).variables
          .map((variable) => variable.name)
          .toSet();
      final foreign = <String>{};

      for (final other in HazardType.values) {
        if (other == hazard) {
          continue;
        }

        for (final spec in HazardCatalog.of(other).variables) {
          if (!own.contains(spec.name)) {
            foreign.add(spec.name);
          }
        }
      }

      final result = await _assess(hazard);

      expect(
        result.evidence.measurements
            .map((measurement) => measurement.name)
            .toSet()
            .intersection(foreign),
        isEmpty,
        reason: '${hazard.label} evidence',
      );

      expect(
        result.factors.entries
            .map((entry) => entry.name)
            .toSet()
            .intersection(foreign),
        isEmpty,
        reason: '${hazard.label} factors',
      );
    }
  });

  test('a measured variable without a usable reference stays in the evidence, '
      'never in the factors', () async {
    final result = await _assess(HazardType.landslide);

    final measurements = result.evidence.measurements
        .map((measurement) => measurement.name)
        .toSet();
    final factors = result.factors.entries.map((entry) => entry.name).toSet();

    // The synthetic reference series makes the 24 h accumulation constant,
    // so it carries no usable statistical reference: its value is real
    // evidence, but it played no role in the score, so it must not be
    // shown as a factor (available or unavailable).
    expect(measurements, contains('rainfallAccumulation24h'));
    expect(factors, isNot(contains('rainfallAccumulation24h')));

    // The exclusion is reported explicitly instead of being dropped.
    expect(
      result.evidence.qualitativeIndicators.join(' '),
      contains('Non pris en compte : Cumul de pluie — dernières 24 heures'),
    );
    expect(
      result.evidence.qualitativeIndicators.join(' '),
      contains('exclue du score au lieu d’être comptée comme un zéro'),
    );
  });

  test('the factor breakdown survives the stored JSON round trip', () async {
    final result = await _assess(HazardType.heat);
    final restored = RiskResult.fromJson(result.toJson());

    expect(restored.factors.entries.length, result.factors.entries.length);

    for (var index = 0; index < result.factors.entries.length; index++) {
      final original = result.factors.entries[index];
      final copy = restored.factors.entries[index];

      expect(copy.name, original.name);
      expect(copy.label, original.label);
      expect(copy.score, original.score);
      expect(copy.usedInScore, original.usedInScore);
      expect(copy.unavailableReason, original.unavailableReason);
      expect(copy.componentNames, original.componentNames);
    }
  });

  test(
    'a document stored before the breakdown keeps its four legacy scores',
    () {
      final factors = RiskFactors.fromJson(<String, dynamic>{
        'rainfall': 55.0,
        'geographicVulnerability': 40.0,
        'historicalExposure': 35.0,
        'currentObservations': 0.0,
        'primaryFactorLabel': 'Rainfall',
      });

      expect(factors.entries, isEmpty);
      expect(factors.rainfall, 55);
      expect(factors.geographicVulnerability, 40);
      expect(factors.historicalExposure, 35);
      expect(factors.currentObservations, 0);
    },
  );
}
