import 'package:latlong2/latlong.dart';

import '../../domain/entities/map_risk.dart';

class MapRepository {
  Future<List<MapRisk>> getRisksAround(LatLng center) async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      MapRisk(
        id: 'risk_1',
        title: 'Zone inondable',
        description:
            'Risque potentiel d’inondation signalé dans cette zone.',
        position: LatLng(
          center.latitude + 0.004,
          center.longitude + 0.002,
        ),
        level: RiskLevel.high,
        type: RiskType.flood,
        address: 'Zone à proximité',
        reportedAt: DateTime.now(),
      ),
      MapRisk(
        id: 'risk_2',
        title: 'Risque d’incendie',
        description:
            'Présence d’un risque potentiel d’incendie dans cette zone.',
        position: LatLng(
          center.latitude - 0.003,
          center.longitude + 0.004,
        ),
        level: RiskLevel.critical,
        type: RiskType.fire,
        address: 'Zone à proximité',
        reportedAt: DateTime.now(),
      ),
      MapRisk(
        id: 'risk_3',
        title: 'Accident signalé',
        description:
            'Un accident a été signalé récemment dans cette zone.',
        position: LatLng(
          center.latitude + 0.002,
          center.longitude - 0.004,
        ),
        level: RiskLevel.medium,
        type: RiskType.accident,
        address: 'Zone à proximité',
        reportedAt: DateTime.now(),
      ),
      MapRisk(
        id: 'risk_4',
        title: 'Pollution',
        description:
            'Une zone présentant un niveau de pollution potentiellement élevé.',
        position: LatLng(
          center.latitude - 0.005,
          center.longitude - 0.002,
        ),
        level: RiskLevel.low,
        type: RiskType.pollution,
        address: 'Zone à proximité',
        reportedAt: DateTime.now(),
      ),
    ];
  }
}