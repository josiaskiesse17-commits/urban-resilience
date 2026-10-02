import 'package:flutter/material.dart';

import '../domain/hazard_type.dart';
import '../domain/risk_zone.dart';

/// Single place where a hazard is turned into a display icon.
///
/// Used by the Zone Active Risks selection UI. The map markers deliberately
/// do not use hazard icons: they only show a coloured dot for the highest
/// identified risk level of the zone.
IconData hazardIcon(HazardType hazard) {
  switch (hazard) {
    case HazardType.flooding:
      return Icons.water;
    case HazardType.heat:
      return Icons.thermostat;
    case HazardType.landslide:
      return Icons.terrain;
  }
}

/// Single place where a risk level is turned into a display colour, shared
/// by the map markers and the Active Risks selection UI.
Color riskLevelColor(RiskLevel level) {
  switch (level) {
    case RiskLevel.low:
      return Colors.green;
    case RiskLevel.medium:
      return Colors.orange;
    case RiskLevel.high:
      return Colors.deepOrange;
    case RiskLevel.critical:
      return Colors.red;
  }
}

/// Neutral marker colour for a zone whose risks are still loading, could not
/// be loaded, or are not identified.
const Color zoneNeutralColor = Colors.blueGrey;
