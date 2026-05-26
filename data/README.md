# Data Directory

  Raw data is **not committed** to this repository. All sources are publicly available; download them directly from the links below to reproduce.

    ## Sources

    | Layer | Source | URL |
    |-------|--------|-----|
    | Community Health Center locations (MA, n=135) | MassGIS | https://www.mass.gov/info-details/massgis-data-community-health-centers |
| MA Census Tracts (2020) | MassGIS / U.S. Census | https://www.mass.gov/info-details/massgis-data-2020-us-census |
| ACS Population 2020 & 2022 | U.S. Census | https://data.census.gov |
| CDC SVI 2020 (MA county) | CDC / ATSDR | https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html |
| TIGRIS Block Groups 2023 | U.S. Census | https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html |

## Folder layout
  ```
  data/
  ├── raw/         ← place downloaded files here (gitignored)
  └── processed/   ← .rds and .csv outputs from R scripts
  ```

  ## Privacy & ethics
  No PHI, no individual-level records, no restricted data. All layers are population-aggregated and openly licensed for public health use.
    
