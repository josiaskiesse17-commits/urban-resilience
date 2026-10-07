# Investigation Report: Urban Resilience Flutter App Risk Score Regression

## 1. Root Cause

The primary root cause of scores becoming zero when vulnerability/historical data is unavailable is **`FloodRiskExposureProfile.fromJson()`** (lib/features/risk/domain/flood_risk_exposure_profile.dart:52-70) which uses `?? 0` for all parsed fields including `historicalFloodExposureScore`. When a Firestore `risk_zones` document exists but lacks a field (e.g., `historicalFloodExposureScore`), it defaults to `0` instead of remaining `null`.

Additionally, the **What-If (simulation) feature is incorrectly disabled** when vulnerability or historical exposure are missing, due to a hard check in `RiskSimulationService._simulateFlood()` (lib/features/risk/domain/risk_simulation.dart:394-396) and an English `unavailableReason` in `modelFrom()` (lines 265-280).

The risk calculators (`FloodRiskCalculator`, `HazardRiskCalculator`) correctly handle null values by excluding them from the weighted average and renormalizing weights — **the calculation logic itself is not the problem**.

---

## 2. Data-Flow Table

| Component | Source | Current Value/Path | Reaches Calculator? | Problem |
|-----------|--------|-------------------|---------------------|---------|
| **Hazard** | Open-Meteo API → `OpenMeteoRiskDataSource` → `FloodEnvironmentalData` → `FloodRiskInputFactory` → `FloodRiskCalculator` | Live rainfall/river data, correctly parsed | **YES** | None — hazard data flows normally |
| **Vulnerability** | Firestore `risk_zones` → `FirestoreRiskExposureRepository` → `FloodRiskExposureProfile.fromJson()` → `FloodRiskInputExposureEnricher` → `FloodRiskInput` | **Becomes 0 if field missing** (due to `?? 0` in fromJson) | **YES** (but as 0, not null) | Missing field → 0 instead of null |
| **Historical Exposure** | Firestore `risk_zones` → `FirestoreRiskExposureRepository` → `FloodRiskExposureProfile.fromJson()` → `FloodRiskInputExposureEnricher` → `FloodRiskInput` | **Becomes 0 if field missing** (due to `?? 0` in fromJson) | **YES** (but as 0, not null) | Missing field → 0 instead of null |
| **Observations** | Firestore `observations` → `ObservationsRepository.getConfirmedForContext()` → `ObservationRiskCalculator` → `FloodRiskInputObservationEnricher` → `FloodRiskInput` | Confirmed observations only, correctly scored | **YES** | None — works as intended |

---

## 3. Confirmed Zero-Producing Code

### 3.1 `FloodRiskExposureProfile.fromJson()` — Missing Fields Become 0
**File:** `lib/features/risk/domain/flood_risk_exposure_profile.dart`  
**Function:** `fromJson` (lines 52-70)  
**Relevant code:**
```dart
factory FloodRiskExposureProfile.fromJson(Map<String, dynamic> json) {
  return FloodRiskExposureProfile(
    zoneId: json['zoneId'] as String,
    populationExposureScore: (json['populationExposureScore'] as num?)?.toDouble() ?? 0,
    infrastructureExposureScore: (json['infrastructureExposureScore'] as num?)?.toDouble() ?? 0,
    drainageVulnerabilityScore: (json['drainageVulnerabilityScore'] as num?)?.toDouble() ?? 0,
    criticalFacilityExposureScore: (json['criticalFacilityExposureScore'] as num?)?.toDouble() ?? 0,
    historicalFloodExposureScore: (json['historicalFloodExposureScore'] as num?)?.toDouble() ?? 0,  // ← PROBLEM
    source: json['source'] as String?,
    updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'] as String),
  );
}
```
**Why it produces 0:** The `?? 0` fallback treats missing Firestore fields as 0. A missing `historicalFloodExposureScore` field becomes 0 instead of null.  
**Correct behavior:** Missing fields should remain `null` (or the field should be optional in the model). The `vulnerabilityScore` getter computes from sub-fields; if sub-fields are missing, they should be null, not 0.

---

### 3.2 `RiskSimulationService._simulateFlood()` — What-If Blocked When Data Missing
**File:** `lib/features/risk/domain/risk_simulation.dart`  
**Function:** `_simulateFlood` (lines 394-396)  
**Relevant code:**
```dart
if (vulnerabilityScore == null || historicalExposureScore == null) {
  return null;
}
```
**Why it produces 0 (indirectly):** Returns `null` outcome, causing UI to show "unavailable" instead of calculating with available components.  
**Correct behavior:** Should calculate with available components (hazard + observations), renormalizing weights per requirements.

---

### 3.3 `RiskSimulationService.modelFrom()` — English Unavailable Message
**File:** `lib/features/risk/domain/risk_simulation.dart`  
**Function:** `modelFrom` (lines 265-280)  
**Relevant code:**
```dart
final factorDataMissing = vulnerabilityScore == null || historicalExposureScore == null;

return RiskSimulationModel(
  // ...
  unavailableReason: missingFloodReference
      ? 'The stored flooding assessment does not contain the complete rainfall and river reference...'
      : factorDataMissing
          ? 'The stored assessment does not contain complete vulnerability and historical exposure data, so no reliable scenario score can be computed.'  // ← ENGLISH
          : adjustableCount == 0
              ? 'None of the stored measurements...'
              : null,
  // ...
);
```
**Why it's wrong:** Message is in English, not French. Also incorrectly blocks What-If when only vulnerability/historical are missing.  
**Correct behavior:** What-If must work with available components; message must be French.

---

### 3.4 `RiskSimulationService._factorScore()` — Legitimate 0 Treated as Missing
**File:** `lib/features/risk/domain/risk_simulation.dart`  
**Function:** `_factorScore` (lines 450-452)  
**Relevant code:**
```dart
return storedLegacyValue != null && storedLegacyValue > 0
    ? storedLegacyValue
    : null;
```
**Why it produces 0 (indirectly):** A legitimate source value of 0 is treated as null/unavailable.  
**Correct behavior:** Should distinguish `null` (unavailable) from `0` (valid score). Use `storedLegacyValue != null` only.

---

## 4. Risk Calculator Diagnosis

Both `FloodRiskCalculator` and `HazardRiskCalculator` correctly implement the required weight renormalization:

### Case A: All Data Available
- Components: hazard(0.40), vulnerability(0.25), historical(0.15), observations(0.20)
- Total weight = 1.0 → weighted average computed normally ✓

### Case B: Vulnerability Null
- Components: hazard(0.40), historical(0.15), observations(0.20)
- Total weight = 0.75 → each weight effectively renormalized (0.40/0.75, 0.15/0.75, 0.20/0.75) ✓
- `FloodRiskCalculator` lines 73-76, 83-84; `HazardRiskCalculator` lines 146-157, 174-181

### Case C: Historical Null
- Components: hazard(0.40), vulnerability(0.25), observations(0.20)
- Total weight = 0.85 → renormalized (0.40/0.85, 0.25/0.85, 0.20/0.85) ✓

### Case D: Both Null
- Components: hazard(0.40), observations(0.20)
- Total weight = 0.60 → renormalized (0.40/0.60, 0.20/0.60) ✓

**The calculator logic is correct.** The problem is upstream: null values never reach the calculator because they're converted to 0 in `FloodRiskExposureProfile.fromJson()`.

---

## 5. What-If Diagnosis

| Aspect | Detail |
|--------|--------|
| **File** | `lib/features/risk/domain/risk_simulation.dart` |
| **Function** | `_simulateFlood` (lines 338-414) and `modelFrom` (lines 192-295) |
| **Current Condition** | `if (vulnerabilityScore == null || historicalExposureScore == null) return null;` |
| **Current English Message** | `'The stored assessment does not contain complete vulnerability and historical exposure data, so no reliable scenario score can be computed.'` |
| **Why Wrong** | 1. Blocks What-If when only optional components missing<br>2. Message is English, not French<br>3. Legitimate 0 treated as missing in `_factorScore` |
| **Intended Behavior** | What-If must work with hazard + observations when vulnerability/historical are null. Weights renormalize. French message if truly unavailable (e.g., no hazard data). |

---

## 6. Confirmed Regressions

| # | Regression | File | Function |
|---|------------|------|----------|
| 1 | Missing `historicalFloodExposureScore` in Firestore becomes 0 instead of null | `flood_risk_exposure_profile.dart` | `fromJson` (line 64) |
| 2 | Missing sub-fields (populationExposureScore, etc.) become 0, corrupting computed `vulnerabilityScore` | `flood_risk_exposure_profile.dart` | `fromJson` (lines 55-62) |
| 3 | What-If simulation unavailable when vulnerability/historical missing | `risk_simulation.dart` | `_simulateFlood` (lines 394-396) |
| 4 | What-If shows English message when vulnerability/historical missing | `risk_simulation.dart` | `modelFrom` (lines 277-280) |
| 5 | Legitimate 0 vulnerability/historical score treated as unavailable in What-If | `risk_simulation.dart` | `_factorScore` (lines 450-452) |

**Not regressed (working correctly):**
- Hazard data flow (API → calculator)
- Observation data flow (confirmed only)
- Weight renormalization in calculators
- Risk calculation with all/partial data (when nulls reach it)

---

## 7. Files That Need Modification

1. **`lib/features/risk/domain/flood_risk_exposure_profile.dart`** — Fix `fromJson` to preserve null for missing fields
2. **`lib/features/risk/domain/risk_simulation.dart`** — Fix `_simulateFlood` to allow null vulnerability/historical; fix `modelFrom` unavailable reason (French, correct logic); fix `_factorScore` to treat 0 as valid

---

## 8. Minimal Fix Plan

### Step 1: Fix `FloodRiskExposureProfile.fromJson()`
- Change all `?? 0` to `?? null` (or remove fallback entirely, letting the field be nullable in the model)
- Make model fields nullable: `double? populationExposureScore`, etc.
- Update `vulnerabilityScore` getter to handle null sub-fields (return null if any component null)

### Step 2: Fix `RiskSimulationService._simulateFlood()`
- Remove the `if (vulnerabilityScore == null || historicalExposureScore == null) return null;` check
- Allow calculation with hazard + observations only; `FloodRiskCalculator` already handles null correctly

### Step 3: Fix `RiskSimulationService.modelFrom()`
- Change `factorDataMissing` logic: only block if hazard data missing, not vulnerability/historical
- Change `unavailableReason` to French: `'Aucune variable environnementale...'` (reuse existing French message pattern)
- Remove the vulnerability/historical check from `unavailableReason`

### Step 4: Fix `RiskSimulationService._factorScore()`
- Change `storedLegacyValue != null && storedLegacyValue > 0` to `storedLegacyValue != null`
- Preserve legitimate 0 values

### Step 5: Verify No Other `?? 0` Fallbacks in Exposure Path
- Search for other `?? 0` in exposure/profile parsing — confirm only `flood_risk_exposure_profile.dart` has this issue

---

## Summary

The regression stems from **one upstream parsing issue** (`FloodRiskExposureProfile.fromJson` converting missing fields to 0) and **one downstream What-If gate** (`RiskSimulationService` incorrectly requiring all four components). The core risk calculators are correctly implemented and would produce the right renormalized weights if they received proper null values.

**No changes needed to:** hazard pipeline, observation pipeline, risk calculators, weight logic, UI display (except What-If message).