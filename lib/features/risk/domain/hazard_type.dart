/// Disaster types the Risk Intelligence engine can assess.
///
/// The application supports three hazards, and all three are carried by the
/// *same* shared architecture: they reuse `RiskResult`, `RiskEvidence`,
/// `RiskMeasurement`, the Firestore repositories, the providers and the
/// screens instead of introducing a parallel design.
///
/// `Flooding` keeps its dedicated pipeline (`LiveFloodRiskService` →
/// `FloodRiskCalculator`), `Landslide` and `Heat` are assessed by the generic
/// catalog-driven engine (`HazardCatalog` → `HazardRiskService`).
///
/// [label] is what is written to `RiskResult.hazardType`, so the stored
/// documents stay human readable. The flooding label is deliberately spelled
/// `Flooding` because documents and tests already use that value.
enum HazardType {
  flooding(
    id: 'flooding',
    label: 'Flooding',
    labelFr: 'Inondation',
    riskNoun: 'flood risk',
    riskNounFr: 'risque d’inondation',
  ),
  landslide(
    id: 'landslide',
    label: 'Landslide',
    labelFr: 'Glissement de terrain',
    riskNoun: 'landslide risk',
    riskNounFr: 'risque de glissement de terrain',
  ),
  heat(
    id: 'heat',
    label: 'Heat',
    labelFr: 'Chaleur',
    riskNoun: 'heat risk',
    riskNounFr: 'risque de chaleur',
  );

  const HazardType({
    required this.id,
    required this.label,
    required this.labelFr,
    required this.riskNoun,
    required this.riskNounFr,
  });

  /// Stable identifier used in risk ids (`zone-masina--heat`).
  final String id;

  /// Human readable name stored in `RiskResult.hazardType`.
  final String label;

  /// French wording shown to the user. Only [label] is ever persisted, so
  /// stored documents stay stable while the interface stays French.
  final String labelFr;

  /// Short noun used by the screens (`Flood risk`, `Heat risk`).
  final String riskNoun;

  /// French noun used by the screens.
  final String riskNounFr;

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
