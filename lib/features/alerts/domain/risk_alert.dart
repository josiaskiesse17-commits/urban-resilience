enum AlertSeverity {
  info,
  warning,
  danger,
  critical,
}

class RiskAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  const RiskAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });
}