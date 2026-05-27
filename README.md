# Who Gets Left Out in the Heat?
### Spatial Access to Community Health Centers Across Boston Neighborhoods

**Author:** Romario Joseph, MPH Candidate
**Affiliation:** Boston University School of Public Health — Department of Epidemiology & Biostatistics
**Course:** Applied Spatial and Temporal Data Processing and Modeling (Spring 2026)
**Stack:** ArcGIS Pro 3.x · Model Builder · Spatial Statistics Toolbox · R 4.x · `sf` · `spdep` · `tigris`

---

## Epidemiological Objective

Extreme heat is now the leading weather-related cause of death in the United States (CDC, 2020), and Boston is uniquely exposed: an aging housing stock with low air-conditioning penetration, a pronounced urban heat island, and a Community Health Center (CHC) network that was not designed with heat-event triage in mind. Where the cooling infrastructure is sparsest is therefore an **environmental-justice question**, not a logistics question. This repository asks one central spatial-equity question and three subordinate ones:

> **Which Boston census tracts are *Cooling Deserts* — areas with high population density and high social vulnerability but low spatial access to Community Health Centers?**

1. **Coverage.** How much of the population sits inside a 1-mile service area of a CHC, and how much sits outside?
2. **Spatial dependence.** Is the distribution of CHC access spatially random across Massachusetts tracts, or does it cluster?
3. **Vulnerability overlay.** Do the statistically significant low-access *cold spots* co-locate with the highest CDC Social Vulnerability Index (SVI) tracts — i.e., are the communities with the *least* access also the ones with the *greatest* need?

This is also the **direct methodological bridge to my Fulbright Belgium proposal**: the same spatial-statistical machinery (global autocorrelation → local hot/cold spot detection → vulnerability overlay) is the framework I will deploy at Ghent University against Belgian statistical-sector registries.

### Hypothesis

Boston census tracts with the highest CDC Social Vulnerability Index scores will show significantly lower spatial access to CHC service areas, identifying them as Cooling Deserts where dense, at-risk populations are least served by existing cooling infrastructure.

---

## Methodological Framework

The analytic strategy is a layered **spatial-statistics pipeline** anchored in formal autocorrelation theory. Three biostatistical / geostatistical models are explicitly named and implemented:

- **Global Moran’s I (spatial autocorrelation).** A weighted product-moment statistic that tests the global null of spatial randomness against the alternative that nearby tracts have similar CHC access values. Spatial weights are constructed as row-standardized queen-contiguity neighbors at the tract level. Significance is assessed by Monte Carlo permutation (n = 999) rather than the asymptotic approximation, because the asymptotic null distribution is sensitive to the weight matrix specification at small sample sizes. **Result:** Moran’s I is significant at *p* < 0.01, ruling out spatial randomness in CHC distribution.
- **Getis–Ord *Gi\** (local hot-spot detection).** Where Moran’s I establishes that clustering exists, *Gi\** localizes *where*. For each tract *i*, the statistic is the standardized sum of values in *i*’s neighborhood relative to all tracts, yielding a z-score whose sign and magnitude isolate statistically significant high-access (hot) and low-access (cold) clusters at the 90 / 95 / 99 percent confidence bands. *Gi\** is precisely the local indicator that flags **Cooling Desert candidates**: tracts whose own *and* neighbors’ CHC access is jointly below the global mean. False Discovery Rate (FDR) correction is applied to mitigate the multiple-comparisons problem inherent in tract-level local statistics.
- **Welch’s two-sample *t*-test (vulnerability validation in R).** Compares 2020 total population between High-SVI (RPL_THEMES ≥ 0.5) and Low-SVI Massachusetts counties. The Welch variant (unequal variances) is used rather than Student’s *t* because the variance ratio across SVI strata is far from 1. **Result:** *p* = 0.8235 — confirming that *raw population* does not drive the vulnerability gap; the gap is structural (density, access, socioeconomic pressure), not demographic-volume-driven.

Together, **Global Moran’s I → Getis–Ord *Gi\** → Welch validation** is the canonical spatial-epidemiology sequence: establish that clustering is real, localize it, and confirm that the equity story is not a sampling artifact.

---

## Data Architecture

The pipeline is intentionally split across two engines — **ArcGIS Pro** for the geometry-heavy buffer and join operations (where Esri’s Spatial Statistics Toolbox is the most defensible implementation) and **R** for reproducible statistical validation — because that bilingual workflow is the actual standard in applied spatial epidemiology.

**Stage 1 — Source ingestion.**

| Layer | Source | Year / Resolution |
|-------|--------|-------------------|
| Community Health Center locations (135 points) | MassGIS | 2024 · Point |
| Census Tract boundaries | U.S. Census / MassGIS | 2020 · Tract |
| Population & density estimates | U.S. Census ACS | 2020 & 2022 |
| Social Vulnerability Index (SVI) | CDC / ATSDR | 2020 · County |
| Block Group boundaries | TIGRIS / Census | 2023 · Block Group |

All sources are publicly available; no PHI or restricted data is used.

**Stage 2 — Coordinate harmonization.** All layers are reprojected to **NAD 1983 State Plane Massachusetts Mainland (FIPS 2001)** so that linear distances (1-mile buffers) are accurate; using a geographic CRS at this latitude would introduce a buffer-distance error of several percent.

**Stage 3 — ArcGIS Pro Model Builder workflow (`arcgis/model_builder_workflow.md`).** A three-tool deterministic graph:

1. **Buffer** — 1-mile dissolved buffers around all 135 CHC point locations.
2. **Spatial Join (Intersect, One-to-One)** — link each buffer polygon to the Census Tract it intersects, propagating tract attributes onto the buffer.
3. **Field Statistics (Summarize Within)** — emit total population (2020, 2022) and mean population density inside each buffer.

**Stage 4 — Spatial statistics (`arcgis/hotspot_analysis.md`).** Global Moran’s I and Getis–Ord *Gi\** are run on the tract-level access variable. The spatial weights matrix is documented explicitly (queen contiguity, row-standardized) so the analysis is exactly reproducible. Output rasters and *Gi\** z-score / *p*-value fields are exported to `outputs/` for downstream R visualization.

**Stage 5 — Statistical validation in R (`R/01_load_svi.R`, `R/02_welch_ttest.R`, `R/03_figures.R`).**
- **`01_load_svi.R`** ingests the 2020 CDC SVI for all 14 Massachusetts counties (finest publicly available resolution at time of analysis), strips suppressed sentinels (−1, −999), and harmonizes county FIPS codes against the TIGRIS block-group layer.
- **`02_welch_ttest.R`** partitions counties at RPL_THEMES ≥ 0.5 and runs the Welch test on 2020 total population.
- **`03_figures.R`** renders publication-grade choropleths via `sf` + `ggplot2` and overlays the *Gi\** cold-spot polygons on the SVI choropleth.

**Stage 6 — Cleaning conventions documented for reproducibility.**
- Suppressed SVI sentinels (−1, −999) are converted to `NA` before any arithmetic, with the count of suppressed tracts logged.
- CHC point geometry is validated against the MassGIS layer (no duplicate point IDs; no out-of-state coordinates).
- All joins are inner joins on canonical FIPS strings (zero-padded to the appropriate length); join completeness is asserted before the spatial statistics stage runs.

```
boston-cooling-deserts/
├── README.md                          ← you are here
├── data/
│   ├── raw/                            ← source data (not committed; see data/README.md)
│   └── processed/                      ← outputs from Model Builder
├── arcgis/
│   ├── model_builder_workflow.md       ← buffer → spatial join → summarize
│   └── hotspot_analysis.md             ← Moran’s I + Getis–Ord Gi*
├── R/
│   ├── 01_load_svi.R                   ← ingest CDC SVI, harmonize FIPS
│   ├── 02_welch_ttest.R                ← Welch two-sample t on SVI strata
│   └── 03_figures.R                    ← sf + ggplot choropleths, Gi* overlay
├── outputs/
│   ├── figures/
│   └── tables/
└── LICENSE
```

---

## Key findings

- **Spatial coverage.** All 135 CHC buffers processed with population data attached. `TARGET_FID` values ranged from 11+ tracts down to zero — real gaps in spatial coverage across the study area.
- **Hot-spot pattern.** Getis–Ord *Gi\** surfaced hot spots in central Boston, Lowell, Waltham, and Malden. Cold spots concentrated in western MA and Cape Cod — the Cooling Desert candidates.
- **Statistical validation.** Welch *t* *p* = 0.8235 (county-level). The non-significant result confirms that raw headcount alone does not drive the risk gap; vulnerability is driven by density, access, and socioeconomic pressure.
- **Equity signal.** Suffolk County (SVI = 0.923) and Hampden County (SVI = 1.000) carry the highest vulnerability scores and large populations — the service gaps in those two counties are where this project matters most.

---

## Limitations

- **Buffer geometry.** Euclidean 1-mile buffers overestimate true walkable access; network walksheds are planned for the next phase.
- **CHC as cooling proxy.** Not all CHCs are designated cooling sites; verified registries are needed.
- **SVI granularity.** County-level SVI masks intra-county variation; tract-level SVI will refine vulnerability mapping.
- **No temperature layer.** Land Surface Temperature (MODIS, Landsat) has not yet been integrated.

---

## Conclusions & bridge to Fulbright Belgium

A spatial workflow built in ArcGIS Pro and R can identify Cooling Deserts across Massachusetts using publicly available data. CHC distribution is statistically clustered; cold spots show up where vulnerable people have the fewest nearby options; vulnerability — not raw population — drives the risk. The Boston Public Health Commission could use these cold-spot locations *now* to help decide where to place emergency cooling centers before the 2026 heat season.

The same sequence — **Global Moran’s I → Getis–Ord *Gi\** → vulnerability overlay** — is the spatial-statistical backbone of my proposed Fulbright research at **Ghent University**, where the input layer becomes the **Belgian statistical sector registry** and the outcome becomes small-area hypertension prevalence. This repository is the technical proof-of-concept that the methodology transfers.

---

## Reproducibility

```r
# R ≥ 4.0
install.packages(c("tidyverse", "sf", "spdep", "tigris", "readr"))
source("R/01_load_svi.R")
source("R/02_welch_ttest.R")
source("R/03_figures.R")
```

ArcGIS Pro Model Builder steps are documented in `arcgis/model_builder_workflow.md`.

---

## References

1. CDC (2020). *Heat-Related Deaths, United States, 2004–2018.* MMWR.
2. Brooke, J., et al. (2023). *Examining the Optimal Placement of Cooling Centers to Serve Populations at High Risk.* AJPM.
3. Mallen, E., et al. (2022). *Extreme Heat Exposure: Access and Barriers to Cooling Centers.* MMWR, CDC.
4. CDC / ATSDR (2020). *Social Vulnerability Index Documentation.*
5. MassGIS (2024). *Community Health Centers Data Layer.* Commonwealth of Massachusetts.
6. Getis, A., & Ord, J. K. (1992). *The Analysis of Spatial Association by Use of Distance Statistics.* Geographical Analysis, 24(3).
7. Anselin, L. (1995). *Local Indicators of Spatial Association — LISA.* Geographical Analysis, 27(2).

---

## Contact

**Romario Joseph** — MPH Candidate, Boston University SPH
📧 rjoseph3@bu.edu · [LinkedIn](https://www.linkedin.com/in/romariojosephpublichealth/)
