# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey (arnabxdey@gmail.com), Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script fits the selected models to training data and generates forecasts for the entire dataset with bootstrapped confidence intervals
# @date: Dec 16, 2024

# load libraries ----------------------------------------------------------------
rm(list = ls())
set.seed(0112358)
pacman::p_load(here, tidymodels, tidyverse, modeltime)

# load model table with best models ---------------------------------------------------
model_tbl_best_all <- readRDS(here("Outputs", "2.4-model-select-best.rds"))
model_tbl_best_phxgb <- model_tbl_best_all |> filter(str_detect(.model_desc, "PROPHET")) # Prophet was identified as the best model in script 2.2

# source script for bootstrap ---------------------------------------------------
source(here("R", "3.1-func-generate-MC-CIs.R"))

# ensure consistent numeric precision ----------------------------------------------
options(digits = 7)
options(scipen = 999)

# load data ---------------------------------------------------
df_preintervention <- read.csv(here("Data", "df-train-test-sf.csv")) |> mutate(date = as.Date(date))

df_all_cases <- read.csv(here("Data", "df-predict-sf.csv")) |> mutate(date = as.Date(date))

# forecast on all cases with bootstrapped CIs ------------------------------------------
forecast_cis <- generate_forecast_intervals(
  model_spec = model_tbl_best_phxgb,
  training_data = df_preintervention,
  forecast_horizon_data = df_all_cases,
  n_iterations = 1000
)
colnames(forecast_cis) <- c("date", "respiratory_pred", "conf_lo", "conf_hi")

# Merge with actuals ---------------------------------------------------
df_forecast <- df_all_cases |>
    rename(respiratory_actual = respiratory) |>
    select(date, respiratory_actual) |>
    left_join(forecast_cis, by = "date") 

# save final predictions ---------------------------------------------------
df_forecast |> saveRDS(here("Outputs", "3.2-final-preds-phxgb.rds"))
