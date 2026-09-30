class SelectedPlace {
  final String label;
  final double latitude;
  final double longitude;
  final bool fromGps;

  const SelectedPlace({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.fromGps,
  });

  Map<String, Object> toJson() {
    return {
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'fromGps': fromGps,
    };
  }

  factory SelectedPlace.fromJson(Map<String, Object?> json) {
    return SelectedPlace(
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      fromGps: json['fromGps'] as bool? ?? false,
    );
  }
}
