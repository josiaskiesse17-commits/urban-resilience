import 'hazard_definition.dart';
import 'hazard_series_utils.dart';
import 'hazard_type.dart';

/// Single source of truth for the hazard models of the application.
///
/// Every entry declares the environmental variables the hazard is assessed
/// with, the provider field each variable is read from, the trailing window
/// it is derived over, its unit and its weight, plus what the model cannot
/// assess with the data available today. The data sources build their
/// requests from this catalog, so a variable can never be scored without a
/// declared, verifiable source.
///
/// Weighting rule: the weights are fixed per hazard by the variable's role in
/// the process (the driver of the hazard, a contributing factor, an
/// aggravating factor). They are never adjusted to accommodate a variable
/// that happens to be available.
class HazardCatalog {
  const HazardCatalog._();

  /// Hazards assessed by the generic engine of this file.
  static const List<HazardType> genericHazards =
      <HazardType>[
    HazardType.landslide,
    HazardType.drought,
    HazardType.heat,
    HazardType.wildfire,
    HazardType.storm,
  ];

  /// The flooding assessment keeps its dedicated pipeline
  /// (`LiveFloodRiskService` → `FloodRiskCalculator` → `RiskIntelligenceService`).
  static bool usesLegacyPipeline(HazardType hazard) =>
      hazard == HazardType.flooding;

  static List<HazardType> get allHazards => HazardType.values;

  static HazardDefinition of(HazardType hazard) {
    switch (hazard) {
      case HazardType.flooding:
        return flooding;

      case HazardType.landslide:
        return landslide;

      case HazardType.drought:
        return drought;

      case HazardType.heat:
        return heat;

      case HazardType.wildfire:
        return wildfire;

      case HazardType.storm:
        return storm;
    }
  }

  /// Inventory of the flooding pipeline.
  ///
  /// The variables are listed here so the catalog describes *every* hazard of
  /// the app, but they are assessed by the legacy flooding calculator (which
  /// keeps its own weights), so the generic engine is not allowed to score
  /// them: they are marked informational.
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

  /// Landslide hazard.
  ///
  /// The model is driven by the two rainfall accumulations that trigger slope
  /// failures (short intense rainfall and multi-day saturation) and by the
  /// water content of the topsoil, which is what actually weakens the slope.
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

  /// Drought hazard.
  ///
  /// A rainfall deficit is only meaningful against the water balance of the
  /// same place and the same season, so the 30-day accumulation and the
  /// topsoil water content are compared with the same calendar month of the
  /// reference period, and the atmospheric demand (FAO reference
  /// evapotranspiration) is added because it empties the soil water that the
  /// other two variables describe.
  static const HazardDefinition drought = HazardDefinition(
    hazard: HazardType.drought,
    primaryFactorLabel: 'Rainfall deficit (30 d)',
    description:
        'Meteorological and soil-moisture drought, assessed from the 30-day '
        'rainfall deficit, the topsoil water content and the atmospheric '
        'water demand of the same month.',
    variables: <HazardVariableSpec>[
      HazardVariableSpec(
        name: 'rainfallAccumulation30d',
        label: 'Rainfall accumulation (30 d)',
        apiField: 'rain',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.sum30d,
        unit: 'mm',
        weight: 0.50,
        inverted: true,
        derived: true,
        derivationNote:
            'sum of the hourly rainfall of the last 30 days (720 hours)',
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
      HazardVariableSpec(
        name: 'referenceEvapotranspiration24h',
        label: 'Reference evapotranspiration (24 h)',
        apiField: 'et0_fao_evapotranspiration',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.sum24h,
        unit: 'mm',
        weight: 0.20,
        derived: true,
        derivationNote:
            'sum of the hourly FAO-56 reference evapotranspiration of the '
            'last 24 hours, computed by Open-Meteo from its model inputs',
      ),
    ],
    limitations: <String>[
      'The model stops at soil moisture and does not include surface water, '
          'reservoir levels or groundwater: no such source is integrated for '
          'these zones.',
      'No official drought classification (SPI/SPEI index) is published for '
          'these zones, so the references are statistical percentiles of the '
          'reference period of the same month and are labelled as such.',
    ],
  );

  /// Heat hazard.
  ///
  /// Humid tropical heat is not described by the dry-bulb temperature alone,
  /// so the model combines the daytime maximum of the air temperature, the
  /// daytime maximum of the apparent temperature (which includes humidity)
  /// and the night-time minimum, because a night that does not cool down is
  /// what makes consecutive hot days dangerous.
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

  /// Wildfire hazard.
  ///
  /// The provider used by this app does not expose a Fire Weather Index for
  /// these coordinates and returns no wildfire aerosol (`pm10_wildfires` is
  /// null for Kinshasa), so the model is built from the fuel-dryness and
  /// fire-weather variables that are actually available: topsoil water
  /// content, atmospheric drying power, the 14-day rainfall deficit and wind.
  static const HazardDefinition wildfire = HazardDefinition(
    hazard: HazardType.wildfire,
    primaryFactorLabel: 'Fire weather',
    description:
        'Fire-weather and fuel-dryness risk, assessed from topsoil water '
        'content, the atmospheric vapour pressure deficit, the 14-day '
        'rainfall deficit and the wind speed of the same calendar month of '
        'the reference period.',
    variables: <HazardVariableSpec>[
      HazardVariableSpec(
        name: 'soilMoisture0to7cm',
        label: 'Topsoil water content (0-7 cm)',
        apiField: 'soil_moisture_0_to_7cm',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.instant,
        unit: 'm³/m³',
        weight: 0.35,
        inverted: true,
      ),
      HazardVariableSpec(
        name: 'vapourPressureDeficit',
        label: 'Vapour pressure deficit',
        apiField: 'vapour_pressure_deficit',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.instant,
        unit: 'kPa',
        weight: 0.30,
      ),
      HazardVariableSpec(
        name: 'rainfallAccumulation14d',
        label: 'Rainfall accumulation (14 d)',
        apiField: 'rain',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.sum14d,
        unit: 'mm',
        weight: 0.20,
        inverted: true,
        derived: true,
        derivationNote:
            'sum of the hourly rainfall of the last 14 days (336 hours)',
      ),
      HazardVariableSpec(
        name: 'windSpeed10m',
        label: 'Wind speed at 10 m',
        apiField: 'wind_speed_10m',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.instant,
        unit: 'km/h',
        weight: 0.15,
      ),
    ],
    limitations: <String>[
      'This is a fire-weather and fuel-dryness risk, not a fire detection or '
          'fire-occurrence product: no active-fire or burned-area source is '
          'integrated.',
      'The Canadian Fire Weather Index is not provided for these coordinates '
          'by the current provider, and wildfire aerosol (pm10_wildfires) is '
          'returned as null, so neither could be used.',
      'Vegetation type, fuel load and land cover are not part of the model: '
          'no land-cover source is integrated yet.',
    ],
  );

  /// Storm hazard.
  ///
  /// Convective storms in the region are destructive through wind gusts and
  /// short-duration downpours, so the model is bounded by the wind gust, the
  /// sustained wind and the 6-hour rainfall of the same calendar month of the
  /// reference period. CAPE is reported as evidence but not scored, because
  /// ERA5 does not provide it for these coordinates and a convective index
  /// without a reference could not be compared with anything.
  static const HazardDefinition storm = HazardDefinition(
    hazard: HazardType.storm,
    primaryFactorLabel: 'Wind gusts',
    description:
        'Convective storm hazard, assessed from the strongest wind gust, the '
        'strongest sustained wind and the rainfall accumulation of the last '
        '6 hours, each compared with the same calendar month of the reference '
        'period.',
    variables: <HazardVariableSpec>[
      HazardVariableSpec(
        name: 'windGusts10mMax6h',
        label: 'Maximum wind gust (6 h)',
        apiField: 'wind_gusts_10m',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.max6h,
        unit: 'km/h',
        weight: 0.45,
        derived: true,
        derivationNote: 'strongest 10 m wind gust of the last 6 hours',
      ),
      HazardVariableSpec(
        name: 'windSpeed10mMax6h',
        label: 'Maximum wind speed (6 h)',
        apiField: 'wind_speed_10m',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.max6h,
        unit: 'km/h',
        weight: 0.25,
        derived: true,
        derivationNote:
            'strongest 10 m wind speed of the last 6 hours',
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
        derivationNote:
            'sum of the hourly rainfall of the last 6 hours',
      ),
      HazardVariableSpec(
        name: 'convectiveAvailablePotentialEnergy',
        label: 'Convective available potential energy',
        apiField: 'cape',
        source: HazardVariableSource.openMeteoWeather,
        window: HazardWindow.instant,
        unit: 'J/kg',
        weight: 0,
        informational: true,
        hasHistoricalReference: false,
      ),
    ],
    limitations: <String>[
      'CAPE is reported for information only: the ERA5 archive used for the '
          'reference period does not return it for these coordinates, so no '
          'statistical reference exists and it is excluded from the score.',
      'No lightning-detection or severe-weather-warning source is '
          'integrated, and no official storm threshold is applied.',
    ],
  );
}
