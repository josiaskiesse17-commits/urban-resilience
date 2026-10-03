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

  final String name;

  final String label;

  final double? score;

  final double weight;

  final bool usedInScore;

  final String? unavailableReason;

  final List<String> componentNames;

  bool get isAvailable => score != null;

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
      unavailableReason: reason is String && reason.isNotEmpty ? reason : null,
      componentNames: (components is List)
          ? components.map((value) => value.toString()).toList(growable: false)
          : const <String>[],
    );
  }
}
