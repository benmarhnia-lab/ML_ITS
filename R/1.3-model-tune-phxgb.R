# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey (arnabxdey@gmail.com), Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script configures, tunes, and fits a Prophet-XGBoost model to the aggregated data
# @date: Dec 16, 2024

# load libraries ----------------------------------------------------------------
rm(list = ls())
set.seed(0112358)
pacman::p_load(here, tidymodels, tidyverse, modeltime, timetk, tictoc)

# load data ----------------
df_train_test <- read.csv(here("Data", "df-train-test-sf.csv")) |> mutate(date = as.Date(date))

# plit data into training and test sets -------------------------------------
set.seed(0112358)
splits_resp <- df_train_test |>
  time_series_split(
    assess = "24 months",
    cumulative = TRUE,
    date_var = date
  )

## resample data ----
set.seed(0112358)
resamples_kfold_resp <- training(splits_resp) |> 
    time_series_cv(
    assess = "12 months",     # Length of each assessment period
    initial = "5 years",     # Initial training period
    slice_limit = 10,        # Number of slices to create
    cumulative = TRUE       # Use expanding window
  )

# recipe for modeling ---------------------------------------------------
rec_obj_phxgb <- recipe(respiratory ~ ., training(splits_resp)) |>
    # Time series features 
    step_timeseries_signature(date) |>
    # Lags
    step_lag(pm25_diff, lag = 1:14) |>

    # Basic seasonal components
    step_fourier(date, period = 365, K = 3) |>   
    
    # cleaning steps
    step_rm(matches("(.iso$)|(.xts$)")) |>
    # step_rm(matches("county")) |>
    step_normalize(matches("(index.num$)|(_year$)")) |>
    step_dummy(all_nominal())

## review the recipe
rec_obj_phxgb |> prep() |> juice() |> colnames()

# specify models ---------------------------------------------------
model_phxgb_tune <- prophet_boost(
                      mode = "regression",
                      growth = tune(),
                      changepoint_range = tune(),
                      seasonality_yearly = tune(),
                      prior_scale_changepoints = tune(),
                      prior_scale_seasonality = tune(),
                      #xgboost  
                      mtry = tune(),
                      min_n = tune(),
                      tree_depth = tune(),
                      learn_rate = tune(),
                      loss_reduction = tune(),
                      stop_iter = tune()
                      ) |>
                set_engine("prophet_xgboost",
                set.seed = 0112358)

# generate grid for tuning ---------------------------------------------------
grid_phxgb_tune <- grid_space_filling(
  extract_parameter_set_dials(model_phxgb_tune) |>
    update(
      # Prophet parameters
      growth = growth(values = c("linear")),
      changepoint_range = changepoint_range(range = c(0.4, 0.8), trans = NULL), # Wider range
      seasonality_yearly = seasonality_yearly(values = c(TRUE)),
      prior_scale_changepoints = prior_scale_changepoints(
        range = c(0.01, 0.5),  
        trans = NULL
      ),
      prior_scale_seasonality = prior_scale_seasonality(
        range = c(0.1, 2.0),   
        trans = NULL
      ),
      
      # XGBoost parameters
      mtry = mtry(range = c(4, 25), trans = NULL),
      min_n = min_n(range = c(1L, 12L), trans = NULL),
      tree_depth = tree_depth(range = c(8, 20), trans = NULL),
      learn_rate = learn_rate(range = c(0.001, 0.1), trans = NULL),
      loss_reduction = loss_reduction(range = c(-12, 2), trans = log10_trans()),
      stop_iter = stop_iter(range = c(10L, 30L), trans = NULL)
    ),
  size = 100
)

# workflow for tuning ---------------------------------------------------
wflw_phxgb_tune <- workflow() |>
                    add_model(model_phxgb_tune) |>
                    add_recipe(rec_obj_phxgb)

# model tuning ---------------------------------------------------
tic(quite = FALSE)
set.seed(0112358)
tune_results_phxgb <- wflw_phxgb_tune |>
  tune_grid(
    resamples = resamples_kfold_resp,
    grid = grid_phxgb_tune,
    # control parameters
    control = control_grid(
        verbose = TRUE,
        allow_par = TRUE,
        save_pred = TRUE,
        save_workflow = TRUE,
        parallel_over = "resamples",
        event_level = "first",
        pkgs = c("tidymodels", "modeltime", "timetk")
      ),
      metrics = metric_set(rmse, rsq)
  )
toc() 

# save the results ---------------------------------------------------
rm(df_train_test)
save.image(here("Outputs", "1.3-model-tune-phxgb-final.RData"))