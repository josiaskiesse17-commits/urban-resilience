import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:urban_resilience/features/risk/data/open_meteo_hazard_data_source.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';

void main() {
  test('builds the request from the catalog and parses the series', () async {
    late Uri requested;

    final client = MockClient((request) async {
      requested = request.url;

      return http.Response('''
          {
            "hourly_units": {
              "temperature_2m": "°C",
              "apparent_temperature": "°C"
            },
            "hourly": {
              "time": [
                "2026-01-05T00:00Z",
                "2026-01-05T01:00Z",
                "2026-01-05T02:00Z"
              ],
              "temperature_2m": [30.0, 31.0, null],
              "apparent_temperature": [33.0, 34.0, 35.0]
            }
          }
          ''', 200);
    });

    final source = OpenMeteoHazardDataSource(client: client);

    final live = await source.fetch(
      hazard: HazardType.heat,
      latitude: -4.30,
      longitude: 15.35,
    );

    expect(requested.host, 'api.open-meteo.com');
    expect(
      requested.queryParameters['hourly'],
      'temperature_2m,apparent_temperature',
    );
    expect(requested.queryParameters['forecast_days'], '0');
    expect(requested.queryParameters['past_days'], '2');

    expect(live.series.keys, <String>[
      'temperature_2m',
      'apparent_temperature',
    ]);
    expect(live.series['temperature_2m']!.unit, '°C');

    expect(live.series['temperature_2m']!.sampleCount, 2);
    expect(live.observedAt, DateTime.utc(2026, 1, 5, 2));
    expect(live.sources, contains('Open-Meteo Weather API'));
    expect(live.missingFields, isEmpty);
  });

  test(
    'a field the provider does not return becomes a missing field',
    () async {
      final client = MockClient((request) async {
        return http.Response('''
          {
            "hourly": {
              "time": ["2026-01-05T00:00"],
              "temperature_2m": [30.0]
            }
          }
          ''', 200);
      });

      final source = OpenMeteoHazardDataSource(client: client);

      final live = await source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
      );

      expect(live.series.keys, <String>['temperature_2m']);
      expect(live.missingFields.keys, contains('apparent_temperature'));
      expect(live.providerNotes.join(' '), contains('Live data missing'));
    },
  );

  test('an API error is reported as a FormatException', () async {
    final client = MockClient((request) async {
      return http.Response('{"error": true, "reason": "Invalid"}', 200);
    });

    final source = OpenMeteoHazardDataSource(client: client);

    expect(
      () => source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Invalid'),
        ),
      ),
    );
  });

  test('a failed HTTP status becomes an HttpException', () async {
    final client = MockClient((request) async {
      return http.Response('server error', 500);
    });

    final source = OpenMeteoHazardDataSource(client: client);

    expect(
      () => source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
      ),
      throwsA(isA<HttpException>()),
    );
  });
}
