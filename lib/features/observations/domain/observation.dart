enum ObservationType {
  flooding,
  blockedRoad,
  landslide,
  other,
}

class Observation {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final ObservationType type;
  final String? imageUrl;
  final String? description;
  final DateTime createdAt;

  const Observation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.imageUrl,
    this.description,
    required this.createdAt,
  });
}