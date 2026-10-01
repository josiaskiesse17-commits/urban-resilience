/// Disaster types the Risk Intelligence engine can assess.
///
/// The application only declared `Flooding` (the flooding risk pipeline) and
/// `Landslide` (as an observation category) before the multi-hazard work.
/// `Drought`, `Heat`, `Wildfire` and `Storm` were added as first-class hazards
/// of the *same* shared architecture: they reuse `RiskResult`, `RiskEvidence`,
/// `RiskMeasurement`, the Firestore repositories, the providers and the
/// screens instead of introducing a parallel design.
///
/// [label] is what is written to `RiskResult.hazardType`, so the stored
/// documents stay human readable. The flooding label is deliberately spelled
/// `Flooding` because documents and tests already use that value.
enum HazardType {
  flooding(
    id: 'flooding',
    label: 'Flooding',
    riskNoun: 'flood risk',
  ),
  landslide(
    id: 'landslide',
    label: 'Landslide',
    riskNoun: 'landslide risk',
  ),
  drought(
    id: 'drought',
    label: 'Drought',
    riskNoun: 'drought risk',
  ),
  heat(
    id: 'heat',
    label: 'Heat',
    riskNoun: 'heat risk',
  ),
  wildfire(
    id: 'wildfire',
    label: 'Wildfire',
    riskNoun: 'wildfire risk',
  ),
  storm(
    id: 'storm',
    label: 'Storm',
    riskNoun: 'storm risk',
  );

  const HazardType({
    required this.id,
    required this.label,
    required this.riskNoun,
  });

  /// Stable identifier used in risk ids (`zone-masina--heat`).
  final String id;

  /// Human readable name stored in `RiskResult.hazardType`.
  final String label;

  /// Short noun used by the screens (`Flood risk`, `Heat risk`).
  final String riskNoun;

  /// Hazard assumed for ids that carry no hazard suffix.
  ///
  /// Such ids are the flooding assessments written before other hazards
  /// existed, so they must keep resolving to flooding.
  static const HazardType legacyDefault = HazardType.flooding;

  static HazardType? fromId(String id) {
    for (final hazard in HazardType.values) {
      if (hazard.id == id) {
        return hazard;
      }
    }

    return null;
  }

  static HazardType? fromLabel(String label) {
    for (final hazard in HazardType.values) {
      if (hazard.label == label) {
        return hazard;
      }
    }

    return null;
  }
}
