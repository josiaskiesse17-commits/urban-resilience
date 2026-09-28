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
    // The form is taller than the default 800x600 test surface, which
    // pushes the submit button and other controls off-screen and makes
    // tester.tap() silently miss them. Use a tall phone-sized surface so
    // every widget on this screen is reachable by taps.
    tester.view.physicalSize = const Size(430, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    testWidgets(
      'reveals a text field when "Autre type de risque" is selected',
      (tester) async {
        await pumpScreen(tester);

        expect(find.text('Titre du risque constaté'), findsNothing);

        await tester.tap(find.text('Autre type de risque (à préciser)'));
        await tester.pump();

        expect(find.text('Titre du risque constaté'), findsOneWidget);
      },
    );

    testWidgets(
      'asks for a custom title when "Autre" is selected but left empty',
      (tester) async {
        await pumpScreen(tester);

        await tester.enterText(
          find.byType(TextField).first,
          'Une route est bloquée par un arbre tombé après la tempête.',
        );
        await tester.tap(find.text('Autre type de risque (à préciser)'));
        await tester.pump();

        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        expect(
          find.text(
            'Précisez le type de risque (au moins 3 caractères).',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
