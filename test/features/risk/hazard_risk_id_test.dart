import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/hazard_risk_id.dart';
import 'package:urban_resilience/features/risk/domain/hazard_type.dart';

void main() {
  test(
    'flooding keeps the bare zone id for backward compatibility',
    () {
      expect(
        HazardRiskId.forZone(
          zoneId: 'zone-masina',
          hazard: HazardType.flooding,
        ),
        'zone-masina',
      );
    },
  );

  test('other hazards get a hazard suffix', () {
    expect(
      HazardRiskId.forZone(
        zoneId: 'zone-masina',
        hazard: HazardType.heat,
      ),
      'zone-masina--heat',
    );
    expect(
      HazardRiskId.forZone(
        zoneId: 'zone-ndjili',
        hazard: HazardType.wildfire,
      ),
      'zone-ndjili--wildfire',
    );
  });

  test('hazardOf and zoneIdOf round trip', () {
    for (final hazard in HazardType.values) {
      final id = HazardRiskId.forZone(
        zoneId: 'zone-gombe',
        hazard: hazard,
      );

      expect(HazardRiskId.hazardOf(id), hazard);
      expect(HazardRiskId.zoneIdOf(id), 'zone-gombe');
    }
  });

  test(
    'ids without a known hazard suffix resolve to flooding',
    () {
      expect(
        HazardRiskId.hazardOf('zone-limete'),
        HazardType.flooding,
      );
      expect(
        HazardRiskId.zoneIdOf('zone-limete'),
        'zone-limete',
      );

      // A document written before the multi-hazard work keeps resolving.
      expect(
        HazardRiskId.zoneIdOf('zone-masina--unknown'),
        'zone-masina--unknown',
      );
      expect(
        HazardRiskId.hazardOf('zone-masina--unknown'),
        HazardType.flooding,
      );
    },
  );
}