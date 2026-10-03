



typedef RiskZoneTarget = ({
  String id,
  String name,
  double latitude,
  double longitude,
});











class RiskZoneCatalog {
  const RiskZoneCatalog._();

  static const List<RiskZoneTarget> zones = <RiskZoneTarget>[
    (id: 'zone-masina', name: 'Masina', latitude: -4.30, longitude: 15.35),
    (id: 'zone-ndjili', name: "N'Djili", latitude: -4.36, longitude: 15.34),
    (id: 'zone-limete', name: 'Limete', latitude: -4.34, longitude: 15.32),
    (id: 'zone-gombe', name: 'Gombe', latitude: -4.31, longitude: 15.29),
    (
      id: 'zone-kasa-vubu',
      name: 'Kasa-Vubu',
      latitude: -4.31,
      longitude: 15.28,
    ),
    (id: 'zone-kalamu', name: 'Kalamu', latitude: -4.34, longitude: 15.24),
    (id: 'zone-bumbu', name: 'Bumbu', latitude: -4.36, longitude: 15.27),
    (id: 'zone-lingwala', name: 'Lingwala', latitude: -4.33, longitude: 15.29),
    (id: 'zone-barumbu', name: 'Barumbu', latitude: -4.32, longitude: 15.31),
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
