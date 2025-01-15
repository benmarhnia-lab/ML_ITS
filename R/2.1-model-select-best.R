# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey (arnabxdey@gmail.com), Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script selects the best models based on RMSE and creates a modeltime table for comparison
# @date: Dec 16, 2024

# load libraries ----------------------------------------------------------------
rm(list = ls())
set.seed(0112358)
pacman::p_load(here, tidymodels, tidyverse, modeltime)

# load data ---------------------------------------------------
df_preintervention <- read.csv(here("Data", "df-train-test-sf.csv")) |> mutate(date = as.Date(date))
df_all_cases <- read.csv(here("Data", "df-predict-sf.csv")) |> mutate(date = as.Date(date))

# load tuned models ---------------------------------------------------
## load ARIMA
load(here("Outputs", "1.1-model-tune-arima-final.RData"))
## load NNETAR

rm(list = ls(pattern = "resp"))
load(here("Outputs", "1.2-model-tune-nnetar-final.RData"))

## load Prophet-XGBoost
rm(list = ls(pattern = "resp"))
load(here("Outputs", "1.3-model-tune-phxgb-final.RData"))

# step-1: select best models ---------------------------------------------------
set.seed(0112358)
## ARIMA
wflw_fit_arima_tuned <- wflw_arima_tune |>
  finalize_workflow(
    select_best(tune_results_arima, metric = "rmse")
  ) |>
  fit(training(splits_resp))

## NNETAR
set.seed(0112358)
wflw_fit_nnetar_tuned <- wflw_nnetar_tune |>
  finalize_workflow(
    select_best(tune_results_nnetar, metric = "rmse")
  ) |>
  fit(training(splits_resp))

## Prophet + XGBoost
set.seed(0112358)
wflw_fit_phxgb_tuned <- wflw_phxgb_tune |>
  finalize_workflow(
    select_best(tune_results_phxgb, metric = "rmse")
  ) |>
  fit(training(splits_resp))

# step-2: generate modeltime table ---------------------------------------------------
set.seed(0112358)
model_tbl_best_all <- modeltime_table(
  wflw_fit_arima_tuned,
  wflw_fit_nnetar_tuned,
  wflw_fit_phxgb_tuned
)

# save the best model table
model_tbl_best_all |> saveRDS(here("Outputs", "2.1-model-select-best.rds"))