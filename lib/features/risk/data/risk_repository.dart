typedef RiskZoneTarget = ({
  String id,
  String name,
  double latitude,
  double longitude,
});

class RiskZoneCatalog {
  const RiskZoneCatalog._();

  static const List<RiskZoneTarget> zones = <RiskZoneTarget>[
    (
      id: 'zone-masina',
      name: 'Masina',
      latitude: -4.3661666,
      longitude: 15.3909815,
    ),
    (
      id: 'zone-ndjili',
      name: "N'Djili",
      latitude: -4.4069558,
      longitude: 15.3754638,
    ),
    (
      id: 'zone-limete',
      name: 'Limete',
      latitude: -4.3543467,
      longitude: 15.3466854,
    ),
    (
      id: 'zone-gombe',
      name: 'Gombe',
      latitude: -4.3119751,
      longitude: 15.2894296,
    ),
    (
      id: 'zone-kasa-vubu',
      name: 'Kasa-Vubu',
      latitude: -4.3417150,
      longitude: 15.3040174,
    ),
    (
      id: 'zone-kalamu',
      name: 'Kalamu',
      latitude: -4.3495584,
      longitude: 15.3179297,
    ),
    (
      id: 'zone-bumbu',
      name: 'Bumbu',
      latitude: -4.3725905,
      longitude: 15.2934444,
    ),
    (
      id: 'zone-lingwala',
      name: 'Lingwala',
      latitude: -4.3252537,
      longitude: 15.3012644,
    ),
    (
      id: 'zone-barumbu',
      name: 'Barumbu',
      latitude: -4.3190075,
      longitude: 15.3256934,
    ),
  ];

  static final DateTime historicalBaselineStart = DateTime.utc(2018, 1, 1);

  static final DateTime historicalBaselineEnd = DateTime.utc(2022, 7, 31);

  static RiskZoneTarget? byId(String id) {
    for (final zone in zones) {
      if (zone.id == id) {
        return zone;
      }
    }

    return null;
  }
}
