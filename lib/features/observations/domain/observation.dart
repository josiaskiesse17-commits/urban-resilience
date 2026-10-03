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
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

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
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
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
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: _requiredString(json['id'], 'id'),
      userId: _requiredString(json['userId'], 'userId'),
      zoneId: _optionalString(json['zoneId']),
      hazardType: _optionalString(json['hazardType']),
      latitude: _number(json['latitude'], 'latitude'),
      longitude: _number(json['longitude'], 'longitude'),
      type: _observationType(json['type']),
      status: _observationStatus(json['status']),
      imageUrl: _optionalString(json['imageUrl']),
      description: _optionalString(json['description']),
      createdAt:
          _parseDateTime(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      reviewedAt: _parseDateTime(json['reviewedAt']),
      reviewedBy: _optionalString(json['reviewedBy']),
      rejectionReason: _optionalString(json['rejectionReason']),
    );
  }

  static String _requiredString(Object? value, String fieldName) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException(
      'Champ "$fieldName" manquant ou invalide dans une observation.',
    );
  }

  static String? _optionalString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }

  static double _number(Object? value, String fieldName) {
    if (value is num) {
      return value.toDouble();
    }

    throw FormatException(
      'Champ "$fieldName" manquant ou invalide dans une observation.',
    );
  }

  static ObservationType _observationType(Object? value) {
    if (value is String) {
      return ObservationType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => ObservationType.other,
      );
    }
    return ObservationType.other;
  }

  static ObservationStatus _observationStatus(Object? value) {
    if (value is String) {
      return ObservationStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => ObservationStatus.pending,
      );
    }

    return ObservationStatus.pending;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is Map && value['seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
        isUtc: true,
      );
    }

    return null;
  }
}
