import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSource(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.userChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() {
    return _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({required String newPassword}) async {
    final user = _requireCurrentUser();
    await user.updatePassword(newPassword);
  }

  Future<void> changeDisplayName({required String displayName}) async {
    final user = _requireCurrentUser();

    await user.updateDisplayName(displayName);
  }

  Future<void> sendEmailVerification() async {
    final user = _requireCurrentUser();

    if (user.emailVerified) {
      return;
    }

    await user.sendEmailVerification();
  }

  Future<void> reauthenticate({required String password}) async {
    final user = _requireCurrentUser();
    final email = user.email;

    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-email',
        message: 'Aucune adresse e-mail n’est associée à ce compte.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> reloadUser() async {
    final user = _requireCurrentUser();

    await user.reload();
  }

  Future<void> deleteAccount() {
    final user = _requireCurrentUser();

    return user.delete();
  }

  User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aucun utilisateur authentifié.',
      );
    }

    return user;
  }
}
