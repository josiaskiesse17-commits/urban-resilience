// Tests de fumée de base pour l'application.
//
// UrbanResilienceApp construit son routeur à partir de FirebaseAuth.instance
// (voir lib/core/router/app_router.dart), ce qui nécessite Firebase.initializeApp()
// au préalable. Ce n'est pas disponible dans l'environnement de test par défaut.
// On teste donc ici les écrans qui ne dépendent pas de Firebase pour s'afficher.
// Les tests couvrant Firestore/Storage/Auth vivent dans leurs propres suites,
// avec les dépendances mockées ou injectées.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_resilience/features/observations/presentation/report_observation_screen.dart';

void main() {
  testWidgets('ReportObservationScreen builds without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReportObservationScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
