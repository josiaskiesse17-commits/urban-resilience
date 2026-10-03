import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:urban_resilience/features/home/presentation/home_screen.dart';
import 'package:urban_resilience/features/map/presentation/map_screen.dart';
import 'package:urban_resilience/features/map/presentation/providers/map_provider.dart';
import 'package:urban_resilience/features/map/presentation/widgets/zone_map_marker.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';

import '../risk/risk_test_fakes.dart';



class _FakeLocationController extends MapLocationController {
  @override
  MapState build() => const MapState(
        currentLocation: null,
        selectedLocation: MapLocationController.defaultLocation,
        loading: false,
        locationPermissionDenied: false,
        error: null,
      );

  @override
  Future<void> initialize() async {}
}

void main() {
  testWidgets(
    'home sends the citizen to the map instead of listing zones',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapControllerProvider.overrideWith(
              _FakeLocationController.new,
            ),
            riskResultRepositoryProvider.overrideWith(
              (ref) => StoredByHazardRepository(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      
      expect(find.text('Masina'), findsNothing);
      expect(find.text('Ouvrir la carte'), findsOneWidget);

      await tester.tap(find.text('Ouvrir la carte'));
      await tester.pumpAndSettle();

      
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byType(ZoneMapMarker), findsWidgets);

      router.dispose();
    },
  );
}
