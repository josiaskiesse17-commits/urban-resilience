import 'package:flutter/material.dart';

import '../domain/hazard_type.dart';
import '../domain/risk_zone.dart';

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

const Color zoneNeutralColor = Colors.blueGrey;
