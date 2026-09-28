import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/flood_environmental_data.dart';
import '../domain/flood_environmental_data_source.dart';

class OpenMeteoRiskDataSource
    implements FloodEnvironmentalDataSource {
  final http.Client client;

  OpenMeteoRiskDataSource({
    required this.client,
  });

  @override
  Future<FloodEnvironmentalData> fetch({
    required double latitude,
    required double longitude,
  }) async {
    final weatherUri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'hourly': 'rain',
        'past_hours': '6',
        'forecast_hours': '0',
        'timezone': 'UTC',
      },
    );

    final floodUri = Uri.https(
      'flood-api.open-meteo.com',
      '/v1/flood',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'daily': 'river_discharge',
        'past_days': '1',
        'forecast_days': '1',
        'timezone': 'UTC',
        'cell_selection': 'nearest',
      },
    );

    final responses = await Future.wait([
      client.get(weatherUri),
      client.get(floodUri),
    ]);

    final weatherResponse = responses[0];
    final floodResponse = responses[1];

    if (weatherResponse.statusCode != 200) {
      throw HttpException(
        'Weather API failed: '
        '${weatherResponse.statusCode}',
        uri: weatherUri,
      );
    }

    if (floodResponse.statusCode != 200) {
      throw HttpException(
        'Flood API failed: '
        '${floodResponse.statusCode}',
        uri: floodUri,
      );
    }

    final weatherJson = _decodeObject(
      weatherResponse.body,
    );

    final floodJson = _decodeObject(
      floodResponse.body,
    );

    final rainfall = _parseRainfall(weatherJson);

    final riverDischarge =
        _parseLatestRiverDischarge(floodJson);

    return FloodEnvironmentalData(
      rainfallLastHourMm: rainfall.lastHourMm,
      rainfallAccumulation6hMm:
          rainfall.accumulation6hMm,
      riverDischargeM3s: riverDischarge,
      observedAt: DateTime.now().toUtc(),
      rainfallSource: 'Open-Meteo Weather API',
      riverSource:
          'Open-Meteo Global Flood API / GloFAS',
    );
  }

  Map<String, dynamic> _decodeObject(
    String body,
  ) {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'API response is not a JSON object.',
      );
    }

    if (decoded['error'] == true) {
      throw FormatException(
        decoded['reason']?.toString() ??
            'Open-Meteo returned an API error.',
      );
    }

    return decoded;
  }

  _RainfallValues _parseRainfall(
    Map<String, dynamic> json,
  ) {
    final hourly = json['hourly'];

    if (hourly is! Map<String, dynamic>) {
      throw const FormatException(
        'Weather API did not return hourly data.',
      );
    }

    final rain = hourly['rain'];

    if (rain is! List) {
      throw const FormatException(
        'Weather API did not return rain data.',
      );
    }

    final values = rain
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();

    if (values.isEmpty) {
      throw const FormatException(
        'No rainfall values returned.',
      );
    }

    final lastSixHours = values.length >= 6
        ? values.sublist(values.length - 6)
        : values;

    final sixHourTotal = lastSixHours.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return _RainfallValues(
      lastHourMm: values.last,
      accumulation6hMm: sixHourTotal,
    );
  }

  double _parseLatestRiverDischarge(
    Map<String, dynamic> json,
  ) {
    final daily = json['daily'];

    if (daily is! Map<String, dynamic>) {
      throw const FormatException(
        'Flood API did not return daily data.',
      );
    }

    final times = daily['time'];
    final discharge = daily['river_discharge'];

    if (times is! List || discharge is! List) {
      throw const FormatException(
        'Flood API did not return valid daily river data.',
      );
    }

    final values =
        <({DateTime date, double value})>[];

    final length =
        times.length < discharge.length
            ? times.length
            : discharge.length;

    for (var i = 0; i < length; i++) {
      final time = times[i];
      final value = discharge[i];

      if (time is String && value is num) {
        final date = DateTime.tryParse(time);

        if (date != null) {
          values.add(
            (
              date: date.toUtc(),
              value: value.toDouble(),
            ),
          );
        }
      }
    }

    if (values.isEmpty) {
      throw const FormatException(
        'No valid river discharge values returned.',
      );
    }

    final today = DateTime.now().toUtc();

    for (final item in values) {
      if (item.date.year == today.year &&
          item.date.month == today.month &&
          item.date.day == today.day) {
        return item.value;
      }
    }

    final pastValues = values
        .where(
          (item) => !item.date.isAfter(today),
        )
        .toList();

    if (pastValues.isNotEmpty) {
      return pastValues.last.value;
    }

    return values.first.value;
  }
}

class _RainfallValues {
  final double lastHourMm;
  final double accumulation6hMm;

  const _RainfallValues({
    required this.lastHourMm,
    required this.accumulation6hMm,
  });
}