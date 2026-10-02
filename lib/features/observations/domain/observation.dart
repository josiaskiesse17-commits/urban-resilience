enum ObservationType { flooding, blockedRoad, landslide, other }

enum ObservationStatus { pending, confirmed, rejected }

class Observation {
  final String id;
  final String userId;
  final String? zoneId;
  final String? hazardType;
  final double latitude;
  final double longitude;
  final ObservationType type;
  final ObservationStatus status;
  final String? imageUrl;
  final String? description;
  final DateTime createdAt;

  const Observation({
    required this.id,
    required this.userId,
    this.zoneId,
    this.hazardType,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.status = ObservationStatus.pending,
    this.imageUrl,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'zoneId': zoneId,
      'hazardType': hazardType,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.name,
      'status': status.name,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      zoneId: json['zoneId'] as String?,
      hazardType: json['hazardType'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: ObservationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ObservationType.other,
      ),
      status: ObservationStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ObservationStatus.pending,
      ),
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      createdAt: _parseCreatedAt(json['createdAt']),
    );
  }

  static DateTime _parseCreatedAt(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is Map && value['seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
        isUtc: true,
      );
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
