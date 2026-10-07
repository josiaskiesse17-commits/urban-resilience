import 'hazard_definition.dart';
import 'hazard_series_utils.dart';
import 'hazard_type.dart';

class HazardCatalog {
  const HazardCatalog._();

  static const List<HazardType> genericHazards = <HazardType>[
    HazardType.landslide,
    HazardType.heat,
  ];

  static bool usesLegacyPipeline(HazardType hazard) =>
      hazard == HazardType.flooding;

  static List<HazardType> get allHazards => HazardType.values;

  static HazardDefinition of(HazardType hazard) {
    switch (hazard) {
      case HazardType.flooding:
        return flooding;

      case HazardType.landslide:
        return landslide;

      case HazardType.heat:
        return heat;
    }
  }

  static const HazardDefinition flooding = HazardDefinition(
    hazard: HazardType.flooding,
    primaryFactorLabel: 'Rainfall',
    legacyPipeline: true,
    description:
        'Pluvial and river flooding. Assessed by the original flooding '
        'pipeline with the weights hazard 0.40 (rainfall intensity 0.40, '
        '6 h accumulation 0.30, river discharge 0.30), vulnerability 0.25, '
        'historical exposure 0.15 and observations 0.20.',
    variables: <HazardVariableSpec>[
      HazardVariableSpec(
        name: 'rainfallIntensity',
        label: 'Rainfall intensity (last hour)',
        apiField: 'rain',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.instant,
        unit: 'mm/h',
        weight: 0.40,
        informational: true,
      ),
      HazardVariableSpec(
        name: 'rainfallAccumulation6h',
        label: 'Rainfall accumulation (6 h)',
        apiField: 'rain',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.sum6h,
        unit: 'mm',
        weight: 0.30,
        derived: true,
        derivationNote: 'sum of the hourly rainfall of the last 6 hours',
        informational: true,
      ),
      HazardVariableSpec(
        name: 'riverDischarge',
        label: 'River discharge',
        apiField: 'river_discharge',
        source: HazardVariableSource.openMeteoFlood,
        window: HazardWindow.instant,
        unit: 'm³/s',
        weight: 0.30,
        informational: true,
      ),
    ],
    seasonalReference: false,
    limitations: <String>[
      'GloFAS resolves the river network at roughly 5 km. At the centre of '
          'some communes the nearest grid cell is a small watercourse instead '
          'of the Congo river, so the absolute discharge is small for those '
          'zones. The score stays comparable inside a zone because the '
          'reference is computed from the same grid cell.',
      'Rainfall and river reference values are computed over the whole '
          'reference period and are not season specific.',
    ],
  );

  static const HazardDefinition landslide = HazardDefinition(
    hazard: HazardType.landslide,
    primaryFactorLabel: 'Rainfall (24 h)',
    description:
        'Rainfall-triggered slope instability. Multi-day saturation and '
        'short-duration intensity are the two rainfall drivers recorded in '
        'the literature on tropical urban landslides, and topsoil water '
        'content is the state variable they change.',
    variables: <HazardVariableSpec>[
      HazardVariableSpec(
        name: 'rainfallAccumulation24h',
        label: 'Rainfall accumulation (24 h)',
        apiField: 'rain',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.sum24h,
        unit: 'mm',
        weight: 0.45,
        derived: true,
        derivationNote: 'sum of the hourly rainfall of the last 24 hours',
      ),
      HazardVariableSpec(
        name: 'rainfallAccumulation72h',
        label: 'Rainfall accumulation (72 h)',
        apiField: 'rain',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.sum72h,
        unit: 'mm',
        weight: 0.25,
        derived: true,
        derivationNote: 'sum of the hourly rainfall of the last 72 hours',
      ),
      HazardVariableSpec(
        name: 'soilMoisture0to7cm',
        label: 'Topsoil water content (0-7 cm)',
        apiField: 'soil_moisture_0_to_7cm',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.instant,
        unit: 'm³/m³',
        weight: 0.30,
        inverted: true,
      ),
    ],
    limitations: <String>[
      'Slope, elevation, lithology and land cover are not part of the model: '
          'no terrain data source is integrated yet, and terrain values are '
          'never invented for a zone.',
      'Soil moisture comes from the ERA5/ERA5-Land soil model (a modelled '
          'variable, not a station measurement), and its spatial resolution '
          'is coarser than an urban commune.',
    ],
  );

  static const HazardDefinition heat = HazardDefinition(
    hazard: HazardType.heat,
    primaryFactorLabel: 'Heat',
    description:
        'Heat stress over the last 24 hours, assessed from the maximum air '
        'temperature, the maximum apparent temperature and the night-time '
        'minimum, each compared with the same calendar month of the reference '
        'period.',
    variables: <HazardVariableSpec>[
      HazardVariableSpec(
        name: 'temperature2mMax24h',
        label: 'Maximum air temperature (24 h)',
        apiField: 'temperature_2m',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.max24h,
        unit: '°C',
        weight: 0.45,
        derived: true,
        derivationNote:
            'highest hourly 2 m air temperature of the last 24 hours',
      ),
      HazardVariableSpec(
        name: 'apparentTemperatureMax24h',
        label: 'Maximum apparent temperature (24 h)',
        apiField: 'apparent_temperature',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.max24h,
        unit: '°C',
        weight: 0.40,
        derived: true,
        derivationNote:
            'highest hourly apparent temperature of the last 24 hours; '
            'apparent temperature is derived by Open-Meteo from temperature, '
            'humidity, wind and radiation',
      ),
      HazardVariableSpec(
        name: 'temperature2mMin24h',
        label: 'Night-time minimum temperature (24 h)',
        apiField: 'temperature_2m',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.min24h,
        unit: '°C',
        weight: 0.15,
        derived: true,
        derivationNote:
            'lowest hourly 2 m air temperature of the last 24 hours',
      ),
    ],
    limitations: <String>[
      'No official heat-health warning threshold is used: the references are '
          'the statistics of the same calendar month of the reference period.',
      'The model describes heat exposure, not health impact: it contains no '
          'mortality, morbidity or vulnerability-to-heat data.',
    ],
  );
}
