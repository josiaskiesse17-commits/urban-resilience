import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/observations_repository.dart';
import '../../domain/observation.dart';

final observationsRepositoryProvider = Provider<ObservationsRepository>((ref) {
  return ObservationsRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final observationsForContextProvider = StreamProvider.autoDispose
    .family<List<Observation>, ({String zoneId, String hazardType})>((
      ref,
      context,
    ) {
      return ref
          .watch(observationsRepositoryProvider)
          .watchForContext(
            zoneId: context.zoneId,
            hazardType: context.hazardType,
          );
    });

final pendingObservationsProvider =
    StreamProvider.autoDispose<List<Observation>>(
      (ref) => ref.watch(observationsRepositoryProvider).watchPending(),
    );
