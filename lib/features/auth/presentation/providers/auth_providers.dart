import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_remote_data_source.dart';
import '../../data/auth_repository.dart';
import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
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

final adminStatusProvider = StreamProvider<bool>((ref) {
  ref.watch(authStateChangesProvider);

  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  final user = firebaseAuth.currentUser;

  debugPrint('AUTH USER: ${user?.email}');
  debugPrint('AUTH UID: ${user?.uid}');

  if (user == null) {
    debugPrint('ADMIN CHECK: no authenticated user');
    return Stream.value(false);
  }

  return firestore
      .collection('admins')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
    debugPrint('ADMIN DOC EXISTS: ${snapshot.exists}');
    debugPrint('ADMIN DOC DATA: ${snapshot.data()}');

    if (!snapshot.exists) {
      debugPrint('IS ADMIN: false');
      return false;
    }

    final data = snapshot.data();
    final isAdmin = data?['active'] == true;

    debugPrint('IS ADMIN: $isAdmin');

    return isAdmin;
  });
});

final isAdminProvider = Provider<bool>((ref) {
  final adminStatus = ref.watch(adminStatusProvider);

  return adminStatus.when(
    data: (isAdmin) => isAdmin,
    loading: () => false,
    error: (_, _) => false,
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
