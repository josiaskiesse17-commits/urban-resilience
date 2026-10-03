import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/hazard_catalog.dart';
import '../domain/hazard_environmental_data.dart';
import '../domain/hazard_environmental_data_source.dart';
import '../domain/hazard_type.dart';
import 'open_meteo_hourly_parser.dart';










class OpenMeteoHazardDataSource
    implements HazardEnvironmentalDataSource {
  OpenMeteoHazardDataSource({
    required this.client,
  });

  final http.Client client;

  static const String sourceLabel = 'Open-Meteo Weather API';

  @override
  Future<HazardLiveData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
  }) async {
    final definition = HazardCatalog.of(hazard);

    final fields = definition.liveApiFields;

    if (fields.isEmpty) {
      throw ArgumentError(
        '${hazard.label} is not served by the live hazard '
        'source.',
      );
    }

    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'hourly': fields.join(','),
        'past_days': definition.liveLookbackDays.toString(),
        'forecast_days': '0',
        'timezone': 'UTC',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
      },
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw HttpException(
        'Hazard weather API failed: '
        '${response.statusCode}',
        uri: uri,
      );
    }

    final json =
        OpenMeteoHourlyParser.decodeObject(response.body);

    final times = OpenMeteoHourlyParser.parseTimes(json);

    final series = <String, HazardSeries>{};
    final missing = <String, String>{};
    final notes = <String>[];

    for (final field in fields) {
      final parsed = OpenMeteoHourlyParser.seriesFor(
        json: json,
        times: times,
        field: field,
        source: sourceLabel,
      );

      if (parsed == null) {
        missing[field] =
            'the live provider does not return `$field` at this location';

        continue;
      }

      if (parsed.isEmpty) {
        missing[field] =
            'the live provider returned only missing values for `$field` '
            'at this location';

        continue;
      }

      series[field] = parsed;
    }

    DateTime? newest;

    for (final item in series.values) {
      final last = item.lastObservedAt;

      if (last == null) {
        continue;
      }

      if (newest == null || last.isAfter(newest)) {
        newest = last;
      }
    }

    if (missing.isNotEmpty) {
      notes.add(
        'Live data missing for this request: '
        '${missing.keys.join(', ')}.',
      );
    }

    return HazardLiveData(
      hazard: hazard,
      series: series,
      observedAt: newest ?? DateTime.now().toUtc(),
      sources: const <String>[sourceLabel],
      missingFields: missing,
      providerNotes: notes,
    );
  }
}
