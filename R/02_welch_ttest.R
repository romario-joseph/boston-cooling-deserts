# 02_welch_ttest.R
# Boston Cooling Deserts — Statistical validation
# Welch two-sample t-test: Total Population by SVI group (county-level, MA)
# Author: Romario Joseph | BU SPH

library(tidyverse)

svi <- readRDS("data/processed/svi_ma_county_2020.rds")

# Welch two-sample t-test (unequal variance)
fit <- t.test(E_TOTPOP ~ svi_group, data = svi, var.equal = FALSE)
print(fit)

# Save a tidy table for the report
tidy_out <- tibble(
    test     = "Welch two-sample t-test",
    grouping = "RPL_THEMES >= 0.5",
    t        = unname(fit$statistic),
    df       = unname(fit$parameter),
    p_value  = fit$p.value,
    ci_low   = fit$conf.int[1],
    ci_high  = fit$conf.int[2],
    mean_high_svi = unname(fit$estimate[1]),
    mean_low_svi  = unname(fit$estimate[2])
  )

write_csv(tidy_out, "outputs/tables/welch_ttest_svi.csv")

# Interpretation
message("\nInterpretation:")
message("p = ", round(fit$p.value, 4),
                " — county-level test does not separate High vs Low SVI by raw population.",
                "\nVulnerability is driven by density, access, and SES — not headcount.")
