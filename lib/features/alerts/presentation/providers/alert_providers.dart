import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/alerts_repository.dart';
import '../../domain/risk_alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.watch(firestoreProvider));
});

/// Published alerts of exactly one zone + hazard context, realtime.
final alertsForContextProvider = StreamProvider.autoDispose
    .family<List<RiskAlert>, ({String zoneId, String hazardType})>((
      ref,
      context,
    ) {
      return ref
          .watch(alertsRepositoryProvider)
          .watchForContext(
            zoneId: context.zoneId,
            hazardType: context.hazardType,
          );
    });

/// Every alert of the admin history, realtime.
final allAlertsProvider = StreamProvider.autoDispose<List<RiskAlert>>(
  (ref) => ref.watch(alertsRepositoryProvider).watchAll(),
);
