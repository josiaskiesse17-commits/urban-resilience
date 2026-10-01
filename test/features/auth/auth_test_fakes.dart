import 'package:firebase_auth/firebase_auth.dart';

import 'package:urban_resilience/features/auth/data/auth_remote_data_source.dart';
import 'package:urban_resilience/features/auth/domain/app_user.dart';
import 'package:urban_resilience/features/auth/domain/auth_repository.dart';

/// Fake [User] that records the calls made by the auth flow and can simulate
/// Firebase failures (for example the `too-many-requests` throttling that
/// Firebase returns when a verification email is requested twice in a row).
class FakeUser implements User {
  FakeUser({
    this.uid = 'test-uid',
    this.email = 'user@example.com',
    this.displayName = 'Test User',
    this.emailVerified = false,
    this.sendEmailVerificationError,
  });

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  final bool emailVerified;

  /// When set, [sendEmailVerification] throws it after recording the call.
  final Object? sendEmailVerificationError;

  /// Ordered log of the user operations invoked by the code under test.
  final List<String> calls = [];

  int get sendEmailVerificationCalls =>
      calls.where((call) => call == 'sendEmailVerification').length;

  @override
  Future<void> reload() async {
    calls.add('reload');
  }

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    calls.add('sendEmailVerification');

    final error = sendEmailVerificationError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {
    calls.add('updateDisplayName');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake [UserCredential] exposing only the `user` the repository reads.
class FakeUserCredential implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake [FirebaseAuth] exposing only `currentUser`.
class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.currentUser});

  @override
  final User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake [AuthRemoteDataSource] that returns a scripted signup result.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  FakeAuthRemoteDataSource({this.currentUser, this.createdUser});

  /// Mirrors `FirebaseAuth.currentUser` after signup.
  @override
  final User? currentUser;

  /// Returned as `credential.user` from [register]; `null` simulates a
  /// signup that produced no user.
  final User? createdUser;

  Object? registerError;
  int registerCalls = 0;

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    registerCalls += 1;

    final error = registerError;
    if (error != null) {
      throw error;
    }

    return FakeUserCredential(createdUser);
  }

  @override
  Stream<User?> get authStateChanges => const Stream<User?>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Fake [AuthRepository] used to verify how [AuthNotifier] surfaces results.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.currentUser,
    this.registerResult,
    this.registerError,
    this.sendEmailVerificationError,
  });

  @override
  final AppUser? currentUser;

  AppUser? registerResult;
  Object? registerError;
  Object? sendEmailVerificationError;
  int registerCalls = 0;
  int sendEmailVerificationCalls = 0;

  @override
  Stream<AppUser?> get authStateChanges => const Stream<AppUser?>.empty();

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    registerCalls += 1;

    final error = registerError;
    if (error != null) {
      throw error;
    }

    final result = registerResult ?? currentUser;
    if (result == null) {
      throw StateError('FakeAuthRepository has no user to return.');
    }

    return result;
  }

  @override
  Future<void> sendEmailVerification() async {
    sendEmailVerificationCalls += 1;

    final error = sendEmailVerificationError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> changePassword({required String newPassword}) async {}

  @override
  Future<void> changeDisplayName({required String displayName}) async {}

  @override
  Future<void> reauthenticate({required String password}) async {}

  @override
  Future<void> deleteAccount() async {}
}
