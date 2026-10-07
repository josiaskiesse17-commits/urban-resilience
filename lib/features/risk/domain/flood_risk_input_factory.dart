import 'flood_environmental_data.dart';
import 'flood_risk_context.dart';
import 'flood_risk_input.dart';

class FloodRiskInputFactory {
  const FloodRiskInputFactory();

  FloodRiskInput create({
    required FloodEnvironmentalData environmentalData,
    required FloodRiskContext context,
  }) {
    return FloodRiskInput(
      rainfallIntensityMmPerHour: environmentalData.rainfallLastHourMm,
      rainfallBaselineMmPerHour: context.rainfallBaselineMmPerHour,
      rainfallCriticalMmPerHour: context.rainfallCriticalMmPerHour,
      rainfallAccumulation6hMm: environmentalData.rainfallAccumulation6hMm,
      rainfallAccumulation6hBaselineMm:
          context.rainfallAccumulation6hBaselineMm,
      rainfallAccumulation6hCriticalMm:
          context.rainfallAccumulation6hCriticalMm,
      riverDischargeM3s: environmentalData.riverDischargeM3s,
      riverDischargeBaselineM3s: context.riverDischargeBaselineM3s,
      riverDischargeCriticalM3s: context.riverDischargeCriticalM3s,
      vulnerabilityScore: context.vulnerabilityScore,
      historicalExposureScore: context.historicalExposureScore,
      observationScore: context.observationScore,
      observationCount: context.observationCount,
      confirmedObservationCount: context.confirmedObservationCount,
    );
  }
}
