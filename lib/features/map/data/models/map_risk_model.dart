import 'package:latlong2/latlong.dart';

import '../../domain/entities/map_risk.dart';

class MapRiskModel extends MapRisk {
  const MapRiskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.position,
    required super.level,
    required super.type,
    super.address,
    super.reportedAt,
  });

  factory MapRiskModel.fromJson(Map<String, dynamic> json) {
    return MapRiskModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Risque',
      description: json['description'] as String? ?? '',
      position: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      level: _parseLevel(json['level']),
      type: _parseType(json['type']),
      address: json['address'] as String?,
      reportedAt: json['reported_at'] != null
          ? DateTime.tryParse(json['reported_at'].toString())
          : null,
    );
  }

  static RiskLevel _parseLevel(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'high':
        return RiskLevel.high;
      case 'critical':
        return RiskLevel.critical;
      default:
        return RiskLevel.medium;
    }
  }

  static RiskType _parseType(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'flood':
        return RiskType.flood;
      case 'fire':
        return RiskType.fire;
      case 'accident':
        return RiskType.accident;
      case 'crime':
        return RiskType.crime;
      case 'building':
        return RiskType.building;
      case 'pollution':
        return RiskType.pollution;
      default:
        return RiskType.other;
    }
  }
}