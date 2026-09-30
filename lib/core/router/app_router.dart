import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:urban_resilience/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:urban_resilience/features/auth/presentation/screens/login_screen.dart';
import 'package:urban_resilience/features/auth/presentation/screens/profile_screen.dart';
import 'package:urban_resilience/features/auth/presentation/screens/register_screen.dart';
import 'package:urban_resilience/features/auth/presentation/screens/verify_email_screen.dart';
import 'package:urban_resilience/features/location/presentation/location_permission_screen.dart';
import 'package:urban_resilience/features/map/presentation/map_screen.dart';
import 'package:urban_resilience/features/risk/presentation/risk_details_screen.dart';

final appRouterProvider = Provider((ref) {
  return GoRouter(
    initialLocation: '/login',
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
        path: '/risk',
        builder: (context, state) => const RiskDetailsScreen(),
      ),
      GoRoute(
        path: '/risk/:id',
        builder: (context, state) => RiskDetailsScreen(
          riskId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationPermissionScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});