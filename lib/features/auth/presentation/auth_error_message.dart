import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object? error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'Adresse e-mail invalide.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-login-credentials' =>
        'E-mail ou mot de passe incorrect.',
      'email-already-in-use' => 'Un compte existe déjà avec cette adresse.',
      'weak-password' => 'Le mot de passe doit contenir au moins 6 caractères.',
      'network-request-failed' => 'Connexion impossible. Vérifiez le réseau.',
      'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
      _ => 'Une erreur est survenue. Réessayez.',
    };
  }

  return 'Une erreur est survenue. Réessayez.';
}
