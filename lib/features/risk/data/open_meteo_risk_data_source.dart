import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/flood_environmental_data.dart';
import '../domain/flood_environmental_data_source.dart';
import '../domain/hazard_series_utils.dart';

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

    final river = _parseLatestRiverDischarge(floodJson);

    final today = DateTime.now().toUtc();

    final notes = <String>[...rainfall.notes];

    if (river.date.year != today.year ||
        river.date.month != today.month ||
        river.date.day != today.day) {
      notes.add(
        'The daily GloFAS river discharge available for this location is '
        'dated ${_formatDate(river.date)}; no value for today was returned.',
      );
    }

    return FloodEnvironmentalData(
      rainfallLastHourMm: rainfall.lastHourMm,
      rainfallAccumulation6hMm:
          rainfall.accumulationMm,
      riverDischargeM3s: river.value,
      observedAt: rainfall.observedAt,
      rainfallSource: 'Open-Meteo Weather API',
      riverSource:
          'Open-Meteo Global Flood API / GloFAS',
      rainfallObservedAt: rainfall.observedAt,
      riverObservedAt: river.date,
      rainfallAccumulationWindowHours:
          rainfall.windowHours,
      dataNotes: notes,
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

  ({
    double lastHourMm,
    double accumulationMm,
    int windowHours,
    DateTime observedAt,
    List<String> notes,
  })
      _parseRainfall(
    Map<String, dynamic> json,
  ) {
    final hourly = json['hourly'];

    if (hourly is! Map<String, dynamic>) {
      throw const FormatException(
        'Weather API did not return hourly data.',
      );
    }

    final rain = hourly['rain'];
    final times = hourly['time'];

    if (rain is! List || times is! List) {
      throw const FormatException(
        'Weather API did not return rain data.',
      );
    }

    // The provider timestamps are kept: a missing hour must not shift the
    // following hours of the accumulation window.
    final samples = HazardSeriesUtils.align(
      times: times,
      values: rain,
    );

    if (samples.isEmpty) {
      throw const FormatException(
        'No rainfall values returned.',
      );
    }

    final last = samples.last;

    final notes = <String>[];

    // Largest contiguous run of hourly samples ending at the last sample.
    var windowHours = 1;

    for (var index = samples.length - 1; index > 0; index--) {
      final gap = samples[index].time.difference(
        samples[index - 1].time,
      );

      if (gap != const Duration(hours: 1)) {
        break;
      }

      windowHours++;
    }

    if (windowHours > 6) {
      windowHours = 6;
    }

    final accumulation = HazardSeriesUtils.trailingSums(
      hourly: samples,
      window: windowHours,
    );

    if (windowHours < 6) {
      notes.add(
        'The hourly rainfall series of this location is not contiguous: '
        'the accumulation covers the last $windowHours hour(s) ending at '
        '${last.time.toIso8601String()} instead of the nominal 6 hours.',
      );
    }

    return (
      lastHourMm: last.value,
      accumulationMm: accumulation.isEmpty
          ? last.value
          : accumulation.last.value,
      windowHours: windowHours,
      observedAt: last.time,
      notes: notes,
    );
  }

  ({DateTime date, double value})
      _parseLatestRiverDischarge(
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

    values.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    final today = DateTime.now().toUtc();

    // Newest day that is not in the future: a future day must not be
    // presented as the current state of the river.
    ({DateTime date, double value})? latest;

    for (final item in values) {
      if (item.date.isAfter(today)) {
        continue;
      }

      if (latest == null ||
          item.date.isAfter(latest.date)) {
        latest = item;
      }
    }

    return latest ?? values.first;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(
      2,
      '0',
    );
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}