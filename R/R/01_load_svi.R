# 01_load_svi.R
# Boston Cooling Deserts — Load CDC SVI 2020 (MA, county-level)
# Author: Romario Joseph | BU SPH

library(tidyverse)
library(readr)

# CDC ATSDR SVI 2020 — Massachusetts county file
# Source: https://www.atsdr.cdc.gov/placeandhealth/svi/data_documentation_download.html
svi_url <- "https://svi.cdc.gov/Documents/Data/2020/csv/states_counties/Massachusetts_county.csv"

svi <- read_csv(svi_url, show_col_types = FALSE) |>
  select(COUNTY, FIPS, E_TOTPOP, RPL_THEMES) |>
  mutate(svi_group = if_else(RPL_THEMES >= 0.5, "High SVI", "Low SVI"))

message("Loaded ", nrow(svi), " MA counties")
print(svi |> arrange(desc(RPL_THEMES)))

saveRDS(svi, "data/processed/svi_ma_county_2020.rds")
