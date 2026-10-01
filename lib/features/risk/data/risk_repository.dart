/// A location the Risk Intelligence engine can compute a flood risk for.
///
/// The citizen home screen and the admin risk screen share this catalog so
/// both surfaces always talk about the same zones.
typedef RiskZoneTarget = ({
  String id,
  String name,
  double latitude,
  double longitude,
});

/// Zones shipped with the application.
///
/// The ids follow the `zone-<name>` convention already used by the risk
/// tests (`zone-masina`) and must match the exposure documents stored in the
/// `risk_zones` Firestore collection read by the exposure repository. The
/// coordinates are the commune centres used for the Open-Meteo live and
/// historical lookups.
///
/// The same ids are used for the `risk_results` document ids, so
/// `/risk/<zoneId>` resolves the stored risk result of the zone.
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

  /// Historical reference window used to build the flood baseline.
  ///
  /// Kept in sync with the window used by the risk details screen.
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
