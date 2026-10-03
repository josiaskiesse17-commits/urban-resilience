import 'hazard_risk_id.dart';
import 'hazard_type.dart';
import 'risk_result.dart';
import 'risk_zone.dart';







bool isIdentifiedRisk(RiskResult result) => result.riskScore > 0;







class ZoneActiveRisk {
  const ZoneActiveRisk({
    required this.zoneId,
    required this.riskId,
    required this.hazardType,
    required this.hazardLabel,
    required this.riskScore,
    required this.riskLevel,
    required this.updatedAt,
  });

  final String zoneId;
  final String riskId;
  final HazardType hazardType;
  final String hazardLabel;
  final double riskScore;
  final RiskLevel riskLevel;
  final DateTime updatedAt;

  
  
  
  
  static ZoneActiveRisk? fromResult(RiskResult result) {
    if (!isIdentifiedRisk(result)) {
      return null;
    }

    return ZoneActiveRisk(
      zoneId: HazardRiskId.zoneIdOf(result.id),
      riskId: result.id,
      hazardType: HazardRiskId.hazardOf(result.id),
      hazardLabel: result.hazardType,
      riskScore: result.riskScore,
      riskLevel: result.riskLevel,
      updatedAt: result.updatedAt,
    );
  }
}








enum ZoneHazardStatus {
  identified,
  notIdentified,
  notAssessed,
}







class ZoneHazardAssessment {
  const ZoneHazardAssessment({
    required this.zoneId,
    required this.riskId,
    required this.hazard,
    required this.status,
    this.activeRisk,
  });

  final String zoneId;
  final String riskId;
  final HazardType hazard;
  final ZoneHazardStatus status;
  final ZoneActiveRisk? activeRisk;

  bool get isIdentified => status == ZoneHazardStatus.identified;

  double? get riskScore => activeRisk?.riskScore;

  RiskLevel? get riskLevel => activeRisk?.riskLevel;

  DateTime? get updatedAt => activeRisk?.updatedAt;

  
  
  factory ZoneHazardAssessment.fromResult({
    required String zoneId,
    required HazardType hazard,
    required RiskResult? result,
  }) {
    final activeRisk =
        result == null ? null : ZoneActiveRisk.fromResult(result);

    return ZoneHazardAssessment(
      zoneId: zoneId,
      riskId: HazardRiskId.forZone(
        zoneId: zoneId,
        hazard: hazard,
      ),
      hazard: hazard,
      status: activeRisk != null
          ? ZoneHazardStatus.identified
          : result == null
              ? ZoneHazardStatus.notAssessed
              : ZoneHazardStatus.notIdentified,
      activeRisk: activeRisk,
    );
  }
}




List<ZoneHazardAssessment> zoneHazardAssessmentsFrom(
  String zoneId,
  Map<HazardType, RiskResult?> results,
) {
  final identified = <ZoneHazardAssessment>[];
  final remaining = <ZoneHazardAssessment>[];

  for (final hazard in HazardType.values) {
    final assessment = ZoneHazardAssessment.fromResult(
      zoneId: zoneId,
      hazard: hazard,
      result: results[hazard],
    );

    if (assessment.isIdentified) {
      identified.add(assessment);
    } else {
      remaining.add(assessment);
    }
  }

  identified.sort(
    (a, b) => b.riskScore!.compareTo(a.riskScore!),
  );

  return <ZoneHazardAssessment>[...identified, ...remaining];
}



List<ZoneActiveRisk> identifiedRisksOf(
  Iterable<ZoneHazardAssessment> assessments,
) {
  return <ZoneActiveRisk>[
    for (final assessment in assessments)
      if (assessment.activeRisk != null) assessment.activeRisk!,
  ];
}



RiskLevel? highestIdentifiedLevel(Iterable<ZoneActiveRisk> risks) {
  RiskLevel? highest;

  for (final risk in risks) {
    if (highest == null || risk.riskLevel.index > highest.index) {
      highest = risk.riskLevel;
    }
  }

  return highest;
}
