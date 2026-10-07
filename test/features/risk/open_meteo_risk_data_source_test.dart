import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:urban_resilience/features/risk/data/open_meteo_risk_data_source.dart';

void main() {
  test('parses live rainfall and river discharge', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'api.open-meteo.com') {
        return http.Response('''
            {
              "hourly": {
                "time": [
                  "2026-09-28T04:00",
                  "2026-09-28T05:00",
                  "2026-09-28T06:00",
                  "2026-09-28T07:00",
                  "2026-09-28T08:00",
                  "2026-09-28T09:00"
                ],
                "rain": [
                  0.5,
                  1.0,
                  0.0,
                  2.0,
                  3.5,
                  4.0
                ]
              }
            }
            ''', 200);
      }

      if (request.url.host == 'flood-api.open-meteo.com') {
        return http.Response('''
            {
              "daily": {
                "time": [
                  "2026-09-27",
                  "2026-09-28"
                ],
                "river_discharge": [
                  320.0,
                  410.0
                ]
              }
            }
            ''', 200);
      }

      return http.Response('Not found', 404);
    });

    final source = OpenMeteoRiskDataSource(client: client);

    final result = await source.fetch(latitude: -4.30, longitude: 15.35);

    expect(result.rainfallLastHourMm, 4.0);

    expect(result.rainfallAccumulation6hMm, 11.0);

    expect(result.riverDischargeM3s, 410.0);

    expect(result.rainfallSource, 'Open-Meteo Weather API');

    expect(result.riverSource, 'Open-Meteo Global Flood API / GloFAS');
  });
}
