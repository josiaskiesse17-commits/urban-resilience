import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/push_notifications_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Must be registered before runApp so notifications still arrive while
  // the app is fully closed, not just backgrounded.
  PushNotificationsService.registerBackgroundHandler();

  runApp(
    const ProviderScope(
      child: UrbanResilienceApp(),
    ),
  );
}

class UrbanResilienceApp extends ConsumerWidget {
  const UrbanResilienceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Keeps this device's push-notification token in sync with the
    // signed-in user, both right after login and on a cold start where
    // the user was already signed in.
    ref.listen<AsyncValue<AppUser?>>(authStateChangesProvider, (
      previous,
      next,
    ) {
      final user = next.value;
      if (user != null) {
        PushNotificationsService.registerForCurrentUser(user.id);
      }
    });

    return MaterialApp.router(
      title: 'Urban Resilience',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
