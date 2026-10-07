import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../risk/data/risk_repository.dart';
import '../../../risk/domain/zone_active_risk.dart';
import '../../../risk/presentation/hazard_presentation.dart';
import '../../../risk/presentation/providers/risk_live_providers.dart';

class ZoneMapMarker extends ConsumerWidget {
  const ZoneMapMarker({super.key, required this.zone, required this.onTap});

  final RiskZoneTarget zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRisks = ref.watch(zoneActiveRisksProvider(zone.id));

    final level = highestIdentifiedLevel(activeRisks);

    final color = level == null ? zoneNeutralColor : riskLevelColor(level);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(16, 42, 49, 0.12),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              zone.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102A31),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
