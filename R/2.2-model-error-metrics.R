# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey, Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script loads the modeltime table with best models and calculates training and testing error metrics
# @date: Dec 16, 2024

# load libraries ----------------------------------------------------------------
rm(list = ls())
set.seed(0112358)
pacman::p_load(here, tidymodels, tidyverse, modeltime)

# ensure consistent numeric precision ----------------------------------------------
options(digits = 7)
options(scipen = 999)

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

# load model table with best models ---------------------------------------------------
model_tbl_best_all <- readRDS(here("Outputs", "2.1-model-select-best.rds"))

# step-1: generate training error rates -----------------------------------------------
## calibrate best models on training data and format model descriptions
training_preds <- model_tbl_best_all |>
  modeltime_calibrate(
    new_data = training(splits_resp) |> filter(date > as.Date("2009-01-10")),
    # id = "county",
    quiet = FALSE
  ) |>
  select(.model_desc, .calibration_data) |>
  unnest(cols = c(.calibration_data)) |>
  mutate(.model_desc = case_when(
    stringr::str_detect(.model_desc, "REGRESSION WITH ARIMA") ~ "ARIMA",
    stringr::str_detect(.model_desc, "ARIMA") & stringr::str_detect(.model_desc, "XGBOOST") ~ "ARIMAXGB",
    stringr::str_detect(.model_desc, "PROPHET") ~ "PROPHETXGB",
    stringr::str_detect(.model_desc, "NNAR") ~ "NNETAR",
    TRUE ~ .model_desc
  ))

## generate training error metrics
df_training_metrics <- training_preds |>
  filter(date > as.Date("2009-02-01")) |>
  group_by(.model_desc) |>
  summarise(
    mdae = Metrics::mdae(.actual, .prediction),
    mae = Metrics::mae(.actual, .prediction),
    rmse = Metrics::rmse(.actual, .prediction),
    mape = Metrics::mape(.actual, .prediction),
    rse = Metrics::rse(.actual, .prediction),
    smape = Metrics::smape(.actual, .prediction),
    r2 = round(1 - sum((.actual - .prediction)^2) / sum((.actual - mean(.actual))^2), 2)
  )

## save training predictions
df_training_metrics |> saveRDS(here("Outputs", "2.2-model-training-errors.rds"))

# step-2: generate test error rates ------------------------------------------
## calibrate best models on test data and format model descriptions
test_preds <- model_tbl_best_all |>
  modeltime_calibrate(
    new_data = testing(splits_resp),
    # id = "county",
    quiet = FALSE
  ) |>
  select(.model_desc, .calibration_data) |>
  unnest(cols = c(.calibration_data)) |>
  mutate(.model_desc = case_when(
    stringr::str_detect(.model_desc, "REGRESSION WITH ARIMA") ~ "ARIMA",
    stringr::str_detect(.model_desc, "ARIMA") & stringr::str_detect(.model_desc, "XGBOOST") ~ "ARIMAXGB",
    stringr::str_detect(.model_desc, "PROPHET") ~ "PROPHETXGB",
    stringr::str_detect(.model_desc, "NNAR") ~ "NNETAR",
    TRUE ~ .model_desc
  ))

## generate test error metrics
df_testing_metrics <- test_preds |>
  filter(date > as.Date("2009-02-01")) |>
  group_by(.model_desc) |>
  summarise(
    mdae = Metrics::mdae(.actual, .prediction),
    mae = Metrics::mae(.actual, .prediction),
    rmse = Metrics::rmse(.actual, .prediction),
    mape = Metrics::mape(.actual, .prediction),
    rse = Metrics::rse(.actual, .prediction),
    smape = Metrics::smape(.actual, .prediction),
    r2 = round(1 - sum((.actual - .prediction)^2) / sum((.actual - mean(.actual))^2), 2)
  )

## save test predictions
df_testing_metrics |> saveRDS(here("Outputs", "2.2-model-test-errors.rds"))