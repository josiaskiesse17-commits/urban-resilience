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

    if (rainfall.isEmpty) {
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
      hourlyRainfallValues: rainfall,
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

  List<double> _parseRainfall(Map<String, dynamic> json) {
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

    return rain.whereType<num>().map((value) => value.toDouble()).toList();
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
