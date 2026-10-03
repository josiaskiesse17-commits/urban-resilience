import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_type.dart';
import 'package:urban_resilience/features/risk/domain/risk_result.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/domain/zone_active_risk.dart';

import 'risk_result_test_support.dart';

void main() {
  group('isIdentifiedRisk', () {
    test('only a positive stored score is an identified risk', () {
      expect(isIdentifiedRisk(buildRiskResult(riskScore: 0)), isFalse);
      expect(isIdentifiedRisk(buildRiskResult(riskScore: 0.4)), isTrue);
      expect(isIdentifiedRisk(buildRiskResult(riskScore: 62)), isTrue);
    });
  });

  group('zoneHazardAssessmentsFrom', () {
    test('separates identified risks and stored zeroes', () {
      final assessments = zoneHazardAssessmentsFrom('zone-masina', {
        HazardType.flooding: buildRiskResult(riskScore: 62),
        HazardType.heat: buildRiskResult(
          id: 'zone-masina--heat',
          hazardType: 'Heat',
          riskScore: 71,
          riskLevel: RiskLevel.critical,
        ),
        HazardType.landslide: buildRiskResult(
          id: 'zone-masina--landslide',
          hazardType: 'Landslide',
          riskScore: 0,
          riskLevel: RiskLevel.low,
        ),
      });

      expect(assessments, hasLength(HazardType.values.length));

      
      expect(assessments[0].hazard, HazardType.heat);
      expect(assessments[0].status, ZoneHazardStatus.identified);
      expect(assessments[0].riskId, 'zone-masina--heat');
      expect(assessments[0].riskScore, 71);
      expect(assessments[1].hazard, HazardType.flooding);
      expect(assessments[1].riskId, 'zone-masina');

      
      final landslide = assessments.singleWhere(
        (assessment) => assessment.hazard == HazardType.landslide,
      );
      expect(landslide.status, ZoneHazardStatus.notIdentified);
      expect(landslide.isIdentified, isFalse);
      expect(landslide.riskScore, isNull);
    });

    test('keeps every hazard of the zone reachable', () {
      final assessments = zoneHazardAssessmentsFrom(
        'zone-limete',
        const <HazardType, RiskResult?>{},
      );

      expect(
        assessments.map((assessment) => assessment.hazard),
        HazardType.values,
      );
      expect(
        assessments.every(
          (assessment) => assessment.status == ZoneHazardStatus.notAssessed,
        ),
        isTrue,
      );
      expect(assessments.first.riskId, 'zone-limete');
    });
  });

  group('identifiedRisksOf', () {
    test('keeps the identified risks and their severity order', () {
      final assessments = zoneHazardAssessmentsFrom('zone-masina', {
        HazardType.flooding: buildRiskResult(
          riskScore: 20,
          riskLevel: RiskLevel.low,
        ),
        HazardType.landslide: buildRiskResult(
          id: 'zone-masina--landslide',
          hazardType: 'Landslide',
          riskScore: 88,
          riskLevel: RiskLevel.critical,
        ),
      });

      final risks = identifiedRisksOf(assessments);

      expect(risks.map((risk) => risk.hazardType), <HazardType>[
        HazardType.landslide,
        HazardType.flooding,
      ]);
      expect(risks.map((risk) => risk.hazardLabel), <String>[
        'Landslide',
        'Flood',
      ]);
      expect(risks.map((risk) => risk.zoneId), <String>[
        'zone-masina',
        'zone-masina',
      ]);
      expect(highestIdentifiedLevel(risks), RiskLevel.critical);
      expect(highestIdentifiedLevel(const <ZoneActiveRisk>[]), isNull);
    });
  });
}
