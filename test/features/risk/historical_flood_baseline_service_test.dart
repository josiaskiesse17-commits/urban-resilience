import 'package:flutter_test/flutter_test.dart';

import 'package:urban_resilience/features/risk/domain/flood_historical_baseline.dart';
import 'package:urban_resilience/features/risk/domain/historical_flood_baseline_service.dart';
import 'package:urban_resilience/features/risk/domain/historical_flood_data.dart';
import 'package:urban_resilience/features/risk/domain/historical_flood_data_source.dart';

class _FakeHistoricalFloodDataSource implements HistoricalFloodDataSource {
  @override
  Future<HistoricalFloodData> fetch({
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return HistoricalFloodData(
      hourlyRainfallValues: [0, 1, 2, 3, 4, 5, 6, 8],
      riverDischargeValues: [100, 120, 150, 180, 220, 300],
      referencePeriodStart: startDate,
      referencePeriodEnd: endDate,
      rainfallSource: 'Fake',
      riverSource: 'Fake',
    );
  }
}

void main() {
  test('generates a historical flood baseline', () async {
    final service = HistoricalFloodBaselineService(
      dataSource: _FakeHistoricalFloodDataSource(),
    );

    final FloodHistoricalBaseline result = await service.generate(
      latitude: -4.30,
      longitude: 15.35,
      startDate: DateTime.utc(2018, 1, 1),
      endDate: DateTime.utc(2022, 7, 31),
    );

    expect(result.rainfallSampleCount, 8);

    expect(result.riverDischargeSampleCount, 6);

    expect(result.rainfallBaselineMmPerHour, greaterThanOrEqualTo(0));

    expect(result.riverDischargeBaselineM3s, greaterThan(0));
  });
}
