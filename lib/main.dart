import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'firebase_options.dart';
import 'features/fcm/fcm_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Enable Firestore persistence for offline caching
  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true);

  if (kDebugMode && kIsWeb) {
    await FirebaseAppCheck.instance.activate(providerWeb: WebDebugProvider());
  }

  runApp(const ProviderScope(child: UrbanResilienceApp()));
}

class UrbanResilienceApp extends ConsumerWidget {
  const UrbanResilienceApp({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Trigger FCM service initialization
    ref.watch(fcmServiceProvider);

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