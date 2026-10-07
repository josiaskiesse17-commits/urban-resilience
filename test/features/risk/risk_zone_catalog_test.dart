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

  test('uses the administrative centers of the configured Kinshasa zones', () {
    expect(RiskZoneCatalog.byId('zone-masina'), (
      id: 'zone-masina',
      name: 'Masina',
      latitude: -4.3661666,
      longitude: 15.3909815,
    ));
    expect(RiskZoneCatalog.byId('zone-ndjili'), (
      id: 'zone-ndjili',
      name: "N'Djili",
      latitude: -4.4069558,
      longitude: 15.3754638,
    ));
    expect(RiskZoneCatalog.byId('zone-limete'), (
      id: 'zone-limete',
      name: 'Limete',
      latitude: -4.3543467,
      longitude: 15.3466854,
    ));
    expect(RiskZoneCatalog.byId('zone-gombe'), (
      id: 'zone-gombe',
      name: 'Gombe',
      latitude: -4.3119751,
      longitude: 15.2894296,
    ));
    expect(RiskZoneCatalog.byId('zone-kasa-vubu'), (
      id: 'zone-kasa-vubu',
      name: 'Kasa-Vubu',
      latitude: -4.3417150,
      longitude: 15.3040174,
    ));
    expect(RiskZoneCatalog.byId('zone-kalamu'), (
      id: 'zone-kalamu',
      name: 'Kalamu',
      latitude: -4.3495584,
      longitude: 15.3179297,
    ));
    expect(RiskZoneCatalog.byId('zone-bumbu'), (
      id: 'zone-bumbu',
      name: 'Bumbu',
      latitude: -4.3725905,
      longitude: 15.2934444,
    ));
    expect(RiskZoneCatalog.byId('zone-lingwala'), (
      id: 'zone-lingwala',
      name: 'Lingwala',
      latitude: -4.3252537,
      longitude: 15.3012644,
    ));
    expect(RiskZoneCatalog.byId('zone-barumbu'), (
      id: 'zone-barumbu',
      name: 'Barumbu',
      latitude: -4.3190075,
      longitude: 15.3256934,
    ));
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
