import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/screens/admin_alerts_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_observations_screen.dart';
import '../../features/admin/presentation/screens/admin_risk_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/map/presentation/map_screen.dart';
import '../../features/observations/presentation/observations_screen.dart';
import '../../features/risk/presentation/risk_details_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final adminStatus = ref.watch(adminStatusProvider);

  final router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final user = firebaseAuth.currentUser;
      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      final isVerificationRoute = location == '/verify-email';

      final isAdminRoute = location.startsWith('/admin');

      if (user == null) {
        if (isAuthRoute) {
          return null;
        }

        return '/login';
      }

      if (!user.emailVerified) {
        if (isVerificationRoute) {
          return null;
        }

        return '/verify-email';
      }

      if (adminStatus.isLoading) {
        return null;
      }

      final isAdmin = adminStatus.when(
        data: (value) => value,
        loading: () => false,
        error: (_, _) => false,
      );

      if (isAdmin) {
        if (isAuthRoute || isVerificationRoute) {
          return '/admin/dashboard';
        }

        if (!isAdminRoute) {
          return '/admin/dashboard';
        }

        return null;
      }

      if (isAdminRoute) {
        return '/home';
      }

      if (isAuthRoute || isVerificationRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/risk/:id',
        builder: (context, state) {
          final riskId = state.pathParameters['id']!;

          return RiskDetailsScreen(
            riskId: riskId,
          );
        },
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/observations',
        builder: (context, state) => const ObservationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) {
              return const AdminDashboardScreen();
            },
          ),
          GoRoute(
            path: '/admin/risk',
            builder: (context, state) {
              return const AdminRiskScreen();
            },
          ),
          GoRoute(
            path: '/admin/observations',
            builder: (context, state) {
              return const AdminObservationsScreen();
            },
          ),
          GoRoute(
            path: '/admin/alerts',
            builder: (context, state) {
              return const AdminAlertsScreen();
            },
          ),
        ],
      ),
    ],
  );

  ref.listen(adminStatusProvider, (_, _) {
    router.refresh();
  });

  ref.listen(authStateChangesProvider, (_, _) {
    router.refresh();
  });

  ref.onDispose(router.dispose);

  return router;
});