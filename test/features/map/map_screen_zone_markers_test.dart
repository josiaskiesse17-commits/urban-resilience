import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/map/presentation/map_screen.dart';
import 'package:urban_resilience/features/map/presentation/providers/map_provider.dart';
import 'package:urban_resilience/features/map/presentation/widgets/zone_active_risks_sheet.dart';
import 'package:urban_resilience/features/map/presentation/widgets/zone_map_marker.dart';
import 'package:urban_resilience/features/risk/data/risk_repository.dart';
import 'package:urban_resilience/features/risk/domain/risk_zone.dart';
import 'package:urban_resilience/features/risk/presentation/hazard_presentation.dart';
import 'package:urban_resilience/features/risk/presentation/providers/risk_live_providers.dart';

import '../risk/risk_result_test_support.dart';
import '../risk/risk_test_fakes.dart';

/// Location controller that keeps the map tests off the Geolocator platform
/// channels while behaving like the real one.
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

Widget buildMapHost({
  required StoredByHazardRepository repository,
}) {
  return ProviderScope(
    overrides: [
      mapControllerProvider.overrideWith(_FakeLocationController.new),
      riskResultRepositoryProvider.overrideWith((ref) => repository),
    ],
    child: const MaterialApp(home: MapScreen()),
  );
}

Widget buildMarkerHost({
  required StoredByHazardRepository repository,
  required RiskZoneTarget zone,
}) {
  return ProviderScope(
    overrides: [
      riskResultRepositoryProvider.overrideWith((ref) => repository),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: ZoneMapMarker(zone: zone, onTap: () {}),
        ),
      ),
    ),
  );
}

/// Colour of the circular point of a marker.
Color? _dotColor(WidgetTester tester) {
  for (final container in tester.widgetList<Container>(
    find.byType(Container),
  )) {
    final decoration = container.decoration;

    if (decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle) {
      return decoration.color;
    }
  }

  return null;
}

void _useLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}


void main() {
  testWidgets(
    'paints one named marker per configured zone',
    (tester) async {
      _useLargeView(tester);

      await tester.pumpWidget(
        buildMapHost(repository: StoredByHazardRepository()),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(ZoneMapMarker),
        findsNWidgets(RiskZoneCatalog.zones.length),
      );

      for (final zone in RiskZoneCatalog.zones) {
        expect(find.text(zone.name), findsOneWidget);
      }
    },
  );

  testWidgets(
    'the marker colour is the highest risk identified in the zone',
    (tester) async {
      final zone = RiskZoneCatalog.byId('zone-masina')!;
      final repository = StoredByHazardRepository()
        ..stored['zone-masina'] = buildRiskResult(
          riskScore: 20,
          riskLevel: RiskLevel.medium,
        )
        ..stored['zone-masina--heat'] = buildRiskResult(
          id: 'zone-masina--heat',
          hazardType: 'Heat',
          riskScore: 88,
          riskLevel: RiskLevel.critical,
        );

      await tester.pumpWidget(
        buildMarkerHost(repository: repository, zone: zone),
      );
      await tester.pumpAndSettle();

      expect(find.text('Masina'), findsOneWidget);
      expect(
        _dotColor(tester),
        riskLevelColor(RiskLevel.critical),
      );
    },
  );

  testWidgets(
    'a zone with nothing stored stays neutral instead of green',
    (tester) async {
      final zone = RiskZoneCatalog.byId('zone-masina')!;

      await tester.pumpWidget(
        buildMarkerHost(
          repository: StoredByHazardRepository(),
          zone: zone,
        ),
      );
      await tester.pumpAndSettle();

      expect(_dotColor(tester), zoneNeutralColor);
    },
  );

  testWidgets(
    'tapping a zone opens its Zone Active Risks sheet',
    (tester) async {
      _useLargeView(tester);

      await tester.pumpWidget(
        buildMapHost(repository: StoredByHazardRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Masina'));
      await tester.pumpAndSettle();

      expect(find.byType(ZoneActiveRisksSheet), findsOneWidget);
      expect(
        find.text('No active risk identified in this zone right now.'),
        findsOneWidget,
      );
    },
  );
}
