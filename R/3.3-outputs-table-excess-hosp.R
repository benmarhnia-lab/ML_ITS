# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey (arnabxdey@gmail.com), Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script computes the excess hospitalizations due to the wildfire and saves as a gt table
# @date: Dec 28, 2024

# load libraries ----------------------------------------------------------------
rm(list = ls())
pacman::p_load(here)

# save final predictions
df_forecast <- readRDS(here("Outputs", "3.2-final-preds-phxgb.rds"))

# subset
data.period <- df_forecast |>
  filter(date >= as.Date("2018-11-09") & date <= as.Date("2018-11-20")) |>
  dplyr::select(-date) |>
  mutate(period = "main event")

# calculate and format
data.period <- data.period|>
  group_by(period) |>
  summarise(observed = sum(respiratory_actual),
            expected = sum(respiratory_pred),
            expected_low = sum(conf_lo),
            expected_up = sum(conf_hi)) |>
  mutate(excess = observed - expected,
         excess_low = observed - expected_up,
         excess_up = observed - expected_low,
         excess_pct = excess / observed * 100,
         excess_low_pct = excess_low / observed * 100,
         excess_up_pct = excess_up / observed * 100) |>
  mutate(expected_CI = paste0(round(expected),
                              " (",
                              round(expected_low),
                              ", ",
                              round(expected_up),
                              ")"),
         excess_CI = paste0(round(excess),
                            " (",
                            round(excess_low),
                            ", ",
                            round(excess_up),
                            ")"),
         excess_pct_CI = paste0(round(excess_pct, 1),
                                " (",
                                round(excess_low_pct, 1),
                                ", ",
                                round(excess_up_pct, 1),
                                ")")) |>
  dplyr::select(period, observed, expected_CI, excess_CI, excess_pct_CI)

print(data.period)
