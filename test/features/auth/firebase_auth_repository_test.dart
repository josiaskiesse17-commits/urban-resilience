import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/auth/data/auth_repository.dart';

import 'auth_test_fakes.dart';

void main() {
  group('FirebaseAuthRepository.register', () {
    test('creates the account, sets the name and requests verification',
        () async {
      final user = FakeUser(emailVerified: false);
      final dataSource = FakeAuthRemoteDataSource(
        currentUser: user,
        createdUser: user,
      );
      final repository = FirebaseAuthRepository(dataSource);

      final result = await repository.register(
        email: 'user@example.com',
        password: 'password123',
        displayName: 'Test User',
      );

      expect(dataSource.registerCalls, 1);
      expect(result.id, user.uid);
      expect(result.email, user.email);
      expect(result.emailVerified, isFalse);
      expect(user.sendEmailVerificationCalls, 1);
      expect(
        user.calls,
        equals([
          'updateDisplayName',
          'sendEmailVerification',
          'reload',
        ]),
      );
    });

    test('fails clearly when Firebase returns no user after signup', () async {
      final dataSource = FakeAuthRemoteDataSource(
        currentUser: null,
        createdUser: null,
      );
      final repository = FirebaseAuthRepository(dataSource);

      await expectLater(
        repository.register(
          email: 'user@example.com',
          password: 'password123',
          displayName: 'Test User',
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'registration-failed',
          ),
        ),
      );
    });

    test('surfaces verification failures instead of swallowing them',
        () async {
      final user = FakeUser(
        emailVerified: false,
        sendEmailVerificationError: FirebaseAuthException(
          code: 'too-many-requests',
          message: 'TOO_MANY_ATTEMPTS_TRY_LATER',
        ),
      );
      final dataSource = FakeAuthRemoteDataSource(
        currentUser: user,
        createdUser: user,
      );
      final repository = FirebaseAuthRepository(dataSource);

      await expectLater(
        repository.register(
          email: 'user@example.com',
          password: 'password123',
          displayName: 'Test User',
        ),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'too-many-requests',
          ),
        ),
      );

      
      expect(user.sendEmailVerificationCalls, 1);
    });
  });
}
