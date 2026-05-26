# Who Gets Left Out in the Heat?
## Spatial Access to Community Health Centers Across Boston Neighborhoods

**Author:** Romario Joseph, MPH Candidate
**Affiliation:** Boston University School of Public Health — Department of Epidemiology & Biostatistics
**Course:** Applied Spatial and Temporal Data Processing and Modeling (Spring 2026)
**Stack:** ArcGIS Pro 3.x · Model Builder · Spatial Statistics Toolbox · R 4.x · RStudio

---

## TL;DR
Extreme heat is now the leading weather-related cause of death in the U.S. (CDC, 2020), and Boston is increasingly vulnerable due to the urban heat island effect, aging housing stock, and uneven cooling infrastructure. This project uses **publicly available data + a reproducible ArcGIS Pro + R pipeline** to identify **Cooling Deserts** — census tracts where dense, socially vulnerable populations have the least spatial access to Community Health Centers (CHCs) that can serve as heat-event access points.

**Headline numbers:**
- 135 CHC 1-mile service buffers processed across Massachusetts
- - Suffolk County SVI = 0.923 (Hampden = 1.000) — highest-vulnerability hotspots
  - - Moran's I clustering significant at p < 0.01 — CHC distribution is non-random
    - - Welch t-test (county-level SVI) p = 0.8235 — confirms vulnerability is **not** driven by raw population size
     
      - ---

      ## Central Question
      > Which Boston neighborhoods are **Cooling Deserts** — areas with high population density and high social vulnerability but low spatial access to Community Health Centers?
      >
      > ## Hypothesis
      > Boston census tracts with the highest CDC Social Vulnerability Index scores will show significantly lower spatial access to CHC service areas, identifying them as Cooling Deserts where dense, at-risk populations are least served by existing cooling infrastructure.
      >
      > ---
      >
      > ## Aims
      > | # | Aim |
      > |---|-----|
      > | 1 | Map 1-mile service area buffers around all 135 Community Health Centers across Massachusetts to estimate spatial coverage. |
      > | 2 | Join CHC buffers with 2020 Census Tract data to assess population density within and outside service areas. |
      > | 3 | Run Global Moran's I and Hotspot Analysis (Getis-Ord Gi*) to detect statistically significant clusters of high and low CHC access. |
      >
      > ---
      >
      > ## Methods
      >
      > ### Part 1 — ArcGIS Pro Model Builder
      > Three-step workflow, projected to **NAD 1983 State Plane Massachusetts Mainland (FIPS 2001)** for accurate linear distance:
      > 1. **Buffer** — 1-mile dissolved buffers around all 135 CHC point locations
      > 2. 2. **Spatial Join** (Intersect, One-to-One) — link each buffer to the Census Tract it intersects
      >    3. 3. **Field Statistics** — summarize total population (2020, 2022) and mean population density inside each buffer
      >      
      >       4. ### Part 2 — Spatial Statistics (ArcGIS Pro)
      >       5. - **Global Moran's I** — tests whether CHC distribution across Suffolk County tracts is spatially random or clustered
      >          - - **Hotspot Analysis (Getis-Ord Gi*)** — identifies statistically significant high-access (hot spots) and low-access (cold spots) tracts at 90 / 95 / 99 percent confidence
      >           
      >            - ### Part 3 — Statistical Validation in R
      >            - - **Welch two-sample t-test** comparing 2020 total population between High SVI counties (RPL_THEMES ≥ 0.5) and Low SVI counties
      >              - - Uses 2020 CDC SVI for all 14 Massachusetts counties (finest publicly available resolution at time of analysis)
      >                - - Tract-level SVI validation planned for next phase
      >                 
      >                  - ---
      >
      > ## Repository Structure
      > ```
      > boston-cooling-deserts/
      > ├── README.md                  ← you are here
      > ├── data/
      > │   ├── raw/                   ← source data (not committed; see data/README.md)
      > │   └── processed/             ← outputs from Model Builder
      > ├── arcgis/
      > │   ├── model_builder_workflow.md
      > │   └── hotspot_analysis.md
      > ├── R/
      > │   ├── 01_load_svi.R
      > │   ├── 02_welch_ttest.R
      > │   └── 03_figures.R
      > ├── outputs/
      > │   ├── figures/
      > │   └── tables/
      > └── LICENSE
      > ```
      >
      > ---
      >
      > ## Data Sources
      > | Layer | Source | Year / Resolution |
      > |-------|--------|-------------------|
      > | Community Health Center Locations (135 points) | MassGIS | 2024 · Point |
      > | Census Tract Boundaries | U.S. Census / MassGIS | 2020 · Tract |
      > | Population & Density Estimates | U.S. Census ACS | 2020 & 2022 |
      > | Social Vulnerability Index (SVI) | CDC / ATSDR | 2020 · County |
      > | Block Group Boundaries | TIGRIS / Census | 2023 · Block Group |
      >
      > All sources are publicly available. No PHI or restricted data is used.
      >
      > ---
      >
      > ## Key Findings
      >
      > **Spatial Coverage.** All 135 CHC buffers processed with population data attached. TARGET_FID values ranged from 11+ tracts down to zero — real gaps in spatial coverage across the study area.
      >
      > **Hotspot Pattern.** Getis-Ord Gi* surfaced hot spots in central Boston, Lowell, Waltham, and Malden. Cold spots concentrated in western MA and Cape Cod — these are the Cooling Desert candidates.
      >
      > **Statistical Validation.** Welch t-test p = 0.8235 (county-level). The non-significant result confirms that raw headcount alone does not drive the risk gap; vulnerability is driven by density, access, and socioeconomic pressure.
      >
      > **Equity Signal.** Suffolk County (SVI = 0.923) and Hampden County (SVI = 1.000) have the highest vulnerability scores and large populations. The service gaps in those two counties are where this project matters most.
      >
      > ---
      >
      > ## Limitations
      > - **Buffer geometry.** Euclidean 1-mile buffers overestimate true walkable access. Network walksheds planned for next phase.
      > - - **CHC as cooling proxy.** Not all CHCs are designated cooling sites; verified registries needed.
      >   - - **SVI granularity.** County-level SVI masks intra-county variation; tract-level SVI will refine vulnerability mapping.
      >     - - **No temperature layer.** Land Surface Temperature (MODIS, Landsat) has not yet been integrated.
      >      
      >       - ---
      >
      > ## Conclusions & Implications
      > 1. A spatial workflow built in ArcGIS Pro and R can identify Cooling Deserts across Massachusetts using publicly available data.
      > 2. 2. CHC distribution is statistically clustered. Cold spots show up where vulnerable people have the fewest nearby options.
      >    3. 3. Vulnerability, not raw population, drives the risk. Suffolk and Hampden counties should be first in line for new cooling resources.
      >       4. 4. Running the same workflow at the census tract level and adding Land Surface Temperature (MODIS, Landsat) would sharpen the picture considerably.
      >          5. 5. The Boston Public Health Commission could use these cold-spot locations right now to help decide where to put emergency cooling centers before the 2026 heat season.
      >            
      >             6. ---
      >            
      >             7. ## Reproducibility
      >             8. ```r
      >                # R ≥ 4.0
      > install.packages(c("tidyverse", "sf", "tigris", "readr"))
      > source("R/01_load_svi.R")
      > source("R/02_welch_ttest.R")
      > source("R/03_figures.R")
      > ```
      > ArcGIS Pro Model Builder steps are documented in `arcgis/model_builder_workflow.md`.
      >
      > ---
      >
      > ## References
      > 1. CDC (2020). *Heat-Related Deaths, United States, 2004–2018.* MMWR.
      > 2. Brooke, J., et al. (2023). *Examining the Optimal Placement of Cooling Centers to Serve Populations at High Risk.* AJPM.
      > 3. Mallen, E., et al. (2022). *Extreme Heat Exposure: Access and Barriers to Cooling Centers.* MMWR, CDC.
      > 4. CDC / ATSDR (2020). *Social Vulnerability Index Documentation.*
      > 5. MassGIS (2024). *Community Health Centers Data Layer.* Commonwealth of Massachusetts.
      >
      > ---
      >
      > ## Contact
      > **Romario Joseph** — MPH Candidate, Boston University SPH
      > 📧 rjoseph3@bu.edu · [LinkedIn](https://www.linkedin.com/in/romariojosephpublichealth/)
      > 
