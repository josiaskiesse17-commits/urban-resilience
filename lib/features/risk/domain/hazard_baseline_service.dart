import 'hazard_baseline.dart';
import 'hazard_baseline_calculator.dart';
import 'hazard_catalog.dart';
import 'hazard_historical_data_source.dart';
import 'hazard_type.dart';


class HazardBaselineService {
  const HazardBaselineService({
    required this.dataSource,
    this.calculator = const HazardBaselineCalculator(),
  });

  final HazardHistoricalDataSource dataSource;
  final HazardBaselineCalculator calculator;

  Future<HazardBaseline> generate({
    required HazardType hazard,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final definition = HazardCatalog.of(hazard);

    final data = await dataSource.fetch(
      hazard: hazard,
      latitude: latitude,
      longitude: longitude,
      startDate: startDate,
      endDate: endDate,
    );

    return calculator.calculate(
      definition: definition,
      data: data,
    );
  }
}
