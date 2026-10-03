class RiskAnalysis {
  final String riskId;
  final String summary;
  final String explanation;
  final List<String> mainFactors;
  final List<String> recommendations;
  final DateTime generatedAt;

  const RiskAnalysis({
    required this.riskId,
    required this.summary,
    required this.explanation,
    required this.mainFactors,
    required this.recommendations,
    required this.generatedAt,
  });

  factory RiskAnalysis.fromJson(
    Map<String, dynamic> json, {
    required String riskId,
    required DateTime generatedAt,
  }) {
    final summary = json['summary'];
    final explanation = json['explanation'];
    final mainFactors = json['mainFactors'];
    final recommendations = json['recommendations'];

    if (summary is! String ||
        explanation is! String ||
        mainFactors is! List ||
        recommendations is! List) {
      throw const FormatException(
        'Invalid AI risk analysis format.',
      );
    }

    return RiskAnalysis(
      riskId: riskId,
      summary: summary,
      explanation: explanation,
      mainFactors: mainFactors
          .map((item) => item.toString())
          .toList(),
      recommendations: recommendations
          .map((item) => item.toString())
          .toList(),
      generatedAt: generatedAt,
    );
  }

  
  
  
  
  
  Map<String, dynamic> toJson() {
    return {
      'riskId': riskId,
      'summary': summary,
      'explanation': explanation,
      'mainFactors': mainFactors,
      'recommendations': recommendations,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}