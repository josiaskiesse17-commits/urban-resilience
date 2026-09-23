import 'risk_factors.dart';

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

class RiskZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double riskScore;
  final String hazardType;
  final RiskLevel riskLevel;
  final RiskFactors factors;

  const RiskZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.riskScore,
    required this.hazardType,
    required this.riskLevel,
    required this.factors,
  });
}