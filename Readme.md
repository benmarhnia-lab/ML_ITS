# Two-Stage Interrupted Time Series Analysis with Machine Learning: Evaluating the Health Effects of the 2018 Wildfire Smoke Event in San Francisco County as a Case Study
Authors: Arnab K. Dey, Yiqun Ma, Gabriel Carrasco-Escobar, Changwoo Han, François Rerolle, Tarik Benmarhnia

This repository contains scripts used to analyze the impact of wildfires on respiratory hospitalizations using a two-stage interrupted time series design. The following sections describe data sources and scripts needed to replicate the analysis.

# Data Sources

Data for this analysis comes from multiple sources:

* Maximum and minimum air temperature data (via the Parameter-elevation Regressions on Independent Slopes Model (PRISM) Climate Group)
* Dew point temperature data (via the the Parameter-elevation Regressions on Independent Slopes Model (PRISM) Climate Group)
* PM2.5 concentration data (via an ensemble-based approach developed by Aguilera et al. https://doi.org/10.1016/j.envint.2022.107719)
* Precipitation data (via the Gridded Surface Meteorological (gridMET) reanalysis product)
* Respiratory hospitalization data (via the Department of Health Care Access and Information, California)

# Data Dictionary

This section describes the variables present in the datasets used in the study. We use two datasets [df-train-test-sf.csv](Data/) and [df-predict.csv](Data/). 
These datasets correspond to the pre-event period (i.e. 2009-01-01 to 2018-11-07) and the entire study period including the post-event period (i.e. 2009-01-01 to 2018-12-31).
* `df-train-test-sf.csv` is used to train the models, to perform crossvalidation, and to evaluate model performance. 
* 'df-predict.csv' is used to predict hospitalizations under the counterfactual scenario.

Both datasets include the following variables:
* date: daily dates
* respiratory: the count of daily respiratory hospitalizations  
* Tmin: Daily minimum temperature (°C)
* Tmax: Daily maximum temperature (°C)
* dewT: Daily mean dew point temperature (°C)
* precip_avg: Daily mean precipitation in millimeters 
* pm25_diff: Daily mean non-smoke PM2.5 (\(\mu g/m^{3}\)))

# Data Analysis Scripts

## 1. Model Tuning Scripts

### [1.1-model-tune-arima.R](R/1.1-model-tune-arima.R)
This script configures, tunes, and fits an ARIMA model to the aggregated data. It implements time series cross-validation with 12-month assessment periods and 5-year initial training, tuning hyperparameters using a space-filling grid of 100 combinations.

### [1.2-model-tune-nnetar.R](R/1.2-model-tune-nnetar.R)
This script configures, tunes, and fits a NNETAR model to the aggregated data. It implements neural network time series modeling with comprehensive tuning across network architecture and time series parameters.

### [1.3-model-tune-phxgb.R](R/1.3-model-tune-phxgb.R)
This script configures, tunes, and fits a Prophet-XGBoost model to the aggregated data. It combines Facebook Prophet for trend/seasonality with XGBoost for residuals, using a space-filling grid of 100 combinations.

## 2. Model selection scripts 

### [2.1-model-selection.R](R/2.1-model-select-best.R)
This script selects the best models based on RMSE for each method and creates a modeltime table for comparison. 

### [2.2-model-error-metrics.R](R/2.2-model-error-metrics.R)
This script loads the modeltime table generated in the previous script and calculates training and testing errors. The test errors are compared to identify the best method.

## 3. Output Generation Scripts

### [3.1-func-generate-MC-CIs.R](R/3.1-func-generate-MC-CIs.R)
This script contains functions to generate confidence intervals for time series forecasts.

### [3.2-model-forecast.R](R/3.2-model-forecast.R)
This script fits the model from the selected method to the entire data (including post wildfire data) and generates forecasts for the entire dataset with bootstrapped confidence intervals.

### [3.3-outputs-table-excess-hosp.R](R/3.3-outputs-table-excess-hosp.R)
This script computes the excess hospitalizations due to the wildfire and saves as a gt table.

Note: This repository is part of ongoing research at Scripps Institution of Oceanography, UC San Diego. Additional scripts and documentation will be added as the analysis progresses.