import 'risk_measurement.dart';

class RiskEvidence {
  final List<RiskMeasurement> measurements;
  final List<String> qualitativeIndicators;
  final int observationCount;
  final int confirmedObservationCount;
  final DateTime collectedAt;

  const RiskEvidence({
    required this.measurements,
    required this.qualitativeIndicators,
    required this.observationCount,
    required this.confirmedObservationCount,
    required this.collectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'measurements': measurements
          .map((measurement) => measurement.toJson())
          .toList(),
      'qualitativeIndicators': qualitativeIndicators,
      'observationCount': observationCount,
      'confirmedObservationCount': confirmedObservationCount,
      'collectedAt': collectedAt.toIso8601String(),
    };
  }
}