import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import 'auth_remote_data_source.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  FirebaseAuthRepository(this._remoteDataSource);

  AppUser _mapUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map(
      (user) => user == null ? null : _mapUser(user),
    );
  }

  @override
  AppUser? get currentUser {
    final user = _remoteDataSource.currentUser;

    if (user == null) {
      return null;
    }

    return _mapUser(user);
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _remoteDataSource.register(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Unable to create the user account.',
      );
    }

    await user.updateDisplayName(displayName);
    await user.sendEmailVerification();

    return _mapUser(user);
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final credential = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Unable to sign in.',
      );
    }

    return _mapUser(user);
  }

  @override
  Future<void> logout() {
    return _remoteDataSource.logout();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) {
    return _remoteDataSource.sendPasswordResetEmail(
      email: email,
    );
  }

  @override
  Future<void> changePassword({
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      newPassword: newPassword,
    );
  }

  @override
  Future<void> changeDisplayName({
    required String displayName,
  }) {
    return _remoteDataSource.changeDisplayName(
      displayName: displayName,
    );
  }

  @override
  Future<void> sendEmailVerification() {
    return _remoteDataSource.sendEmailVerification();
  }

  @override
  Future<void> reauthenticate({
    required String password,
  }) {
    return _remoteDataSource.reauthenticate(
      password: password,
    );
  }

  @override
  Future<void> deleteAccount() {
    return _remoteDataSource.deleteAccount();
  }
}