import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:urban_resilience/features/risk/data/open_meteo_hazard_data_source.dart';
import 'package:urban_resilience/features/risk/domain/flood_risk_exposure_profile.dart';
import 'package:urban_resilience/features/risk/domain/hazard_environmental_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_environmental_data_source.dart';
import 'package:urban_resilience/features/risk/domain/hazard_historical_data.dart';
import 'package:urban_resilience/features/risk/domain/hazard_historical_data_source.dart';
import 'package:urban_resilience/features/risk/domain/hazard_risk_service.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/risk_exposure_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_result_repository.dart';

class _FakeLive implements HazardEnvironmentalDataSource {
  _FakeLive(this.data);

  final HazardLiveData data;
  int calls = 0;

  @override
  Future<HazardLiveData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
  }) async {
    calls++;

    return data;
  }
}

class _FakeHistorical implements HazardHistoricalDataSource {
  _FakeHistorical(this.data);

  final HazardHistoricalData data;
  int calls = 0;

  @override
  Future<HazardHistoricalData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    calls++;

    return data;
  }
}

class _FakeExposureRepository implements RiskExposureRepository {
  _FakeExposureRepository(this.profile);

  FloodRiskExposureProfile? profile;

  @override
  Future<FloodRiskExposureProfile?> getProfile(String zoneId) async => profile;

  @override
  Future<void> saveProfile(FloodRiskExposureProfile profile) async {
    this.profile = profile;
  }
}

class _FakeResultRepository implements RiskResultRepository {
  RiskResult? saved;

  @override
  Future<RiskResult?> get(String riskId) async => saved;

  @override
  Future<RiskResult?> getLatestForZone(String zoneId) async => saved;

  @override
  Future<void> save(RiskResult result) async {
    saved = result;
  }
}

HazardLiveData _liveHeatData() {
  final times = <DateTime>[];
  final temperatures = <double?>[];
  final apparent = <double?>[];

  for (var hour = 0; hour < 30; hour++) {
    times.add(DateTime.utc(2026, 1, 5).add(Duration(hours: hour)));
    temperatures.add(30 + ((hour ~/ 24) % 10).toDouble());
    apparent.add(33 + ((hour ~/ 24) % 10).toDouble());
  }

  return HazardLiveData(
    hazard: HazardType.heat,
    series: <String, HazardSeries>{
      'temperature_2m': HazardSeries(
        field: 'temperature_2m',
        unit: '°C',
        times: times,
        values: temperatures,
        source: 'fake-weather',
      ),
      'apparent_temperature': HazardSeries(
        field: 'apparent_temperature',
        unit: '°C',
        times: times,
        values: apparent,
        source: 'fake-weather',
      ),
    },
    observedAt: DateTime.utc(2026, 1, 6, 5),
    sources: const <String>['fake-weather'],
    providerNotes: const <String>['live provider note'],
  );
}

HazardHistoricalData _historicalHeatData() {
  final times = <DateTime>[];
  final temperatures = <double?>[];
  final apparent = <double?>[];

  var cursor = DateTime.utc(2021, 1, 1);

  for (var hour = 0; hour < 24 * 45; hour++) {
    times.add(cursor);
    temperatures.add(28 + ((hour ~/ 24) % 8).toDouble());
    apparent.add(30 + ((hour ~/ 24) % 8).toDouble());
    cursor = cursor.add(const Duration(hours: 1));
  }

  return HazardHistoricalData(
    hazard: HazardType.heat,
    series: <String, HazardSeries>{
      'temperature_2m': HazardSeries(
        field: 'temperature_2m',
        unit: '°C',
        times: times,
        values: temperatures,
        source: 'fake-archive',
      ),
      'apparent_temperature': HazardSeries(
        field: 'apparent_temperature',
        unit: '°C',
        times: times,
        values: apparent,
        source: 'fake-archive',
      ),
    },
    referencePeriodStart: DateTime.utc(2021, 1, 1),
    referencePeriodEnd: DateTime.utc(2021, 2, 14),
    source: 'fake-archive',
  );
}

http.Response _openMeteoResponse({required Map<String, List<double?>> series}) {
  final times = <String>[
    for (var hour = 0; hour < 30; hour++)
      DateTime.utc(2026, 1, 5).add(Duration(hours: hour)).toIso8601String(),
  ];

  return http.Response(
    jsonEncode(<String, dynamic>{
      'hourly_units': <String, String>{
        for (final field in series.keys) field: '°C',
      },
      'hourly': <String, dynamic>{'time': times, ...series},
    }),
    200,
  );
}

void main() {
  late _FakeLive live;
  late _FakeHistorical historical;
  late _FakeExposureRepository exposure;
  late _FakeResultRepository results;
  late HazardRiskService service;

  setUp(() {
    live = _FakeLive(_liveHeatData());
    historical = _FakeHistorical(_historicalHeatData());
    exposure = _FakeExposureRepository(
      const FloodRiskExposureProfile(
        zoneId: 'zone-test',
        populationExposureScore: 40,
        infrastructureExposureScore: 50,
        drainageVulnerabilityScore: 70,
        criticalFacilityExposureScore: 60,
        historicalFloodExposureScore: 55,
      ),
    );
    results = _FakeResultRepository();

    service = HazardRiskService(
      liveDataSource: live,
      historicalDataSource: historical,
      referencePeriodStart: DateTime.utc(2021, 1, 1),
      referencePeriodEnd: DateTime.utc(2021, 2, 14),
      exposureRepository: exposure,
      riskResultRepository: results,
    );
  });

  test('generates a hazard-aware assessment for a zone', () async {
    final result = await service.calculate(
      zoneId: 'zone-test',
      locationName: 'Test Zone',
      latitude: -4.30,
      longitude: 15.35,
      hazard: HazardType.heat,
    );

    expect(result.id, 'zone-test--heat');
    expect(result.hazardType, 'Heat');
    expect(result.locationName, 'Test Zone');
    expect(result.updatedAt, DateTime.utc(2026, 1, 6, 5));
    expect(result.factors.primaryFactorLabel, 'Heat');
    expect(result.riskScore, greaterThan(0));

    expect(result.factors.geographicVulnerability, closeTo(49.5, 0.001));

    expect(result.factors.historicalExposure, 0);

    final names = result.evidence.measurements
        .map((item) => item.name)
        .toList();

    expect(names, contains('temperature2mMax24h'));
    expect(names, contains('apparentTemperatureMax24h'));

    final indicators = result.evidence.qualitativeIndicators.join('\n');

    expect(indicators, contains('Référence statistique :'));
    expect(indicators, contains('même mois calendaire'));
    expect(
      indicators,
      contains('La vulnérabilité combine l’exposition de la population'),
    );
    expect(indicators, contains('live provider note'));
  });

  test('refuses to score flooding with the generic engine', () {
    expect(
      service.calculate(
        zoneId: 'zone-test',
        locationName: 'Test Zone',
        latitude: -4.30,
        longitude: 15.35,
        hazard: HazardType.flooding,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('reuses the cached baseline between assessments', () async {
    Future<RiskResult> run() => service.calculate(
      zoneId: 'zone-test',
      locationName: 'Test Zone',
      latitude: -4.30,
      longitude: 15.35,
      hazard: HazardType.heat,
    );

    await run();
    await run();

    expect(historical.calls, 1);

    service.clearBaselineCache();
    await run();

    expect(historical.calls, 2);
  });

  test('persists the result under its hazard-aware id', () async {
    final result = await service.calculateAndSave(
      zoneId: 'zone-test',
      locationName: 'Test Zone',
      latitude: -4.30,
      longitude: 15.35,
      hazard: HazardType.heat,
    );

    expect(results.saved, isNotNull);
    expect(results.saved!.id, 'zone-test--heat');
    expect(result.id, results.saved!.id);
  });

  test('reports a missing exposure profile explicitly', () async {
    exposure.profile = null;

    final result = await service.calculate(
      zoneId: 'zone-test',
      locationName: 'Test Zone',
      latitude: -4.30,
      longitude: 15.35,
      hazard: HazardType.heat,
    );

    final indicators = result.evidence.qualitativeIndicators.join('\n');

    expect(
      indicators,
      contains('Aucun profil d’exposition enregistré n’a été trouvé'),
    );
  });

  test(
    'receives the live environmental data and maps it into the evidence',
    () async {
      late Uri requested;

      final client = MockClient((request) async {
        requested = request.url;

        return _openMeteoResponse(
          series: <String, List<double?>>{
            'temperature_2m': <double?>[
              for (var hour = 0; hour < 30; hour++)
                hour < 6
                    ? 20.0
                    : hour == 29
                    ? 41.0
                    : 30.0,
            ],
            'apparent_temperature': <double?>[
              for (var hour = 0; hour < 30; hour++)
                hour < 6
                    ? 20.0
                    : hour == 29
                    ? 44.0
                    : 35.0,
            ],
          },
        );
      });

      final service = HazardRiskService(
        liveDataSource: OpenMeteoHazardDataSource(client: client),
        historicalDataSource: historical,
        referencePeriodStart: DateTime.utc(2021, 1, 1),
        referencePeriodEnd: DateTime.utc(2021, 2, 14),
        exposureRepository: exposure,
      );

      final result = await service.calculate(
        zoneId: 'zone-test',
        locationName: 'Test Zone',
        latitude: -4.30,
        longitude: 15.35,
        hazard: HazardType.heat,
      );

      expect(requested.host, 'api.open-meteo.com');
      expect(
        requested.queryParameters['hourly'],
        'temperature_2m,apparent_temperature',
      );

      final measurements = result.evidence.measurements;

      RiskMeasurement measurement(String name) =>
          measurements.firstWhere((item) => item.name == name);

      expect(measurement('temperature2mMax24h').value, 41.0);
      expect(measurement('temperature2mMin24h').value, 30.0);
      expect(measurement('apparentTemperatureMax24h').value, 44.0);

      expect(measurement('temperature2mMax24h').unit, '°C');
      expect(measurement('temperature2mMax24h').measurementPeriod, '24h');
      expect(
        measurement('temperature2mMax24h').source,
        'Open-Meteo Weather API',
      );

      expect(measurement('temperature2mMax24h').referenceValue, isNotNull);
      expect(
        measurement('temperature2mMax24h').historicalPercentile,
        isNotNull,
      );
      expect(result.riskScore, greaterThan(0));
    },
  );

  test(
    'a live field the provider does not return becomes a gap, never a zero',
    () async {
      final client = MockClient((request) async {
        return _openMeteoResponse(
          series: <String, List<double?>>{
            'temperature_2m': <double?>[
              for (var hour = 0; hour < 30; hour++) 31.5,
            ],
          },
        );
      });

      final service = HazardRiskService(
        liveDataSource: OpenMeteoHazardDataSource(client: client),
        historicalDataSource: historical,
        referencePeriodStart: DateTime.utc(2021, 1, 1),
        referencePeriodEnd: DateTime.utc(2021, 2, 14),
        exposureRepository: exposure,
      );

      final result = await service.calculate(
        zoneId: 'zone-test',
        locationName: 'Test Zone',
        latitude: -4.30,
        longitude: 15.35,
        hazard: HazardType.heat,
      );

      final names = result.evidence.measurements
          .map((item) => item.name)
          .toList();

      expect(names, contains('temperature2mMax24h'));
      expect(names, isNot(contains('apparentTemperatureMax24h')));

      final indicators = result.evidence.qualitativeIndicators.join('\n');

      expect(indicators, contains('Non mesuré : Maximum apparent temperature'));
      expect(indicators, contains('jamais comme un zéro'));

      expect(
        result.evidence.measurements.where(
          (item) => item.name == 'apparentTemperatureMax24h' && item.value == 0,
        ),
        isEmpty,
      );

      expect(
        result.evidence.measurements
            .firstWhere((item) => item.name == 'temperature2mMax24h')
            .value,
        31.5,
      );
    },
  );
}
