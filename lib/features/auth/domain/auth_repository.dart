import 'app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> login({required String email, required String password});

  Future<void> logout();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> changePassword({required String newPassword});

  Future<void> changeDisplayName({required String displayName});

  Future<void> sendEmailVerification();

  Future<void> reauthenticate({required String password});

  Future<void> deleteAccount();
}
