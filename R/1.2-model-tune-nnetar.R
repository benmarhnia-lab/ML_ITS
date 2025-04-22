# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey, Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script configures, tunes, and fits a NNTEAR model to the aggregated data
# @date: Dec 16, 2024

# load libraries ----------------------------------------------------------------
rm(list = ls())
set.seed(0112358)
pacman::p_load(here, tidymodels, tidyverse, modeltime, timetk, tictoc)

# load data ----------------
df_train_test <- read.csv(here("Data", "df-train-test-sf.csv")) |> mutate(date = as.Date(date))

# split data into training and test sets -------------------------------------
set.seed(0112358)
splits_resp <- df_train_test |>
  time_series_split(
    assess = "24 months",
    cumulative = TRUE,
    date_var = date
  )

min(training(splits_resp)$date)
max(training(splits_resp)$date)
min(testing(splits_resp)$date)
max(testing(splits_resp)$date)

## resample data ----
set.seed(0112358)
resamples_kfold_resp <- training(splits_resp) |>
  time_series_cv(
    assess = "12 months",     # Length of each assessment period
    initial = "2 years",     # Initial training period
    slice_limit = 5,         # Number of slices to create
    skip = "12 months",       # Skip period
    cumulative = TRUE       # Use expanding window
)
  
# recipe for modeling ---------------------------------------------------
rec_obj_nnetar <- recipe(respiratory ~ ., training(splits_resp)) |>
    step_timeseries_signature(date) |>
    
    # cleaning steps
    step_rm(matches("(.iso$)|(.xts$)")) |>
    # step_rm(matches("county")) |>
    step_normalize(matches("(index.num$)|(_year$)")) |>
    step_dummy(all_nominal())

### Review the recipe ----
rec_obj_nnetar |> prep() |> juice() |> colnames()

# specify models ---------------------------------------------------
model_nnetar_tune <- nnetar_reg(
      non_seasonal_ar = tune(),
      seasonal_ar   = tune(),
      hidden_units = tune(),
      num_networks = tune(),
      penalty = tune(),
      epochs = tune()
  ) |>
    set_engine("nnetar",
      set.seed = 0112358)


# generate grid for tuning ---------------------------------------------------
grid_nnetar_tune <- grid_space_filling(
  extract_parameter_set_dials(model_nnetar_tune) |>
    update(
      hidden_units = hidden_units(range = c(8, 20), trans = NULL),
      num_networks = num_networks(range = c(40, 100), trans = NULL),
      penalty = penalty(range = c(0.01, 0.1), trans = NULL), 

      # Time series parameters
      seasonal_ar = seasonal_ar(range = c(1, 4), trans = NULL),
      non_seasonal_ar = non_seasonal_ar(range = c(1, 6), trans = NULL),
      epochs = epochs(range = c(50L, 200L), trans = NULL)
    ),
  size = 75
)

# workflow for tuning ---------------------------------------------------
wflw_nnetar_tune <- workflow() |>
                    add_model(model_nnetar_tune) |>
                    add_recipe(rec_obj_nnetar)

# model tuning ---------------------------------------------------
tic()
set.seed(0112358)
tune_results_nnetar <- wflw_nnetar_tune |>
  tune_grid(
    resamples = resamples_kfold_resp,
    grid = grid_nnetar_tune,
    # control parameters
    control = control_grid(
      verbose = TRUE,
      allow_par = TRUE,
      save_pred = TRUE,
      save_workflow = TRUE,
      parallel_over = "resamples",
      event_level = "first",
      pkgs = c("modeltime", "timetk", "tidymodels")
    ),
    # Add metrics
    metrics = metric_set(rmse, rsq)
  )
toc() # 23 hrs on MESOM

# save the results ---------------------------------------------------
rm(df_train_test)
save.image(here("Outputs", "1.2-model-tune-nnetar-final.RData"))
