import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/data/risk_repository.dart';

void main() {
  test('exposes unique zones with usable coordinates', () {
    final zones = RiskZoneCatalog.zones;

    expect(zones, isNotEmpty);

    final ids = zones.map((zone) => zone.id).toSet();

    expect(ids.length, zones.length);

    for (final zone in zones) {
      expect(zone.name, isNotEmpty);
      expect(zone.latitude, inInclusiveRange(-90, 90));
      expect(zone.longitude, inInclusiveRange(-180, 180));
      expect(RiskZoneCatalog.byId(zone.id), isNotNull);
    }

    expect(RiskZoneCatalog.byId('zone-unknown'), isNull);
  });

  test('includes the full nine-zone refresh catalog for Kinshasa', () {
    final zones = RiskZoneCatalog.zones;
    final ids = zones.map((zone) => zone.id).toList();

    expect(zones.length, 9);
    expect(
      ids,
      containsAll(<String>[
        'zone-masina',
        'zone-ndjili',
        'zone-limete',
        'zone-gombe',
        'zone-kasa-vubu',
        'zone-kalamu',
        'zone-bumbu',
        'zone-lingwala',
        'zone-barumbu',
      ]),
    );
  });

  test('keeps the historical reference window before the live period', () {
    expect(
      RiskZoneCatalog.historicalBaselineStart.isBefore(
        RiskZoneCatalog.historicalBaselineEnd,
      ),
      isTrue,
    );
  });
}
