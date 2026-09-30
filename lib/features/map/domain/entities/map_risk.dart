import 'package:latlong2/latlong.dart';

enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

enum RiskType {
  flood,
  fire,
  accident,
  crime,
  building,
  pollution,
  other,
}

class MapRisk {
  final String id;
  final String title;
  final String description;
  final LatLng position;
  final RiskLevel level;
  final RiskType type;
  final String? address;
  final DateTime? reportedAt;

  const MapRisk({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.level,
    required this.type,
    this.address,
    this.reportedAt,
  });
}