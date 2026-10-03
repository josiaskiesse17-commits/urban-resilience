import 'risk_analysis.dart';
import 'risk_evidence.dart';
import 'risk_factors.dart';
import 'risk_measurement.dart';
import 'risk_zone.dart';

class RiskResult {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final String hazardType;
  final double riskScore;
  final RiskLevel riskLevel;
  final RiskFactors factors;
  final RiskEvidence evidence;
  final DateTime updatedAt;

  /// AI interpretation of *this* evaluation, or null when the AI has not
  /// interpreted this version yet.
  ///
  /// It is stored inside the same `risk_results/{id}` document as the result it
  /// interprets, so it is tied to the evaluation version ([updatedAt]): a new
  /// evaluation writes a fresh result, which clears this field and lets the AI
  /// generate one new interpretation for the new version.
  final RiskAnalysis? analysis;

  const RiskResult({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.hazardType,
    required this.riskScore,
    required this.riskLevel,
    required this.factors,
    required this.evidence,
    required this.updatedAt,
    this.analysis,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'hazardType': hazardType,
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'factors': factors.toJson(),
      'evidence': evidence.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Firestore representation of the result, including the AI interpretation
  /// stored with it.
  ///
  /// Kept separate from [toJson] so the AI request keeps sending exactly the
  /// evaluation it has to interpret, without its own previous interpretation.
  Map<String, dynamic> toStoredJson() {
    return {
      ...toJson(),
      'analysis': analysis?.toJson(),
    };
  }

  /// Returns a copy of this result carrying [analysis] as its stored AI
  /// interpretation. Every other field, including the evaluation version
  /// ([updatedAt]), is preserved.
  RiskResult withAnalysis(RiskAnalysis analysis) {
    return RiskResult(
      id: id,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      hazardType: hazardType,
      riskScore: riskScore,
      riskLevel: riskLevel,
      factors: factors,
      evidence: evidence,
      updatedAt: updatedAt,
      analysis: analysis,
    );
  }

  factory RiskResult.fromJson(Map<String, dynamic> json) {
    final factorsJson =
        Map<String, dynamic>.from(
      json['factors'] as Map,
    );

    final evidenceJson =
        Map<String, dynamic>.from(
      json['evidence'] as Map,
    );

    final measurementJson =
        (evidenceJson['measurements'] as List?)
                ?.map(
                  (item) => Map<String, dynamic>.from(
                    item as Map,
                  ),
                )
                .toList() ??
            <Map<String, dynamic>>[];

    final measurements = measurementJson.map((json) {
      return RiskMeasurement(
        name: json['name'] as String,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        measurementPeriod:
            json['measurementPeriod'] as String?,
        referenceValue:
            (json['referenceValue'] as num?)?.toDouble(),
        referenceUnit:
            json['referenceUnit'] as String?,
        referenceLabel:
            json['referenceLabel'] as String?,
        referenceType: _parseReferenceType(
          json['referenceType'],
        ),
        ratioToReference:
            (json['ratioToReference'] as num?)?.toDouble(),
        differenceFromReference:
            (json['differenceFromReference'] as num?)
                ?.toDouble(),
        historicalPercentile:
            (json['historicalPercentile'] as num?)
                ?.toDouble(),
        statisticalCriticalValue:
            (json['statisticalCriticalValue'] as num?)
                ?.toDouble(),
        statisticalCriticalLabel:
            json['statisticalCriticalLabel'] as String?,
        isDerived: json['isDerived'] == true,
        derivationNote:
            json['derivationNote'] as String?,
        source: json['source'] as String?,
        observedAt: _parseDateTime(
          json['observedAt'],
        ),
      );
    }).toList();

    final qualitativeIndicators =
        (evidenceJson['qualitativeIndicators'] as List?)
                ?.map((value) => value.toString())
                .toList() ??
            <String>[];

    final analysis = _parseAnalysis(
      json['analysis'],
      json['id'] as String,
    );

    return RiskResult(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      hazardType: json['hazardType'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      riskLevel: _parseRiskLevel(
        json['riskLevel'],
      ),
      factors: RiskFactors.fromJson(factorsJson),
      evidence: RiskEvidence(
        measurements: measurements,
        qualitativeIndicators: qualitativeIndicators,
        observationCount:
            (evidenceJson['observationCount'] as num?)?.toInt() ??
                0,
        confirmedObservationCount:
            (evidenceJson['confirmedObservationCount'] as num?)
                    ?.toInt() ??
                0,
        collectedAt: _parseDateTime(
          evidenceJson['collectedAt'],
        ) ??
            DateTime.now().toUtc(),
      ),
      updatedAt:
          _parseDateTime(json['updatedAt']) ??
              DateTime.now().toUtc(),
      analysis: analysis,
    );
  }

  /// Reads the stored AI interpretation.
  ///
  /// A malformed interpretation resolves to null instead of failing the whole
  /// result: the evaluation is still usable and the AI will simply be asked
  /// once more. A failed request is never stored, so this only ever drops an
  /// unreadable document.
  static RiskAnalysis? _parseAnalysis(
    Object? value,
    String riskId,
  ) {
    if (value is! Map) {
      return null;
    }

    try {
      final json = Map<String, dynamic>.from(value);

      return RiskAnalysis.fromJson(
        json,
        riskId: json['riskId'] as String? ?? riskId,
        generatedAt: _parseDateTime(json['generatedAt']) ??
            DateTime.now().toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  static RiskLevel _parseRiskLevel(
    Object? value,
  ) {
    final name = value?.toString();

    return RiskLevel.values.firstWhere(
      (level) => level.name == name,
      orElse: () => RiskLevel.low,
    );
  }

  static RiskReferenceType? _parseReferenceType(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    final name = value.toString();

    return RiskReferenceType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => RiskReferenceType.threshold,
    );
  }

  static DateTime? _parseDateTime(
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}