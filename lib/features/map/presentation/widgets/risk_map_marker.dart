import 'package:flutter/material.dart';

import '../../domain/entities/map_risk.dart';

class RiskMapMarker extends StatelessWidget {
  final MapRisk risk;
  final VoidCallback onTap;

  const RiskMapMarker({
    super.key,
    required this.risk,
    required this.onTap,
  });

  Color get color {
    switch (risk.level) {
      case RiskLevel.low:
        return const Color(0xFF6B8F71);
      case RiskLevel.medium:
        return const Color(0xFFE8A629);
      case RiskLevel.high:
      case RiskLevel.critical:
        return const Color(0xFFD64A45);
    }
  }

  IconData get icon {
    switch (risk.type) {
      case RiskType.flood:
        return Icons.water;
      case RiskType.fire:
        return Icons.local_fire_department;
      case RiskType.accident:
        return Icons.car_crash;
      case RiskType.crime:
        return Icons.warning;
      case RiskType.building:
        return Icons.domain;
      case RiskType.pollution:
        return Icons.cloud;
      case RiskType.other:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 23,
        ),
      ),
    );
  }
}