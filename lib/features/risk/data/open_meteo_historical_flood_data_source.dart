import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/historical_flood_data.dart';
import '../domain/historical_flood_data_source.dart';

class OpenMeteoHistoricalFloodDataSource implements HistoricalFloodDataSource {
  final http.Client client;

  OpenMeteoHistoricalFloodDataSource({required this.client});

  @override
  Future<HistoricalFloodData> fetch({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStart = _normalizeDate(startDate);
    final normalizedEnd = _normalizeDate(endDate);

    if (normalizedEnd.isBefore(normalizedStart)) {
      throw ArgumentError('End date cannot be before start date.');
    }

    final weatherUri = Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'start_date': _formatDate(normalizedStart),
      'end_date': _formatDate(normalizedEnd),
      'hourly': 'rain',
      'timezone': 'UTC',
      'models': 'era5',
    });

    final floodUri = Uri.https('flood-api.open-meteo.com', '/v1/flood', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'start_date': _formatDate(normalizedStart),
      'end_date': _formatDate(normalizedEnd),
      'daily': 'river_discharge',
      'timezone': 'UTC',
    });

    final responses = await Future.wait([
      client.get(weatherUri),
      client.get(floodUri),
    ]);

    final weatherResponse = responses[0];
    final floodResponse = responses[1];

    if (weatherResponse.statusCode != 200) {
      throw HttpException(
        'Historical weather request failed: '
        '${weatherResponse.statusCode}',
        uri: weatherUri,
      );
    }

    if (floodResponse.statusCode != 200) {
      throw HttpException(
        'Historical flood request failed: '
        '${floodResponse.statusCode}',
        uri: floodUri,
      );
    }

    final weatherJson = _decodeObject(weatherResponse.body);

    final floodJson = _decodeObject(floodResponse.body);

    final rainfall = _parseRainfall(weatherJson);
    final riverDischarge = _parseRiverDischarge(floodJson);

    if (rainfall.values.isEmpty) {
      throw const FormatException(
        'Historical weather API returned no rainfall values.',
      );
    }

    if (riverDischarge.isEmpty) {
      throw const FormatException(
        'Historical flood API returned no river discharge values.',
      );
    }

    return HistoricalFloodData(
      hourlyRainfallValues: rainfall.values,
      hourlyRainfallTimes: rainfall.times,
      riverDischargeValues: riverDischarge,
      referencePeriodStart: normalizedStart,
      referencePeriodEnd: normalizedEnd,
      rainfallSource: 'Open-Meteo Historical Weather API / ERA5',
      riverSource: 'Open-Meteo Global Flood API / GloFAS',
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('API response is not a JSON object.');
    }

    if (decoded['error'] == true) {
      throw FormatException(
        decoded['reason']?.toString() ?? 'Open-Meteo returned an API error.',
      );
    }

    return decoded;
  }

  /// Pairs every rainfall sample with its timestamp.
  ///
  /// Samples with a missing/non-numeric value or an unparseable timestamp are
  /// dropped (they would otherwise silently shift the six-hour windows), and
  /// the surviving samples are sorted chronologically so downstream windowing
  /// never sees an unordered series. When the response carries no timestamps
  /// at all, the raw values are returned with an empty time list.
  ({List<double> values, List<DateTime> times}) _parseRainfall(
    Map<String, dynamic> json,
  ) {
    final hourly = json['hourly'];

    if (hourly is! Map<String, dynamic>) {
      throw const FormatException(
        'Historical weather response has no hourly data.',
      );
    }

    final rain = hourly['rain'];

    if (rain is! List) {
      throw const FormatException(
        'Historical weather response has no rain array.',
      );
    }

    final rawTimes = hourly['time'];

    if (rawTimes == null) {
      return (
        values: rain.whereType<num>().map((value) => value.toDouble()).toList(),
        times: const <DateTime>[],
      );
    }

    if (rawTimes is! List) {
      throw const FormatException(
        'Historical weather response has a malformed time array.',
      );
    }

    final samples = <({DateTime time, double value})>[];
    final length =
        rain.length < rawTimes.length ? rain.length : rawTimes.length;

    for (var index = 0; index < length; index++) {
      final value = rain[index];

      if (value is! num || !value.isFinite) {
        continue;
      }

      final parsed = DateTime.tryParse('${rawTimes[index]}');

      if (parsed == null) {
        continue;
      }

      // The API answers with timezone=UTC, so naive timestamps are UTC wall
      // times; keeping them in UTC avoids machine-timezone/DST distortion.
      final time = parsed.isUtc
          ? parsed
          : DateTime.utc(
              parsed.year,
              parsed.month,
              parsed.day,
              parsed.hour,
              parsed.minute,
            );

      samples.add((time: time, value: value.toDouble()));
    }

    samples.sort((left, right) => left.time.compareTo(right.time));

    return (
      values: [for (final sample in samples) sample.value],
      times: [for (final sample in samples) sample.time],
    );
  }

  List<double> _parseRiverDischarge(Map<String, dynamic> json) {
    final daily = json['daily'];

    if (daily is! Map<String, dynamic>) {
      throw const FormatException(
        'Historical flood response has no daily data.',
      );
    }

    final discharge = daily['river_discharge'];

    if (discharge is! List) {
      throw const FormatException(
        'Historical flood response has no river discharge array.',
      );
    }

    return discharge.whereType<num>().map((value) => value.toDouble()).toList();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
