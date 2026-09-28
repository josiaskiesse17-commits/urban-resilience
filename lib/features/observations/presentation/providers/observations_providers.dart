import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/observations_repository.dart';
import '../../domain/observation.dart';

final observationsRepositoryProvider = Provider<ObservationsRepository>((ref) {
  return ObservationsRepository();
});

final verifiedObservationsProvider = StreamProvider<List<Observation>>((ref) {
  return ref.watch(observationsRepositoryProvider).watchVerifiedObservations();
});

final myObservationsProvider = StreamProvider<List<Observation>>((ref) {
  return ref.watch(observationsRepositoryProvider).watchMyObservations();
});

final pendingObservationsProvider = StreamProvider<List<Observation>>((ref) {
  return ref.watch(observationsRepositoryProvider).watchPendingObservations();
});

final isAdminProvider = FutureProvider<bool>((ref) {
  return ref.watch(observationsRepositoryProvider).isCurrentUserAdmin();
});
