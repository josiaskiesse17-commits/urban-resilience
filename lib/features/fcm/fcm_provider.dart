import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../auth/presentation/providers/auth_providers.dart';
import 'fcm_service.dart';

final firebaseMessagingProvider = Provider<FirebaseMessaging>((ref) {
  return FirebaseMessaging.instance;
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  final messaging = ref.watch(firebaseMessagingProvider);
  final firestore = ref.watch(firestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);

  final service = FcmService(
    messaging: messaging,
    firestore: firestore,
    auth: auth,
  );

  // Initialize the service (errors are caught inside initialize)
  service.initialize();

  // Dispose the service when the provider is disposed (e.g., app termination)
  ref.onDispose(() => service.dispose());

  return service;
});