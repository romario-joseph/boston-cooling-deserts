# Who Gets Left Out in the Heat?
### Spatial access to Community Health Centers across Boston neighborhoods

**Author:** Romario Joseph, MPH Candidate
**Affiliation:** Boston University School of Public Health, Department of Epidemiology & Biostatistics
**Course:** Applied Spatial and Temporal Data Processing and Modeling (Spring 2026)
**Stack:** ArcGIS Pro 3.x, Model Builder, Spatial Statistics Toolbox, R 4.x, `sf`, `spdep`, `tigris`

I built this project as my course capstone, but the methodology is also the technical proof-of-concept for my Fulbright Belgium proposal. The same spatial-statistics chain I run here on Massachusetts census tracts is what I plan to run at Ghent University on Belgian statistical sectors.

## Epidemiological Objective

Extreme heat is now the leading weather-related cause of death in the United States (CDC, 2020), and Boston is unusually exposed: an aging housing stock with low air-conditioning penetration, a pronounced urban heat island, and a Community Health Center (CHC) network that was not designed with heat-event triage in mind. Where the cooling infrastructure is sparsest is therefore an environmental-justice question, not a logistics question.

The central question I am asking is:

> Which Boston census tracts are *Cooling Deserts*: areas with high population density and high social vulnerability but low spatial access to Community Health Centers?

Underneath that, three sub-questions:

1. Coverage. How much of the population sits inside a 1-mile service area of a CHC, and how much sits outside?
2. Spatial dependence. Is the distribution of CHC access spatially random across Massachusetts tracts, or does it cluster?
3. Vulnerability overlay. Do the statistically significant low-access cold spots co-locate with the highest CDC Social Vulnerability Index (SVI) tracts? Put differently: are the communities with the least access also the ones with the greatest need?

### Hypothesis

Boston census tracts with the highest CDC Social Vulnerability Index scores will show significantly lower spatial access to CHC service areas, identifying them as Cooling Deserts where dense, at-risk populations are least served by existing cooling infrastructure.

## Methodological Framework

The analytic strategy is a layered spatial-statistics pipeline. There are three named tests, and I tried to keep each one defensible enough that a methods reviewer can pick at it.

**Global Moran's I (spatial autocorrelation).** A weighted product-moment statistic that tests the global null of spatial randomness against the alternative that nearby tracts have similar CHC access values. I build a row-standardized queen-contiguity weights matrix at the tract level. Significance is assessed by 999 Monte Carlo permutations rather than the asymptotic normal approximation, because the asymptotic null is sensitive to the weights specification at small sample sizes. In my run, Moran's I came out significant at p < 0.01, which rules out spatial randomness in CHC distribution.

**Getis-Ord Gi\* (local hot-spot detection).** Moran's I tells me clustering exists; Gi\* tells me where. For each tract *i*, Gi\* is the standardized sum of values in the neighborhood of *i* relative to all tracts. The output is a z-score whose sign and magnitude isolate statistically significant high-access (hot) and low-access (cold) clusters at the 90 / 95 / 99 percent confidence bands. Gi\* is precisely the local statistic that flags Cooling Desert candidates: tracts whose own values *and* whose neighbors' values are jointly below the global mean. I apply False Discovery Rate (FDR) correction to mitigate the multiple-comparisons problem inherent in tract-level local statistics.

**Welch's two-sample t-test (vulnerability validation in R).** I compare 2020 total population between High-SVI (RPL_THEMES at or above 0.5) and Low-SVI Massachusetts counties. I use the Welch variant (unequal variances) rather than Student's t because the variance ratio across SVI strata is far from 1. Result: p = 0.8235. That non-significant result is the point. It confirms that raw population does not drive the vulnerability gap. The gap is structural (density, access, socioeconomic pressure), not a demographic-volume artefact.

Put together, Global Moran's I, Getis-Ord Gi\*, and Welch validation is the canonical spatial-epidemiology sequence: establish that clustering is real, localize it, and confirm that the equity story is not a sampling artefact.

## Data Architecture

I deliberately split the pipeline across two engines. ArcGIS Pro handles the geometry-heavy buffer and join operations, because the Esri Spatial Statistics Toolbox is the most defensible implementation of those steps. R handles the reproducible statistical validation. That bilingual workflow is the actual standard in applied spatial epidemiology, and it is the one I want to demonstrate I can run.

**Stage 1, source ingestion.**

| Layer | Source | Year / Resolution |
|-------|--------|-------------------|
| Community Health Center locations (135 points) | MassGIS | 2024, Point |
| Census Tract boundaries | U.S. Census / MassGIS | 2020, Tract |
| Population & density estimates | U.S. Census ACS | 2020 & 2022 |
| Social Vulnerability Index (SVI) | CDC / ATSDR | 2020, County |
| Block Group boundaries | TIGRIS / Census | 2023, Block Group |

All sources are publicly available. No PHI or restricted data is used.

**Stage 2, coordinate harmonization.** I reproject every layer to NAD 1983 State Plane Massachusetts Mainland (FIPS 2001), so that linear distances (1-mile buffers) are accurate. Using a geographic CRS at this latitude would introduce a buffer-distance error of several percent.

**Stage 3, ArcGIS Pro Model Builder workflow (`arcgis/model_builder_workflow.md`).** A three-tool deterministic graph:

1. Buffer: 1-mile dissolved buffers around all 135 CHC point locations.
2. Spatial Join (Intersect, One-to-One): link each buffer polygon to the Census Tract it intersects, propagating tract attributes onto the buffer.
3. Field Statistics (Summarize Within): emit total population (2020, 2022) and mean population density inside each buffer.

**Stage 4, spatial statistics (`arcgis/hotspot_analysis.md`).** I run Global Moran's I and Getis-Ord Gi\* on the tract-level access variable. The spatial weights matrix is documented explicitly (queen contiguity, row-standardized) so the analysis is exactly reproducible. Output rasters and the Gi\* z-score and p-value fields go to `outputs/` for downstream R visualization.

**Stage 5, statistical validation in R.**

- `R/01_load_svi.R` ingests the 2020 CDC SVI for all 14 Massachusetts counties (the finest publicly available resolution at the time of this analysis), strips suppressed sentinels (-1, -999), and harmonizes county FIPS codes against the TIGRIS block-group layer.
- `R/02_welch_ttest.R` partitions counties at RPL_THEMES at or above 0.5 and runs the Welch test on 2020 total population.
- `R/03_figures.R` renders publication-grade choropleths via `sf` and `ggplot2` and overlays the Gi\* cold-spot polygons on the SVI choropleth.

**Stage 6, cleaning conventions worth being explicit about.**

- Suppressed SVI sentinels (-1, -999) are converted to `NA` before any arithmetic. The count of suppressed tracts is logged.
- CHC point geometry is validated against the MassGIS layer (no duplicate point IDs; no out-of-state coordinates).
- All joins are inner joins on canonical FIPS strings (zero-padded to the appropriate length). Join completeness is asserted before the spatial statistics stage runs.

```
boston-cooling-deserts/
├── README.md                          # you are here
├── data/
│   ├── raw/                            # source data (not committed; see data/README.md)
│   └── processed/                      # outputs from Model Builder
├── arcgis/
│   ├── model_builder_workflow.md       # buffer -> spatial join -> summarize
│   └── hotspot_analysis.md             # Moran's I + Getis-Ord Gi*
├── R/
│   ├── 01_load_svi.R                   # ingest CDC SVI, harmonize FIPS
│   ├── 02_welch_ttest.R                # Welch two-sample t on SVI strata
│   └── 03_figures.R                    # sf + ggplot choropleths, Gi* overlay
├── outputs/
│   ├── figures/
│   └── tables/
└── LICENSE
```

## Key findings

- Spatial coverage. All 135 CHC buffers processed with population data attached. `TARGET_FID` values ranged from 11+ tracts down to zero, which means there are real gaps in spatial coverage across the study area.
- Hot-spot pattern. Getis-Ord Gi\* surfaced hot spots in central Boston, Lowell, Waltham, and Malden. Cold spots concentrated in western MA and Cape Cod, which are the Cooling Desert candidates.
- Statistical validation. The Welch t-test p-value of 0.8235 (county level) confirms that raw headcount alone does not drive the risk gap. The risk gap is driven by density, access, and socioeconomic pressure.
- Equity signal. Suffolk County (SVI = 0.923) and Hampden County (SVI = 1.000) carry the highest vulnerability scores and large populations. The service gaps in those two counties are where this project matters most.

## Limitations

- Buffer geometry. Euclidean 1-mile buffers overestimate true walkable access. Network walksheds are planned for the next phase.
- CHC as cooling proxy. Not all CHCs are designated cooling sites; verified registries are needed.
- SVI granularity. County-level SVI masks intra-county variation; tract-level SVI will refine vulnerability mapping.
- No temperature layer. Land Surface Temperature (MODIS, Landsat) has not yet been integrated.

## Conclusions and bridge to Fulbright Belgium

A spatial workflow built in ArcGIS Pro and R can identify Cooling Deserts across Massachusetts using publicly available data. CHC distribution is statistically clustered. Cold spots show up where vulnerable people have the fewest nearby options. Vulnerability, not raw population, drives the risk. The Boston Public Health Commission could use these cold-spot locations now to help decide where to place emergency cooling centers before the 2026 heat season.

The same sequence (Global Moran's I, Getis-Ord Gi\*, vulnerability overlay) is the spatial-statistical backbone of my proposed Fulbright research at Ghent University. The input layer becomes the Belgian statistical sector registry, the outcome becomes small-area hypertension prevalence, and the equity overlay shifts from CDC SVI to the Belgian socioeconomic indicators published by Statbel. This repository is the technical proof that the methodology transfers.

## Reproducibility

```r
# R >= 4.0
install.packages(c("tidyverse", "sf", "spdep", "tigris", "readr"))
source("R/01_load_svi.R")
source("R/02_welch_ttest.R")
source("R/03_figures.R")
```

ArcGIS Pro Model Builder steps are documented in `arcgis/model_builder_workflow.md`.

## References

1. CDC (2020). *Heat-Related Deaths, United States, 2004-2018.* MMWR.
2. Brooke, J., et al. (2023). *Examining the Optimal Placement of Cooling Centers to Serve Populations at High Risk.* AJPM.
3. Mallen, E., et al. (2022). *Extreme Heat Exposure: Access and Barriers to Cooling Centers.* MMWR, CDC.
4. CDC / ATSDR (2020). *Social Vulnerability Index Documentation.*
5. MassGIS (2024). *Community Health Centers Data Layer.* Commonwealth of Massachusetts.
6. Getis, A., & Ord, J. K. (1992). *The Analysis of Spatial Association by Use of Distance Statistics.* Geographical Analysis, 24(3).
7. Anselin, L. (1995). *Local Indicators of Spatial Association: LISA.* Geographical Analysis, 27(2).

## Contact

**Romario Joseph**, MPH Candidate, Boston University SPH
rjoseph3@bu.edu, [LinkedIn](https://www.linkedin.com/in/romariojosephpublichealth/)
