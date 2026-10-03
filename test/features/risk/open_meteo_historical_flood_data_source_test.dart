import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:urban_resilience/features/risk/data/open_meteo_historical_flood_data_source.dart';

void main() {
  test('parses historical rainfall and river discharge', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'archive-api.open-meteo.com') {
        return http.Response(
          '''
            {
              "hourly": {
                "time": [
                  "2022-01-01T00:00",
                  "2022-01-01T01:00",
                  "2022-01-01T02:00"
                ],
                "rain": [1.0, 2.5, 4.0]
              }
            }
            ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (request.url.host == 'flood-api.open-meteo.com') {
        return http.Response(
          '''
            {
              "daily": {
                "time": [
                  "2022-01-01",
                  "2022-01-02"
                ],
                "river_discharge": [
                  100.0,
                  140.0
                ]
              }
            }
            ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('Not found', 404);
    });

    final source = OpenMeteoHistoricalFloodDataSource(client: client);

    final result = await source.fetch(
      latitude: -4.30,
      longitude: 15.35,
      startDate: DateTime.utc(2022, 1, 1),
      endDate: DateTime.utc(2022, 1, 2),
    );

    expect(result.hourlyRainfallValues, [1.0, 2.5, 4.0]);

    expect(result.riverDischargeValues, [100.0, 140.0]);

    expect(result.referencePeriodStart, DateTime.utc(2022, 1, 1));

    expect(result.referencePeriodEnd, DateTime.utc(2022, 1, 2));
  });
}
