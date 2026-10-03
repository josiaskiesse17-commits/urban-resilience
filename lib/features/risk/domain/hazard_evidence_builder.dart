import 'hazard_variable.dart';
import 'risk_measurement.dart';

/// Turns hazard variables into the shared evidence model.
///
/// Every measurement keeps its own unit, source and observation timestamp,
/// plus the statistical reference of the variable and where the live value
/// sits inside that reference. The AI analyst only interprets this evidence:
/// no calculation happens in the AI layer.
class HazardEvidenceBuilder {
  const HazardEvidenceBuilder._();

  static const String _statisticalReferenceNote =
      'référence statistique du même endroit et de la même période de '
      'référence, et non un seuil de sécurité officiel';

  static RiskMeasurement measurementFrom(
    HazardVariable variable,
  ) {
    final reference = variable.referenceValue;
    final critical = variable.statisticalCriticalValue;

    return RiskMeasurement(
      name: variable.name,
      value: variable.value,
      unit: variable.unit,
      measurementPeriod: variable.measurementPeriod,
      referenceValue: reference,
      referenceUnit: reference == null ? null : variable.unit,
      referenceLabel: variable.referenceLabel,
      referenceType: variable.referenceType,
      ratioToReference: reference != null && reference > 0
          ? variable.value / reference
          : null,
      differenceFromReference: reference == null
          ? null
          : variable.value - reference,
      historicalPercentile: variable.historicalPercentile,
      statisticalCriticalValue: critical,
      statisticalCriticalLabel: critical == null
          ? null
          : '${variable.inverted ? '5e' : '95e'} centile — '
              '$_statisticalReferenceNote',
      isDerived: variable.isDerived,
      derivationNote: variable.derivationNote,
      source: variable.source,
      observedAt: variable.observedAt,
    );
  }

  static List<RiskMeasurement> measurementsFrom(
    List<HazardVariable> variables,
  ) {
    return variables
        .map(measurementFrom)
        .toList(growable: false);
  }
}
