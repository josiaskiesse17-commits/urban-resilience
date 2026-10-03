import 'package:urban_resilience/features/risk/domain/risk_evidence.dart';
import 'package:urban_resilience/features/risk/domain/risk_factors.dart';
import 'package:urban_resilience/features/risk/domain/risk_measurement.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';



RiskResult buildRiskResult({
  String id = 'zone-masina',
  String locationName = 'Masina',
  String hazardType = 'Flood',
  double riskScore = 62,
  RiskLevel riskLevel = RiskLevel.high,
  String primaryFactorLabel = 'Rainfall',
  DateTime? updatedAt,
  DateTime? collectedAt,
  List<String> qualitativeIndicators = const <String>[],
}) {
  final timestamp = DateTime.now().toUtc();

  return RiskResult(
    id: id,
    locationName: locationName,
    latitude: -4.30,
    longitude: 15.35,
    hazardType: hazardType,
    riskScore: riskScore,
    riskLevel: riskLevel,
    factors: RiskFactors(
      rainfall: 55,
      geographicVulnerability: 40,
      historicalExposure: 35,
      currentObservations: 0,
      primaryFactorLabel: primaryFactorLabel,
    ),
    evidence: RiskEvidence(
      measurements: const <RiskMeasurement>[
        RiskMeasurement(
          name: 'rainfallIntensity',
          value: 12.5,
          unit: 'mm/h',
          referenceValue: 4,
          referenceUnit: 'mm/h',
          referenceLabel: 'Local rainfall baseline',
          source: 'Open-Meteo',
        ),
        RiskMeasurement(
          name: 'riverDischarge',
          value: 240,
          unit: 'm³/s',
          referenceValue: 160,
          referenceUnit: 'm³/s',
          source: 'Open-Meteo',
        ),
      ],
      qualitativeIndicators: qualitativeIndicators,
      observationCount: 3,
      confirmedObservationCount: 1,
      collectedAt: collectedAt ?? timestamp,
    ),
    updatedAt: updatedAt ?? timestamp,
  );
}
