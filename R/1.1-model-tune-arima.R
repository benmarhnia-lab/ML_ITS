# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey (arnabxdey@gmail.com), Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This script configures, tunes, and fits an ARIMA model to the aggregated data
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

## resample data ----
set.seed(0112358)
resamples_kfold_resp <- training(splits_resp) |> 
    time_series_cv(
    assess = "12 months",     # Length of each assessment period
    initial = "5 years",     # Initial training period
    slice_limit = 10,        # Number of slices to create
    cumulative = TRUE       # Use expanding window
  )

# recipe for resampling ---------------------------------------------------
rec_obj_arima <- recipe(respiratory ~ ., 
    training(splits_resp)) |>

    # add Fourier terms for yearly seasonality
    step_fourier(date, period = 365, K = 3) |>  

    # clean up and normalize
    step_rm(matches("(.iso$)|(.xts$)")) |>
    step_normalize(matches("(index.num$)|(_year$)")) |>
    step_dummy(all_nominal())

### Review the recipe 
rec_obj_arima |> prep() |> juice() |> colnames()

# specify models ---------------------------------------------------
model_arima_tune <- arima_reg(
        non_seasonal_ar = tune(),
        non_seasonal_ma = tune(),
        non_seasonal_differences = tune(),
        seasonal_ar = tune(),
        seasonal_ma = tune(),
        seasonal_differences = tune()
        ) |>
  set_engine("auto_arima")

# generate grid for tuning ---------------------------------------------------
grid_arima_tune <- grid_space_filling(
 extract_parameter_set_dials(model_arima_tune) |>
   update(
     # Non-seasonal parameters
     non_seasonal_ar = non_seasonal_ar(range = c(1L, 3L), trans = NULL),
     non_seasonal_ma = non_seasonal_ma(range = c(1L, 3L), trans = NULL),
     non_seasonal_differences = non_seasonal_differences(range = c(0L, 2L)),
     
     # Seasonal parameters
     seasonal_ar = seasonal_ar(range = c(0L, 3L)),
     seasonal_ma = seasonal_ma(range = c(0L, 3L)),
     seasonal_differences = seasonal_differences(range = c(0L, 1L))
   ),
 size = 100  
)

# workflow for tuning ---------------------------------------------------
wflw_arima_tune <- workflow() |>
                    add_model(model_arima_tune) |>
                    add_recipe(rec_obj_arima)

# model tuning ---------------------------------------------------
tic()
set.seed(0112358)
tune_results_arima <- wflw_arima_tune |>
  tune_grid(
    resamples = resamples_kfold_resp,
    grid = grid_arima_tune,
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
    # Add metrics
    metrics = metric_set(rmse, rsq)
  )
toc() 

# save the results ---------------------------------------------------
rm(df_train_test)
save.image(here("Outputs", "1.1-model-tune-arima-final.RData"))