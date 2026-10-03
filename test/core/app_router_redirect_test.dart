import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/core/router/app_router.dart';

void main() {
  String? redirect(
    String location, {
    bool isAuthenticated = true,
    bool isEmailVerified = true,
    bool isAdminStatusLoading = false,
    bool isAdmin = false,
  }) {
    return appRouteRedirect(
      location: location,
      isAuthenticated: isAuthenticated,
      isEmailVerified: isEmailVerified,
      isAdminStatusLoading: isAdminStatusLoading,
      isAdmin: isAdmin,
    );
  }

  group('guests', () {
    test('are sent to the login screen', () {
      expect(redirect('/home', isAuthenticated: false), '/login');
      expect(redirect('/admin/risk', isAuthenticated: false), '/login');
      expect(redirect('/risk/zone-masina', isAuthenticated: false), '/login');
    });

    test('can stay on the sign-in routes', () {
      expect(redirect('/login', isAuthenticated: false), isNull);
      expect(redirect('/register', isAuthenticated: false), isNull);
      expect(redirect('/forgot-password', isAuthenticated: false), isNull);
    });
  });

  group('unverified users', () {
    test('must verify their email before anything else', () {
      expect(redirect('/home', isEmailVerified: false), '/verify-email');
      expect(redirect('/admin/risk', isEmailVerified: false), '/verify-email');
    });

    test('can stay on the verification route', () {
      expect(redirect('/verify-email', isEmailVerified: false), isNull);
    });
  });

  group('ordinary users', () {
    test('can open citizen routes', () {
      expect(redirect('/home'), isNull);
      expect(redirect('/risk/zone-masina'), isNull);
      expect(redirect('/profile'), isNull);
    });

    test('cannot access admin routes', () {
      expect(redirect('/admin/risk'), '/home');
      expect(redirect('/admin/dashboard'), '/home');
      expect(redirect('/admin/observations'), '/home');
      expect(redirect('/admin/alerts'), '/home');
      expect(redirect('/admin'), '/home');
    });

    test('leave auth routes after signing in', () {
      expect(redirect('/login'), '/home');
      expect(redirect('/register'), '/home');
      expect(redirect('/forgot-password'), '/home');
      expect(redirect('/verify-email'), '/home');
    });
  });

  group('active admins', () {
    test('are routed into the admin shell', () {
      expect(redirect('/home', isAdmin: true), '/admin/dashboard');
      expect(redirect('/login', isAdmin: true), '/admin/dashboard');
      expect(redirect('/verify-email', isAdmin: true), '/admin/dashboard');
      expect(redirect('/risk/zone-masina', isAdmin: true), '/admin/dashboard');
    });

    test('can stay on every admin route', () {
      expect(redirect('/admin/dashboard', isAdmin: true), isNull);
      expect(redirect('/admin/risk', isAdmin: true), isNull);
      expect(redirect('/admin/observations', isAdmin: true), isNull);
      expect(redirect('/admin/alerts', isAdmin: true), isNull);
    });
  });

  group('admin status loading', () {
    test('defers the decision instead of guessing a role', () {
      expect(redirect('/home', isAdminStatusLoading: true), isNull);
      expect(redirect('/admin/risk', isAdminStatusLoading: true), isNull);
    });
  });
}
