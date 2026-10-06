import 'dart:math' as math;

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

  /// Nearest catalog zone to [latitude]/[longitude] (haversine).
  static RiskZoneTarget nearest(double latitude, double longitude) {
    RiskZoneTarget? best;
    var bestDistance = double.infinity;

    for (final zone in zones) {
      final distance = _haversineKm(
        latitude,
        longitude,
        zone.latitude,
        zone.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        best = zone;
      }
    }

    return best ?? zones.first;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
