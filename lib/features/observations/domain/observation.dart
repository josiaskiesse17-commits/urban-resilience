enum ObservationType {
  flooding,
  blockedRoad,
  landslide,
  other,
  custom,
}

enum ObservationStatus {
  pending,
  verified,
  rejected,
}

enum ObservationMediaType {
  image,
  video,
}

class Observation {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final ObservationType type;
  final String? mediaUrl;
  final ObservationMediaType? mediaType;
  final String? description;
  final String? customTypeLabel;
  final ObservationStatus status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  const Observation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.mediaUrl,
    this.mediaType,
    this.description,
    this.customTypeLabel,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  factory Observation.fromMap(String id, Map<String, dynamic> map) {
    return Observation(
      id: id,
      userId: map['userId'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      type: ObservationType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ObservationType.other,
      ),
      mediaUrl: map['mediaUrl'] as String?,
      mediaType: _mediaTypeFromValue(map['mediaType']),
      description: map['description'] as String?,
      customTypeLabel: map['customTypeLabel'] as String?,
      status: ObservationStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => ObservationStatus.pending,
      ),
      createdAt: _dateFromValue(map['createdAt']) ?? DateTime.now(),
      verifiedAt: _dateFromValue(map['verifiedAt']),
      verifiedBy: map['verifiedBy'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  static ObservationMediaType? _mediaTypeFromValue(dynamic value) {
    if (value == null) return null;
    return ObservationMediaType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ObservationMediaType.image,
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return value.toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  String get typeLabel {
    if (type == ObservationType.custom &&
        customTypeLabel != null &&
        customTypeLabel!.trim().isNotEmpty) {
      return customTypeLabel!.trim();
    }

    switch (type) {
      case ObservationType.flooding:
        return 'Inondation';
      case ObservationType.blockedRoad:
        return 'Route bloquée';
      case ObservationType.landslide:
        return 'Glissement de terrain';
      case ObservationType.other:
        return 'Autre';
      case ObservationType.custom:
        return 'Autre';
    }
  }

  String get statusLabel {
    switch (status) {
      case ObservationStatus.pending:
        return 'En attente';
      case ObservationStatus.verified:
        return 'Validée';
      case ObservationStatus.rejected:
        return 'Rejetée';
    }
  }
}
