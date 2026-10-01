import 'dart:convert';

import '../domain/hazard_environmental_data.dart';

/// Shared parsing of Open-Meteo `hourly` payloads.
///
/// The parser keeps the provider timestamps and its null entries: a missing
/// hour must stay visible, because dropping it silently would shift every
/// following hour of a window.
class OpenMeteoHourlyParser {
  const OpenMeteoHourlyParser._();

  static Map<String, dynamic> decodeObject(String body) {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Open-Meteo response is not a JSON object.',
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

  static List<DateTime> parseTimes(
    Map<String, dynamic> json,
  ) {
    final hourly = json['hourly'];

    if (hourly is! Map<String, dynamic>) {
      throw const FormatException(
        'Open-Meteo response has no hourly block.',
      );
    }

    final times = hourly['time'];

    if (times is! List) {
      throw const FormatException(
        'Open-Meteo response has no hourly timestamps.',
      );
    }

    final parsed = <DateTime>[];

    for (final entry in times) {
      if (entry is! String) {
        throw FormatException(
          'Open-Meteo returned a non textual timestamp: $entry',
        );
      }

      final time = DateTime.tryParse(entry);

      if (time == null) {
        throw FormatException(
          'Open-Meteo returned an invalid timestamp: $entry',
        );
      }

      parsed.add(time.toUtc());
    }

    return parsed;
  }

  /// Reads one field of the `hourly` block.
  ///
  /// Returns null when the field is absent from the response.
  static HazardSeries? seriesFor({
    required Map<String, dynamic> json,
    required List<DateTime> times,
    required String field,
    required String source,
  }) {
    final hourly = json['hourly'];

    if (hourly is! Map<String, dynamic>) {
      return null;
    }

    final values = hourly[field];

    if (values is! List) {
      return null;
    }

    final units = json['hourly_units'];

    final unit = units is Map && units[field] is String
        ? units[field] as String
        : '';

    return HazardSeries(
      field: field,
      unit: unit == 'undefined' ? '' : unit,
      times: times,
      values: values
          .map((value) => value is num ? value.toDouble() : null)
          .toList(growable: false),
      source: source,
    );
  }
}
