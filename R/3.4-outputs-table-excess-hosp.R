# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey, Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script computes the excess hospitalizations due to the wildfire smoke event for different periods
# @date: Dec 28, 2024

# load libraries ----
rm(list = ls())
pacman::p_load(here, dplyr)

# save final predictions
df_forecast <- readRDS(here("Outputs", "3.2-final-preds-phxgb.rds"))
head(df_forecast)

# load function ----
source(here("R", "3.3-func-calc-excess-hosp.R"))

# create data subsets ----
## daily data bw 2018-11-09 and 2018-11-20
df_daily <- df_forecast |>
  filter(date >= as.Date("2018-11-09") & date <= as.Date("2018-11-20")) |>
  mutate(observed = respiratory_actual)

## total hospitalizations bw 2018-11-09 and 2018-11-20
df_period_1 <- df_forecast |>
  filter(date >= as.Date("2018-11-09") & date <= as.Date("2018-11-20")) |>
  summarise(observed = sum(respiratory_actual),
            expected = sum(respiratory_pred),
            expected_low = sum(conf_lo),
            expected_up = sum(conf_hi),
            period = "Period 1") 

## total hospitalizations bw 2018-11-08 and 2018-11-20
df_period_2 <- df_forecast |>
  filter(date >= as.Date("2018-11-08") & date <= as.Date("2018-11-20")) |>
  summarise(observed = sum(respiratory_actual),
            expected = sum(respiratory_pred),
            expected_low = sum(conf_lo),
            expected_up = sum(conf_hi),
            period = "Period 2")

## total hospitalizations bw 2018-11-21 and 2018-11-27
df_period_3 <- df_forecast |>
  filter(date >= as.Date("2018-11-21") & date <= as.Date("2018-11-27")) |>
  summarise(observed = sum(respiratory_actual),
            expected = sum(respiratory_pred),
            expected_low = sum(conf_lo),
            expected_up = sum(conf_hi),
            period = "Period 3")


# calculate excess hospitalizations ----
## daily data
result_daily <- func_excess_hosp(df_daily,
                      observed = "observed",
                      expected = "respiratory_pred",
                      expected_conf_lo = "conf_lo",
                      expected_conf_hi = "conf_hi")

head(result_daily)

## for period-1
result_period_1 <- func_excess_hosp(df_period_1,
                      observed = "observed",
                      expected = "expected",
                      expected_conf_lo = "expected_low",
                      expected_conf_hi = "expected_up")

head(result_period_1)

## for period-2
result_period_2 <- func_excess_hosp(df_period_2,
                      observed = "observed",
                      expected = "expected",
                      expected_conf_lo = "expected_low",
                      expected_conf_hi = "expected_up")

## for period-3
result_period_3 <- func_excess_hosp(df_period_3,
                      observed = "observed",
                      expected = "expected",
                      expected_conf_lo = "expected_low",
                      expected_conf_hi = "expected_up")

# combine results ----
result_combined <- bind_rows(result_daily, 
                              result_period_1,
                              result_period_2,
                              result_period_3)

print(result_combined)                              
