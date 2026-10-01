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
    );
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