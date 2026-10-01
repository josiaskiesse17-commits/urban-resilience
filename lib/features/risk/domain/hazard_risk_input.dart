import 'hazard_type.dart';
import 'hazard_variable.dart';

/// Everything the hazard model needs for one assessment.
///
/// The input is built from three independent origins, and each one is
/// allowed to be absent:
///
/// * the environmental variables measured for the hazard (live data plus the
///   statistical reference of the same location and season);
/// * the variables the hazard model needed but could not obtain, reported
///   explicitly as [gaps] so they are never scored as zero and never vanish
///   from the factor breakdown;
/// * the stored exposure profile of the zone;
/// * the citizen observations, which are intentionally not connected in this
///   release.
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

  /// Label of the primary risk factor in the stored result.
  final String primaryFactorLabel;

  final List<HazardVariable> variables;

  /// Variables of the hazard catalog that could not be measured or scored.
  ///
  /// Each gap still appears in the factor breakdown with a null score and an
  /// explicit reason, so a missing measurement is reported as missing, never
  /// as zero and never as a silently dropped factor.
  final List<HazardVariableGap> gaps;

  /// Stored vulnerability of the zone, or null when no exposure profile is
  /// available. Null is reported as unknown, never scored as zero.
  final double? vulnerabilityScore;

  /// Stored historical exposure of the zone for *this* hazard, or null when
  /// the stored profile has no hazard-specific value.
  final double? historicalExposureScore;

  final double observationScore;
  final int observationCount;
  final int confirmedObservationCount;

  final bool exposureProfileMissing;

  /// What the exposure profile did or did not provide, in plain language.
  final String exposureNote;

  /// What the hazard model cannot assess with the data available today.
  final List<String> limitations;

  /// Provider and baseline facts that must reach the evidence (a variable
  /// without a historical counterpart, a provider that returned no usable
  /// series, ...).
  final List<String> notes;

  final DateTime? referencePeriodStart;
  final DateTime? referencePeriodEnd;
  final String? referenceSource;

  /// True when at least one reference fell back to the whole reference period
  /// because the location/season bucket was too small.
  final bool partialReference;

  bool get hasReferencePeriod =>
      referencePeriodStart != null && referencePeriodEnd != null;
}
