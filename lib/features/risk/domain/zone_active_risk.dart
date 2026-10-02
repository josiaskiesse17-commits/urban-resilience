import 'hazard_risk_id.dart';
import 'hazard_type.dart';
import 'risk_result.dart';
import 'risk_zone.dart';

/// Central definition of what currently counts as an identified risk.
///
/// This is intentionally the single place holding the current product rule
/// (`riskScore > 0`) so the threshold can later be replaced by a
/// scientifically justified value without touching the map, the Active Risks
/// selection UI or any screen.
bool isIdentifiedRisk(RiskResult result) => result.riskScore > 0;

/// Minimal, presentation-safe view of one identified risk of a zone.
///
/// The map and the Zone Active Risks selection UI consume only this
/// abstraction: they never see rainfall series, discharge, historical
/// baselines, exposure calculations, AI or Firestore internals. Every field
/// is derived from an already calculated, stored [RiskResult].
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

  /// Builds the [ZoneActiveRisk] of a stored result.
  ///
  /// Returns null when the result does not satisfy [isIdentifiedRisk], so
  /// callers never have to repeat the threshold rule themselves.
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

/// What a zone has stored for one hazard.
///
/// The map and the Zone Active Risks selection UI must distinguish the three
/// real states of a hazard instead of collapsing them into a number:
/// * [identified] - a stored assessment whose score is a current risk;
/// * [notIdentified] - a stored assessment that is not a current risk;
/// * [notAssessed] - nothing is stored yet, so nothing is known about it.
enum ZoneHazardStatus {
  identified,
  notIdentified,
  notAssessed,
}

/// Presentation-safe state of one hazard of a zone.
///
/// The risk id is always derivable ([HazardRiskId.forZone]), so the selection
/// UI can open the Risk Details screen of a hazard even when nothing is stored
/// yet: the details screen is the only place that generates or refreshes an
/// assessment. Every value here comes from an already stored [RiskResult].
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

  /// Builds the state of one hazard from its stored result, applying the
  /// single [isIdentifiedRisk] rule.
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

/// States of every hazard of a zone, identified risks first (most severe
/// score first), then the hazards that carry no current risk so the selection
/// UI can still offer them.
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

/// Keeps only the identified assessments as active risks, in the order they
/// were given (identified risks, most severe first).
List<ZoneActiveRisk> identifiedRisksOf(
  Iterable<ZoneHazardAssessment> assessments,
) {
  return <ZoneActiveRisk>[
    for (final assessment in assessments)
      if (assessment.activeRisk != null) assessment.activeRisk!,
  ];
}

/// Highest identified risk level of a zone, or null when the zone has no
/// identified risk. Used for the map marker colour.
RiskLevel? highestIdentifiedLevel(Iterable<ZoneActiveRisk> risks) {
  RiskLevel? highest;

  for (final risk in risks) {
    if (highest == null || risk.riskLevel.index > highest.index) {
      highest = risk.riskLevel;
    }
  }

  return highest;
}
