import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:urban_resilience/features/risk/data/open_meteo_hazard_historical_data_source.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';

void main() {
  test(
    'requests the archive with catalog fields and parses the series',
    () async {
      late Uri requested;

      final client = MockClient((request) async {
        requested = request.url;

        return http.Response('''
          {
            "hourly": {
              "time": [
                "2021-01-01T00:00",
                "2021-01-01T01:00",
                "2021-01-01T02:00"
              ],
              "temperature_2m": [28.0, 29.0, null],
              "apparent_temperature": [30.0, 31.0, 32.0]
            }
          }
          ''', 200);
      });

      final source = OpenMeteoHazardHistoricalDataSource(client: client);

      final data = await source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
        startDate: DateTime.utc(2021, 1, 1),
        endDate: DateTime.utc(2021, 2, 14),
      );

      expect(requested.host, 'archive-api.open-meteo.com');
      expect(requested.queryParameters['start_date'], '2021-01-01');
      expect(requested.queryParameters['end_date'], '2021-02-14');
      expect(requested.queryParameters['models'], 'era5');
      expect(
        requested.queryParameters['hourly'],
        'temperature_2m,apparent_temperature',
      );

      expect(data.series.keys, <String>[
        'temperature_2m',
        'apparent_temperature',
      ]);
      expect(data.series['temperature_2m']!.sampleCount, 2);
      expect(data.referencePeriodStart, DateTime.utc(2021, 1, 1));
      expect(data.referencePeriodEnd, DateTime.utc(2021, 2, 14));
      expect(data.source, contains('ERA5'));
    },
  );

  test('a field absent from the archive is skipped, not invented', () async {
    final client = MockClient((request) async {
      return http.Response('''
          {
            "hourly": {
              "time": ["2021-01-01T00:00"],
              "temperature_2m": [28.0]
            }
          }
          ''', 200);
    });

    final source = OpenMeteoHazardHistoricalDataSource(client: client);

    final data = await source.fetch(
      hazard: HazardType.heat,
      latitude: -4.30,
      longitude: 15.35,
      startDate: DateTime.utc(2021, 1, 1),
      endDate: DateTime.utc(2021, 1, 31),
    );

    expect(data.series.keys, <String>['temperature_2m']);
  });

  test('an inverted date range is rejected', () async {
    final source = OpenMeteoHazardHistoricalDataSource(
      client: MockClient((request) async {
        return http.Response('{}', 200);
      }),
    );

    expect(
      () => source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
        startDate: DateTime.utc(2021, 2, 14),
        endDate: DateTime.utc(2021, 1, 1),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('an API error is reported as a FormatException', () async {
    final source = OpenMeteoHazardHistoricalDataSource(
      client: MockClient((request) async {
        return http.Response('{"error": true, "reason": "No data"}', 200);
      }),
    );

    expect(
      () => source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
        startDate: DateTime.utc(2021, 1, 1),
        endDate: DateTime.utc(2021, 1, 31),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('No data'),
        ),
      ),
    );
  });

  test('a failed HTTP status becomes an HttpException', () async {
    final source = OpenMeteoHazardHistoricalDataSource(
      client: MockClient((request) async {
        return http.Response('server error', 503);
      }),
    );

    expect(
      () => source.fetch(
        hazard: HazardType.heat,
        latitude: -4.30,
        longitude: 15.35,
        startDate: DateTime.utc(2021, 1, 1),
        endDate: DateTime.utc(2021, 1, 31),
      ),
      throwsA(isA<HttpException>()),
    );
  });
}
