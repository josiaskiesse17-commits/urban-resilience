enum RiskReferenceType {
  localBaseline,
  historicalAverage,
  historicalMedian,
  guideline,
  threshold,
  forecastBaseline,
  statisticalPercentile,
}

class RiskMeasurement {
  final String name;
  final double value;
  final String unit;

  final String? measurementPeriod;

  final double? referenceValue;
  final String? referenceUnit;
  final String? referenceLabel;
  final RiskReferenceType? referenceType;

  final double? ratioToReference;
  final double? differenceFromReference;

  final double? historicalPercentile;

  /// Outer statistical reference of the same variable: the 95th percentile of
  /// the reference period, or the 5th percentile when a low value is the risk.
  /// It bounds the score and is explicitly *not* a validated danger threshold.
  final double? statisticalCriticalValue;
  final String? statisticalCriticalLabel;

  /// True when the value is derived from measurements instead of being read
  /// directly from the provider.
  final bool isDerived;
  final String? derivationNote;

  final String? source;
  final DateTime? observedAt;

  const RiskMeasurement({
    required this.name,
    required this.value,
    required this.unit,
    this.measurementPeriod,
    this.referenceValue,
    this.referenceUnit,
    this.referenceLabel,
    this.referenceType,
    this.ratioToReference,
    this.differenceFromReference,
    this.historicalPercentile,
    this.statisticalCriticalValue,
    this.statisticalCriticalLabel,
    this.isDerived = false,
    this.derivationNote,
    this.source,
    this.observedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'measurementPeriod': measurementPeriod,
      'referenceValue': referenceValue,
      'referenceUnit': referenceUnit,
      'referenceLabel': referenceLabel,
      'referenceType': referenceType?.name,
      'ratioToReference': ratioToReference,
      'differenceFromReference': differenceFromReference,
      'historicalPercentile': historicalPercentile,
      'statisticalCriticalValue': statisticalCriticalValue,
      'statisticalCriticalLabel': statisticalCriticalLabel,
      'isDerived': isDerived,
      'derivationNote': derivationNote,
      'source': source,
      'observedAt': observedAt?.toIso8601String(),
    };
  }

  /// Human readable title of a measurement name.
  ///
  /// Known measurements are relabelled by the screens where a nicer wording
  /// exists; any other name (a hazard variable such as
  /// `temperature2mMax24h`) is split on its camel-case boundaries so a new
  /// variable stays readable without a mapping table.
  static String humanizeName(String name) {
    if (name.isEmpty) {
      return name;
    }

    final buffer = StringBuffer();

    for (var index = 0; index < name.length; index++) {
      final char = name[index];

      if (index > 0 &&
          char.toUpperCase() == char &&
          char.toLowerCase() != char) {
        buffer.write(' ');
      }

      buffer.write(char);
    }

    final text = buffer.toString();

    return text[0].toUpperCase() + text.substring(1);
  }
}