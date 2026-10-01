# SITUATION - urban_resilience (30/09/2026)

> Active branch: `feature/ai-risk` (HEAD `0f27466 ai feature and risk intelligence`)
> Compared against: `origin/main` (`e97d772 first commit`)
> Team workflow (REGLE.md): branch `type/nom-tache` -> commits `type: description` -> PR to `dev` -> mentor merges.

## 1. Where we are (summary)

The **auth + flood risk-intelligence + AI analyst** base works and is tested.
The generic **multi-hazard** extension (heat, storm, drought, landslide...) is
~95% implemented in the working tree but **NOT committed / NOT pushed**.
The **P0 blocker is FIXED**: factor <-> evidence consistency tests all pass.

- `flutter analyze`: **No issues found!**
- `flutter test`: **145 pass, 0 fail** (was 134 pass / 2 fail)

## 2. ALREADY DONE

### 2.1 Auth & account (commit `cbb8d47`)
- `auth_remote_data_source.dart`, `auth_repository.dart`, `app_user.dart`
- `auth_providers.dart`, screens login/register/forgot/verify/profile (903 lines)
- Widgets: auth_button/field/scaffold/password_field
- Tests auth_notifier/remote_data_source/firebase_repository: pass.

### 2.2 Flood Risk Intelligence (branches risk-intelligence + ai-risk)
- Domain flood: flood_risk_calculator/input/context, environmental_data,
  historical_baseline, exposure_profile/calculator, input_factory,
  input_exposure_enricher/extension, input_observation_enricher,
  historical_baseline_calculator/service, historical_statistics,
  rainfall_window_calculator, live_flood_risk_service, risk_analysis/analyst/
  evidence/measurement/factors/result/scenario/score_utils/zone.
- Data: open_meteo_risk_data_source, open_meteo_historical_flood_data_source,
  hourly_parser, firestore_result/exposure_repositories, firebase_ai_risk_analyst.
- Intelligence + UI: risk_intelligence_service.dart (736 lines),
  risk_live/intelligence/ai/exposure providers, risk_details_screen.dart
  (1760 lines: loads stored RiskResult, runs AI exactly once, no loop,
  explicit Retry/Recalculate, missing exposure shown explicitly, freshness).
- Passing tests: flood_risk_*, historical_*, live_flood_risk_*, open_meteo_*,
  risk_intelligence_service*, risk_scenario_service, risk_zone_catalog,
  risk_result_json/freshness, risk_details_screen_test.
### 2.3 Multi-hazard generic (done in working tree, NOT committed)

New untracked files + ~30 modified files (see `git status --short`):

- Types: hazard_type/definition, hazard_catalog.dart (430 lines),
  hazard_variable/variable_builder, hazard_series_utils
- Data: hazard_environmental/historical_data + sources,
  open_meteo_hazard_data_source + historical_data_source
- Baseline: hazard_baseline/calculator/service, historical_distribution
- Engine: hazard_risk_input/calculator (renormalised weights, no fake zero),
  hazard_risk_service/id, hazard_exposure_extractor, hazard_evidence_builder
- Shared model: risk_factor_score.dart (entries usedInScore/score=null/
  unavailableReason/componentNames), risk_factors.dart (legacy kept),
  risk_measurement_label.dart (window spelled out), risk_simulation.dart,
  risk_result_freshness.dart
- UI: risk_details_screen refactored (hazard selector, factor breakdown,
  evidence with unit/source/date + statistical ref + percentile, Not measured),
  widgets/risk_exposure_card, admin_shell/dashboard/risk (1034 lines)/alerts/
  observations, app_router/home/auth_providers updates
- Infra: firestore.rules, .firebaserc, firebase.json, ai-proxy/index.js,
  firebase_options.dart, main.dart, theme files
- New passing tests: hazard_catalog/variable_builder/series_utils/
  baseline_calculator/risk_calculator/risk_id/risk_service/evidence_builder,
  open_meteo_hazard_*, risk_details_hazard_switch, risk_measurement_label,
  risk_intelligence_service_hazard, admin_risk_*, home_zone_selection,
  observation_risk_calculator.

## 3. LEFT TO DO (prioritised)

### P0 - FIXED (was blocking): 2 red tests in risk_factor_evidence_consistency_test.dart

Fix applied on 30/09/2026 (user-side risk only, no admin/observations/map/AI-proxy changes):

1. `an unavailable factor is never presented as a measured zero` - FIXED:
   `HazardRiskCalculator` no longer emits a factor entry for a variable that
   was measured but carries no usable statistical reference (score == null).
   Its real value stays in the Evidence, and `RiskIntelligenceService
   calculateHazardRisk` now adds a `Not scored: <label> - ...` qualitative
   indicator naming the exclusion (measured-but-unscored != factor).
2. `a missing measurement becomes a gap, not a zero` - FIXED:
   `HazardRiskCalculator` now emits one `RiskFactorScore` per
   `input.gaps` entry (usedInScore=false, score=null, unavailableReason,
   label via `RiskMeasurementLabel.of`), so a missing input is an explicit
   unavailable factor while weights are renormalised over measured ones.

New tests added:
- `risk_simulation_test.dart` (What-If: same engine, starts from stored
  assessment, hazard-specific controls, human labels, no reference => not
  adjustable, determinism, stored result untouched).
- `risk_details_what_if_test.dart` (What-If card below AI, "not a forecast",
  scenario never invokes AI, real result stays on screen).
- extra case in `risk_factor_evidence_consistency_test.dart` (measured but
  unscored variable => evidence only + `Not scored:` indicator).

Do NOT merge until these tests stay green.

### P1 - Commit / push / PR (team rule)
- `git status` shows M (incl. MM app_router, AM admin_dashboard/risk_screen)
  and ~40 untracked. Do selective `git add`, clean `feat:`/`fix:` commits,
  push feature/ai-risk, open PR to `dev`, notify lead/mentor.
- Empty 0-line files in diff vs origin/main to fill or drop:
  app_constants.dart, api_client.dart, app_logger.dart,
  alerts_repository.dart, home_repository.dart, home_models.dart,
  map_repository.dart, map_models.dart, observations_repository.dart.

### P2 - Still stub / placeholder features
- alerts_screen.dart -> Text('Alerts') only; map_screen -> Text('Risk Map');
  observations_screen -> Text('Observations') only.
- citizenObservationRisk: observationsConnected=false ("not connected").
  -> wire real Firestore observations + zone filter.
- home_screen.dart (195 lines): zone selection tested but repo/models empty.
- Admin shell/dashboard/risk/alerts/observations exist but widget-tests only;
  check app_router navigation.

### P3 - Multi-hazard finishing touches
- historicalExposure for non-flood: "flood exposure is not a measurement".
  -> per-hazard historical baseline or explicit unavailable.
- risk_simulation.dart: expose per-hazard scenarios in UI.
- HazardExposureExtractor reuses flood exposure for all hazards: specialise.
- Check firestore.rules + risk_results/risk_zones ids vs RiskZoneCatalog
  and hazard_risk_id.dart. AI must only interpret evidence, never compute
  (validate ai-proxy/src/index.js contract with firebase_ai_risk_analyst).

### P4 - Hygiene
- README.md almost empty; document run/test/Firebase/Open-Meteo.
- .wrangler/ + .firebaserc untracked: decide versioning.
- After fix: full `flutter analyze` + `flutter test` green (now +134 -2).

## 4. Next concrete actions

1. [DONE] Fix hazard_risk_calculator + risk_intelligence_service for the 2
   P0 tests; consistency file is 7/7 green.
2. [DONE] Full analyze + test green (145 pass, 0 fail).
3. Fill or exclude the 9 empty files; minimal alerts/map/observations/home.
4. `git add -p`, clean commits, push, PR to dev.
5. Wire citizen observations + per-hazard exposure.

*Generated to resume the task list: done = section 2, left = sections 3-4.*
