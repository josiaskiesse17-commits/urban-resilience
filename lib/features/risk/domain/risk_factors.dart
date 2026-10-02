import 'risk_factor_score.dart';

class RiskFactors {
  final double rainfall;
  final double geographicVulnerability;
  final double historicalExposure;
  final double currentObservations;

  /// Label of the first factor. Flooding reports `Rainfall`, the other
  /// hazards report their own primary driver (`Heat`, `Rainfall (24 h)`, ...)
  /// so a heat assessment is never labelled as a rainfall factor in the UI.
  final String primaryFactorLabel;

  /// Factors the engine really examined for this assessment, in the order the
  /// Risk Factors section displays them.
  ///
  /// A factor whose data was unavailable keeps `score == null`, so the four
  /// legacy fields above can stay `0` for backwards compatibility without the
  /// UI ever presenting a missing value as a zero.
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
    double read(String key) {
      final value = json[key];

      return value is num ? value.toDouble() : 0;
    }

    final label = json['primaryFactorLabel'];
    final entries = json['entries'];

    return RiskFactors(
      rainfall: read('rainfall'),
      geographicVulnerability:
          read('geographicVulnerability'),
      historicalExposure: read('historicalExposure'),
      currentObservations: read('currentObservations'),
      primaryFactorLabel:
          label is String && label.isNotEmpty ? label : 'Rainfall',
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
      'entries': entries
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}
