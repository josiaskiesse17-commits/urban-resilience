













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

  
  final String id;

  
  final String label;

  
  
  final String labelFr;

  
  final String riskNoun;

  
  final String riskNounFr;

  
  
  
  
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
