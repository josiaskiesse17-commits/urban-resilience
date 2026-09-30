import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/push_notifications_service.dart';
import '../../data/auth_remote_data_source.dart';
import '../../data/auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return AuthRemoteDataSource(firebaseAuth);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);

  return FirebaseAuthRepository(remoteDataSource);
});

final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  return repository.authStateChanges;
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, _) => null,
  );
});

class AuthNotifier extends AsyncNotifier<AppUser?> {
  late final AuthRepository _repository;

  @override
  Future<AppUser?> build() async {
    _repository = ref.watch(authRepositoryProvider);

    return _repository.currentUser;
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () {
        return _repository.register(
          email: email,
          password: password,
          displayName: displayName,
        );
      },
    );

    _refreshAuthState();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () {
        return _repository.login(
          email: email,
          password: password,
        );
      },
    );

    _refreshAuthState();
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        // Must run before signing out: Firestore rules only allow a
        // user to edit their own fcmTokens while still authenticated.
        await PushNotificationsService.clearTokenForCurrentUser();
        await _repository.logout();
        return null;
      },
    );

    _refreshAuthState();
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _repository.sendPasswordResetEmail(
          email: email,
        );

        return _repository.currentUser;
      },
    );
  }

  Future<void> changePassword({
    required String newPassword,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _repository.changePassword(
          newPassword: newPassword,
        );

        return _repository.currentUser;
      },
    );

    _refreshAuthState();
  }

  Future<void> changeDisplayName({
    required String displayName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _repository.changeDisplayName(
          displayName: displayName,
        );

        return _repository.currentUser;
      },
    );

    _refreshAuthState();
  }

  Future<void> sendEmailVerification() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _repository.sendEmailVerification();

        return _repository.currentUser;
      },
    );
  }

  Future<void> reauthenticate({
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _repository.reauthenticate(
          password: password,
        );

        return _repository.currentUser;
      },
    );

    _refreshAuthState();
  }

  Future<void> refreshUser() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        return _repository.currentUser;
      },
    );

    _refreshAuthState();
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () async {
        await _repository.deleteAccount();

        return null;
      },
    );

    _refreshAuthState();
  }

  void _refreshAuthState() {
    ref.invalidate(authStateChangesProvider);
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AppUser?>(
  AuthNotifier.new,
);