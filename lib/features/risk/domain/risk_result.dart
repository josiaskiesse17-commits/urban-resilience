import 'risk_evidence.dart';
import 'risk_factors.dart';
import 'risk_zone.dart';

class RiskResult {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final String hazardType;
  final double riskScore;
  final RiskLevel riskLevel;
  final RiskFactors factors;
  final RiskEvidence evidence;
  final DateTime updatedAt;

  const RiskResult({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.hazardType,
    required this.riskScore,
    required this.riskLevel,
    required this.factors,
    required this.evidence,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'hazardType': hazardType,
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'factors': factors.toJson(),
      'evidence': evidence.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}