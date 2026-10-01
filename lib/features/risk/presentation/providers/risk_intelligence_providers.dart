import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/flood_risk_input_exposure_enricher.dart';
import 'risk_live_providers.dart';

/// The canonical risk providers live in `risk_live_providers.dart`. This
/// library re-exports them so the existing import path keeps working without
/// defining a second, competing provider instance for the same services.
export 'risk_live_providers.dart'
    show riskExposureRepositoryProvider, riskIntelligenceServiceProvider;

/// Exposure enricher bound to the canonical exposure repository.
final floodRiskInputExposureEnricherProvider =
    Provider<FloodRiskInputExposureEnricher>((ref) {
  return FloodRiskInputExposureEnricher(
    repository: ref.read(
      riskExposureRepositoryProvider,
    ),
  );
});
