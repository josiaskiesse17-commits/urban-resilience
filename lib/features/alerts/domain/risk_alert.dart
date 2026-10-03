enum AlertSeverity {
  info,
  warning,
  danger,
  critical,
}

/// One alert published manually by an admin for a zone + hazard context.
///
/// There is no automatic alert generation: an alert exists because an admin
/// created and published it.
class RiskAlert {
  final String id;
  final String title;
  final String message;

  /// Configured zone the alert targets (`zone-masina`).
  final String zoneId;

  /// Stored hazard label of the target (`Flooding`, `Heat`, `Landslide`).
  final String hazardType;

  final AlertSeverity severity;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  /// Optional expiry: an expired alert stops being shown to users.
  final DateTime? expiresAt;

  /// Whether the alert is currently published to users.
  final bool active;

  const RiskAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.zoneId,
    required this.hazardType,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.expiresAt,
    this.active = true,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!);

  bool get isVisibleToUsers => active && !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'zoneId': zoneId,
      'hazardType': hazardType,
      'severity': severity.name,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'active': active,
    };
  }

  factory RiskAlert.fromJson(Map<String, dynamic> json) {
    return RiskAlert(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      zoneId: json['zoneId'] as String,
      hazardType: json['hazardType'] as String,
      severity: AlertSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDateTime(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt: _parseDateTime(json['expiresAt']),
      active: json['active'] != false,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is Map && value['seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
        isUtc: true,
      );
    }
    return null;
  }
}