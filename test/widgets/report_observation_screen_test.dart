import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urban_resilience/features/observations/presentation/report_observation_screen.dart';

/// These tests pump [ReportObservationScreen] directly (not the full app),
/// so no Firebase initialisation is needed: the screen only reaches into
/// the Firebase-backed repository once client-side validation has passed,
/// and these tests deliberately stop before that point.
void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ReportObservationScreen(),
        ),
      ),
    );
  }

  group('ReportObservationScreen', () {
    testWidgets('renders the form with its key elements', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Nouveau signalement'), findsOneWidget);
      expect(find.text('Que constatez-vous ?'), findsOneWidget);
      expect(find.text('Ajouter une photo'), findsOneWidget);
      expect(find.text('Envoyer le signalement'), findsOneWidget);
    });

    testWidgets(
      'shows a validation message when the description is too short',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(
          find.text('La description doit contenir au moins 10 caractères.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows a validation message when no GPS position was captured',
      (tester) async {
        await pumpScreen(tester);

        await tester.enterText(
          find.byType(TextField),
          'Une route est bloquée par un arbre tombé après la tempête.',
        );
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(
          find.text('Récupérez votre position avant l’envoi.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('lets the user choose between the three incident types', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Inondation'), findsOneWidget);
      expect(find.text('Éboulement'), findsOneWidget);
      expect(find.text('Incendie'), findsOneWidget);

      await tester.tap(find.text('Éboulement'));
      await tester.pump();

      // Selecting a type should not throw or change the screen structure.
      expect(find.text('Envoyer le signalement'), findsOneWidget);
    });

    testWidgets('opens the photo source picker when tapping the photo card', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Prendre ou choisir une photo'));
      await tester.pumpAndSettle();

      expect(find.text('Prendre une photo'), findsOneWidget);
      expect(find.text('Choisir dans la galerie'), findsOneWidget);
    });
  });
}
