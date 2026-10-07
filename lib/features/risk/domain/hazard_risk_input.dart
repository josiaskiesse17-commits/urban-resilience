import 'hazard_type.dart';
import 'hazard_variable.dart';

class HazardRiskInput {
  const HazardRiskInput({
    required this.hazard,
    required this.primaryFactorLabel,
    required this.variables,
    this.gaps = const <HazardVariableGap>[],
    this.vulnerabilityScore,
    this.historicalExposureScore,
    this.observationScore = 0,
    this.observationCount = 0,
    this.confirmedObservationCount = 0,
    this.exposureProfileMissing = false,
    this.exposureNote = '',
    this.limitations = const <String>[],
    this.notes = const <String>[],
    this.referencePeriodStart,
    this.referencePeriodEnd,
    this.referenceSource,
    this.partialReference = false,
  });

  final HazardType hazard;

  final String primaryFactorLabel;

  final List<HazardVariable> variables;

  final List<HazardVariableGap> gaps;

  final double? vulnerabilityScore;

  final double? historicalExposureScore;

  final double observationScore;
  final int observationCount;
  final int confirmedObservationCount;

  final bool exposureProfileMissing;

  final String exposureNote;

  final List<String> limitations;

  final List<String> notes;

  final DateTime? referencePeriodStart;
  final DateTime? referencePeriodEnd;
  final String? referenceSource;

  final bool partialReference;

  bool get hasReferencePeriod =>
      referencePeriodStart != null && referencePeriodEnd != null;
}
