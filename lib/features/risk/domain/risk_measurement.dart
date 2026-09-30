enum RiskReferenceType {
  localBaseline,
  historicalAverage,
  historicalMedian,
  guideline,
  threshold,
  forecastBaseline,
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
      'source': source,
      'observedAt': observedAt?.toIso8601String(),
    };
  }
}