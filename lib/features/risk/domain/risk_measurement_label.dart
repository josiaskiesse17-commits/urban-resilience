/// Human readable wording of a measurement identifier.
///
/// The screens must never show an internal field name such as
/// `rainfallAccumulation6h` or `riverDischargeM3s` to a citizen, but the
/// stored documents keep those names. This helper is the single translation
/// point, so the Risk Factors row, the Evidence row and the What-If control of
/// the same variable are worded identically:
///
/// * a known identifier is translated with the wording of its hazard model;
/// * a trailing window (`6h`, `24h`, `14d`, `30d`, ...) becomes a period
///   ("- 30 days"), taken from the identifier or from [measurementPeriod];
/// * a unit embedded in the identifier (`MmPerHour`, `M3s`, ...) is spelled
///   out as a unit;
/// * anything else falls back to a camel-case split, so a new variable is
///   readable without a mapping table.
class RiskMeasurementLabel {
  const RiskMeasurementLabel._();

  static const String _separator = ' \u2014 ';

  /// Base wording of the identifiers the application stores.
  static const Map<String, String> _known = <String, String>{
    'rainfall': 'Pluie',
    'rainfallIntensity': 'Intensité de la pluie',
    'rainfallAccumulation': 'Cumul de pluie',
    'rainfallAccumulation6h': 'Cumul de pluie',
    'rainfallAccumulation24h': 'Cumul de pluie',
    'rainfallAccumulation72h': 'Cumul de pluie',
    'soilMoisture': 'Humidité du sol',
    'soilMoisture0to7cm': 'Contenu en eau de la couche 0-7 cm',
    'temperature2mMax24h': 'Température maximale de l’air',
    'temperature2mMin24h': 'Température minimale nocturne',
    'apparentTemperatureMax24h': 'Température ressentie maximale',
    'riverDischarge': 'Débit fluvial',
    'riverDischargeM3s': 'Débit fluvial',
    'geographicVulnerability': 'Vulnérabilité géographique',
    'historicalExposure': 'Exposition historique',
    'citizenObservationRisk': 'Risque lié aux observations citoyennes',
  };

  /// Unit spellings for the identifiers that embed one.
  static const Map<String, String> _unitsInName = <String, String>{
    'MmPerHour': 'mm/h',
    'PerHour': '/heure',
    'MmPerDay': 'mm/jour',
    'M3s': 'm\u00b3/s',
    'M3S': 'm\u00b3/s',
    'Kpa': 'kPa',
    'JPerKg': 'J/kg',
    'Kmh': 'km/h',
    'Mm': 'mm',
    'Celsius': '°C',
    'Percent': '%',
  };

  static String of({
    required String name,
    String? measurementPeriod,
    String? unit,
  }) {
    if (name.isEmpty) {
      return name;
    }

    var identifier = name;
    String? unitFromName;

    for (final entry in _unitsInName.entries) {
      if (identifier.endsWith(entry.key) &&
          identifier.length > entry.key.length) {
        unitFromName = entry.value;
        identifier = identifier.substring(
          0,
          identifier.length - entry.key.length,
        );
        break;
      }
    }

    final window = _takeWindow(identifier);

    if (window != null) {
      identifier = window.remainder;
    }

    final base = _known[identifier] ??
        _known[name] ??
        _camelCaseToWords(identifier);

    final period = window?.phrase ??
        _periodPhrase(measurementPeriod);
    final scale = period == null
        ? unitFromName
        : unitFromName == null
            ? period
            : '$period ($unitFromName)';

    if (scale == null) {
      return base;
    }

    return '$base$_separator$scale';
  }

  /// Extracts a trailing window token of an identifier (`rainfall30d`).
  static ({String remainder, String phrase})? _takeWindow(String value) {
    final match = _windowPattern.firstMatch(value);

    if (match == null || match.start == 0) {
      return null;
    }

    final amount = int.tryParse(match.group(1)!);

    if (amount == null || amount <= 0) {
      return null;
    }

    final phrase = _windowPhrase(amount, match.group(2)!);

    if (phrase == null) {
      return null;
    }

    return (remainder: value.substring(0, match.start), phrase: phrase);
  }

  static final RegExp _windowPattern = RegExp(r'(\d{1,3})(h|d)$');

  /// Wording of a trailing window token (`6h`, `30d`).
  static String? _windowPhrase(int amount, String unit) {
    if (unit == 'h') {
      return amount == 1
          ? 'dernière heure'
          : 'dernières $amount heures';
    }

    if (unit == 'd') {
      return amount == 1 ? 'dernier jour' : 'derniers $amount jours';
    }

    return null;
  }

  /// Wording of the measurement period written by the sources
  /// (`instant`, `1h`, `6h`, `daily`, ...).
  static String? _periodPhrase(String? measurementPeriod) {
    if (measurementPeriod == null || measurementPeriod.isEmpty) {
      return null;
    }

    if (measurementPeriod == 'instant') {
      return null;
    }

    if (measurementPeriod == 'daily') {
      return 'moyenne journalière';
    }

    final match = _windowPattern.firstMatch(measurementPeriod);

    if (match == null) {
      return measurementPeriod;
    }

    final amount = int.tryParse(match.group(1)!);

    if (amount == null || amount <= 0) {
      return measurementPeriod;
    }

    return _windowPhrase(amount, match.group(2)!);
  }

  /// `customSensorAlpha` -> `Custom sensor alpha` (used when nothing is known).
  static String _camelCaseToWords(String name) {
    final buffer = StringBuffer();

    for (var index = 0; index < name.length; index++) {
      final char = name[index];

      if (index == 0) {
        buffer.write(char.toUpperCase());
        continue;
      }

      if (char.toUpperCase() == char && char.toLowerCase() != char) {
        buffer
          ..write(' ')
          ..write(char.toLowerCase());
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
  }
}
