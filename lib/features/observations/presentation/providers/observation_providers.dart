import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/observations_repository.dart';
import '../../domain/observation.dart';

final observationsRepositoryProvider = Provider<ObservationsRepository>((ref) {
  return ObservationsRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseStorageProvider),
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

/// Citizen-facing list.
///
/// Only observations that are still pending admin review are returned.
/// Confirmed and rejected observations remain in Firestore but disappear
/// from this pending list automatically after their status changes.
final myObservationsProvider =
    StreamProvider.autoDispose<List<Observation>>((ref) {
      final user = ref.watch(currentUserProvider);

      if (user == null) {
        return Stream<List<Observation>>.value(
          const <Observation>[],
        );
      }

      return ref
          .watch(observationsRepositoryProvider)
          .watchMyPending(user.id);
    });

final allConfirmedObservationsProvider =
    StreamProvider.autoDispose<List<Observation>>(
      (ref) =>
          ref.watch(observationsRepositoryProvider).watchAllConfirmed(),
    );