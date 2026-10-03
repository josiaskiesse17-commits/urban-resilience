import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/auth/data/auth_remote_data_source.dart';

import 'auth_test_fakes.dart';

void main() {
  group('AuthRemoteDataSource.sendEmailVerification', () {
    test('requests a verification email for an unverified user', () async {
      final user = FakeUser(emailVerified: false);
      final dataSource = AuthRemoteDataSource(
        FakeFirebaseAuth(currentUser: user),
      );

      await dataSource.sendEmailVerification();

      expect(user.sendEmailVerificationCalls, 1);
    });

    test('does not resend to an already verified user', () async {
      final user = FakeUser(emailVerified: true);
      final dataSource = AuthRemoteDataSource(
        FakeFirebaseAuth(currentUser: user),
      );

      await dataSource.sendEmailVerification();

      expect(user.sendEmailVerificationCalls, 0);
    });

    test('fails with user-not-found when nobody is signed in', () async {
      final dataSource = AuthRemoteDataSource(
        FakeFirebaseAuth(currentUser: null),
      );

      await expectLater(
        dataSource.sendEmailVerification(),
        throwsA(
          isA<FirebaseAuthException>().having(
            (error) => error.code,
            'code',
            'user-not-found',
          ),
        ),
      );
    });

    test(
      'propagates the exact Firebase error instead of swallowing it',
      () async {
        final user = FakeUser(
          emailVerified: false,
          sendEmailVerificationError: FirebaseAuthException(
            code: 'too-many-requests',
            message: 'TOO_MANY_ATTEMPTS_TRY_LATER',
          ),
        );
        final dataSource = AuthRemoteDataSource(
          FakeFirebaseAuth(currentUser: user),
        );

        await expectLater(
          dataSource.sendEmailVerification(),
          throwsA(
            isA<FirebaseAuthException>().having(
              (error) => error.code,
              'code',
              'too-many-requests',
            ),
          ),
        );

        expect(user.sendEmailVerificationCalls, 1);
      },
    );
  });
}
