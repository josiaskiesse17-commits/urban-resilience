import 'risk_factor_score.dart';

class RiskFactors {
  final double rainfall;
  final double? geographicVulnerability;
  final double? historicalExposure;
  final double currentObservations;

  final String primaryFactorLabel;

  final List<RiskFactorScore> entries;

  const RiskFactors({
    required this.rainfall,
    required this.geographicVulnerability,
    required this.historicalExposure,
    required this.currentObservations,
    this.primaryFactorLabel = 'Rainfall',
    this.entries = const <RiskFactorScore>[],
  });

  factory RiskFactors.fromJson(Map<String, dynamic> json) {
    double? readNullable(String key) {
      final value = json[key];

      return value is num ? value.toDouble() : null;
    }

    double readNonNullable(String key) {
      final value = json[key];

      return value is num ? value.toDouble() : 0;
    }

    final label = json['primaryFactorLabel'];
    final entries = json['entries'];

    return RiskFactors(
      rainfall: readNonNullable('rainfall'),
      geographicVulnerability: readNullable('geographicVulnerability'),
      historicalExposure: readNullable('historicalExposure'),
      currentObservations: readNonNullable('currentObservations'),
      primaryFactorLabel: label is String && label.isNotEmpty
          ? label
          : 'Rainfall',
      entries: entries is List
          ? entries
                .whereType<Map>()
                .map(
                  (entry) => RiskFactorScore.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList(growable: false)
          : const <RiskFactorScore>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rainfall': rainfall,
      'geographicVulnerability': geographicVulnerability,
      'historicalExposure': historicalExposure,
      'currentObservations': currentObservations,
      'primaryFactorLabel': primaryFactorLabel,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}
