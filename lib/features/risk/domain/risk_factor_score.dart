/// One input of an assessment that the user is allowed to see.
///
/// A factor entry exists only for data the hazard model really consumed (or
/// explicitly could not consume), so the Risk Factors section can never show a
/// variable that played no role in the calculation:
///
/// * [score] and [usedInScore] carry the outcome of the engine, and
/// * [componentNames] links the factor to the evidence measurements it is
///   built from (`hazard` aggregates the hazard variables, every other factor
///   is backed by the measurement of the same [name]).
///
/// A factor whose data was unavailable keeps `score == null` together with the
/// [unavailableReason]: missing data is reported as missing, never as a zero.
class RiskFactorScore {
  const RiskFactorScore({
    required this.name,
    required this.label,
    required this.weight,
    required this.usedInScore,
    this.score,
    this.unavailableReason,
    this.componentNames = const <String>[],
  });

  /// Stable internal identifier of the factor. It is also the name of the
  /// evidence measurement the factor comes from, except for an aggregate
  /// factor, which lists its components in [componentNames].
  final String name;

  /// Human readable label shown to the user.
  final String label;

  /// Normalized score of the factor, `0`–`100`. Null when the factor could
  /// not be scored.
  final double? score;

  /// Nominal weight of the factor inside the overall score. It is `0` for a
  /// factor that was not applied.
  final double weight;

  /// True when the factor really entered the computed score.
  final bool usedInScore;

  /// Why [score] is null, in plain language.
  final String? unavailableReason;

  /// Evidence measurements this factor is derived from. Empty for a factor
  /// that is backed by a single measurement named [name].
  final List<String> componentNames;

  bool get isAvailable => score != null;

  /// Evidence measurement names that must exist for this factor.
  List<String> get evidenceNames =>
      componentNames.isEmpty ? <String>[name] : componentNames;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'score': score,
      'weight': weight,
      'usedInScore': usedInScore,
      'unavailableReason': unavailableReason,
      'componentNames': componentNames,
    };
  }

  factory RiskFactorScore.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    final reason = json['unavailableReason'];
    final components = json['componentNames'];
    final weight = json['weight'];

    return RiskFactorScore(
      name: json['name'] as String,
      label: json['label'] as String,
      score: score is num ? score.toDouble() : null,
      weight: weight is num ? weight.toDouble() : 0,
      usedInScore: json['usedInScore'] == true,
      unavailableReason: reason is String && reason.isNotEmpty
          ? reason
          : null,
      componentNames: (components is List)
          ? components
              .map((value) => value.toString())
              .toList(growable: false)
          : const <String>[],
    );
  }
}
