# ArcGIS Pro Model Builder Workflow

**Project:** Boston Cooling Deserts
**Software:** ArcGIS Pro 3.x · Spatial Statistics Toolbox
**Coordinate System:** NAD 1983 State Plane Massachusetts Mainland (FIPS 2001) — chosen for accurate linear distance in feet/meters

---

## Inputs
| Layer | Source | Format |
|-------|--------|--------|
| CHC point locations (n = 135) | MassGIS 2024 | Feature class (point) |
| MA Census Tracts | U.S. Census / MassGIS 2020 | Feature class (polygon) |
| ACS Population 2020 & 2022 | U.S. Census | Joined table |

## Step 1 — Buffer
- Tool: **Buffer** (Analysis Toolbox)
- Input: CHC point feature class
- Distance: `1 Mile`
- Side type: `FULL`
- Dissolve: `ALL`
- Output: `CHC_Buffer_1mi`

## Step 2 — Spatial Join
- Tool: **Spatial Join** (Analysis Toolbox)
- Target features: `CHC_Buffer_1mi`
- Join features: `MA_Census_Tracts_2020`
- Join operation: `JOIN_ONE_TO_ONE`
- Match option: `INTERSECT`
- Output: `CHC_Buffer_Tract_Join`

## Step 3 — Field Statistics
- Tool: **Summary Statistics** (Analysis Toolbox)
- Input: `CHC_Buffer_Tract_Join`
- Statistics: `SUM(TOTPOP_2020)`, `SUM(TOTPOP_2022)`, `MEAN(POP_DENSITY)`
- Case field: `TARGET_FID`
- Output: `CHC_Coverage_Summary`

## Validation Notes
- TARGET_FID range observed: 0 → 11+ tracts per buffer
- Zero-tract buffers flag CHC locations with no adjacent census coverage (data sparsity, water boundary, or peripheral location)
- Re-project before buffering. Linear units in WGS84 will be invalid.

## Next Phase
Replace Euclidean 1-mile buffers with **Network Analyst walksheds** (10-min walk, 20-min walk) for realistic pedestrian access during heat events.
