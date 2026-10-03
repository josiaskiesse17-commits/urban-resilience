import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/hazard_catalog.dart';
import '../domain/hazard_environmental_data.dart';
import '../domain/hazard_historical_data.dart';
import '../domain/hazard_historical_data_source.dart';
import '../domain/hazard_type.dart';
import 'open_meteo_hourly_parser.dart';







class OpenMeteoHazardHistoricalDataSource
    implements HazardHistoricalDataSource {
  OpenMeteoHazardHistoricalDataSource({
    required this.client,
  });

  final http.Client client;

  static const String sourceLabel =
      'Open-Meteo Historical Weather API / ERA5';

  @override
  Future<HazardHistoricalData> fetch({
    required HazardType hazard,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError(
        'End date cannot be before start date.',
      );
    }

    final definition = HazardCatalog.of(hazard);

    final fields = definition.historicalApiFields;

    if (fields.isEmpty) {
      throw ArgumentError(
        '${hazard.label} declares no historical field.',
      );
    }

    final uri = Uri.https(
      'archive-api.open-meteo.com',
      '/v1/archive',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'start_date': _formatDate(normalizedStart),
        'end_date': _formatDate(normalizedEnd),
        'hourly': fields.join(','),
        'timezone': 'UTC',
        'models': 'era5',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
      },
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw HttpException(
        'Hazard archive API failed: '
        '${response.statusCode}',
        uri: uri,
      );
    }

    final json =
        OpenMeteoHourlyParser.decodeObject(response.body);

    final times = OpenMeteoHourlyParser.parseTimes(json);

    final series = <String, HazardSeries>{};

    for (final field in fields) {
      final parsed = OpenMeteoHourlyParser.seriesFor(
        json: json,
        times: times,
        field: field,
        source: sourceLabel,
      );

      if (parsed == null || parsed.isEmpty) {
        continue;
      }

      series[field] = parsed;
    }

    return HazardHistoricalData(
      hazard: hazard,
      series: series,
      referencePeriodStart: normalizedStart,
      referencePeriodEnd: normalizedEnd,
      source: sourceLabel,
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
