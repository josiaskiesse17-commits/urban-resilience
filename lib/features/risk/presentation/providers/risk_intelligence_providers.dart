import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/flood_risk_input_exposure_enricher.dart';
import 'risk_live_providers.dart';

export 'risk_live_providers.dart'
    show riskExposureRepositoryProvider, riskIntelligenceServiceProvider;

final floodRiskInputExposureEnricherProvider =
    Provider<FloodRiskInputExposureEnricher>((ref) {
      return FloodRiskInputExposureEnricher(
        repository: ref.read(riskExposureRepositoryProvider),
      );
    });
