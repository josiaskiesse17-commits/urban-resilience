import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/auth/domain/app_user.dart';
import 'package:urban_resilience/features/auth/presentation/providers/auth_providers.dart';

import 'auth_test_fakes.dart';

void main() {
  const user = AppUser(
    id: 'test-uid',
    email: 'user@example.com',
    displayName: 'Test User',
    emailVerified: false,
  );

  ProviderContainer createContainer(FakeAuthRepository repository) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AuthNotifier.register', () {
    test('completes with the registered user on success', () async {
      final repository = FakeAuthRepository(
        currentUser: user,
        registerResult: user,
      );
      final container = createContainer(repository);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).register(
            email: 'user@example.com',
            password: 'password123',
            displayName: 'Test User',
          );

      final state = container.read(authNotifierProvider);

      expect(repository.registerCalls, 1);
      expect(state.hasValue, isTrue);
      expect(state.hasError, isFalse);
      expect(state.value, same(user));
    });

    test('keeps registration errors visible on the state the UI reads',
        () async {
      final error = FirebaseAuthException(
        code: 'too-many-requests',
        message: 'TOO_MANY_ATTEMPTS_TRY_LATER',
      );
      final repository = FakeAuthRepository(
        currentUser: user,
        registerError: error,
      );
      final container = createContainer(repository);

      await container.read(authNotifierProvider.future);
      await container.read(authNotifierProvider.notifier).register(
            email: 'user@example.com',
            password: 'password123',
            displayName: 'Test User',
          );

      final state = container.read(authNotifierProvider);

      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    });
  });

  group('AuthNotifier.sendEmailVerification', () {
    test('keeps resend errors visible on the state the UI reads', () async {
      final error = FirebaseAuthException(
        code: 'too-many-requests',
        message: 'TOO_MANY_ATTEMPTS_TRY_LATER',
      );
      final repository = FakeAuthRepository(
        currentUser: user,
        sendEmailVerificationError: error,
      );
      final container = createContainer(repository);

      await container.read(authNotifierProvider.future);
      await container
          .read(authNotifierProvider.notifier)
          .sendEmailVerification();

      final state = container.read(authNotifierProvider);

      expect(repository.sendEmailVerificationCalls, 1);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    });

    test('succeeds when the repository accepts the request', () async {
      final repository = FakeAuthRepository(currentUser: user);
      final container = createContainer(repository);

      await container.read(authNotifierProvider.future);
      await container
          .read(authNotifierProvider.notifier)
          .sendEmailVerification();

      final state = container.read(authNotifierProvider);

      expect(repository.sendEmailVerificationCalls, 1);
      expect(state.hasError, isFalse);
      expect(state.value, same(user));
    });
  });
}
