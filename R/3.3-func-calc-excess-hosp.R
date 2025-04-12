# -------------------------------------------------------------------------------
# @project: Two-stage interrupted time series design
# @author: Arnab K. Dey, Yiqun Ma
# @organization: Scripps Institution of Oceanography, UC San Diego
# @description: This function calculates excess hospitalizations related metrics and formats the output
# @date: April 2025
# -------------------------------------------------------------------------------

#' @description
#' This function calculates excess hospitalization metrics by comparing observed values against expected values and their confidence intervals. 
#' It computes excess counts, percentages, and their uncertainty bounds, then formats them into interpretable strings for reporting.
#'
#' @param df A dataframe containing the observed and expected values, along with confidence intervals.
#' @param observed String specifying the column name of the observed values (e.g., actual hospitalizations).
#' @param expected String specifying the column name of the expected values (e.g., predicted hospitalizations).
#' @param expected_conf_lo String specifying the column name of the lower confidence bound for expected values.
#' @param expected_conf_hi String specifying the column name of the upper confidence bound for expected values.
#'
#' @return A dataframe with the following columns:
#' \itemize{
#' \item \code{observed}: Original observed values (retained for reference).
#' \item \code{expected_CI}: Formatted string of expected values with 95% CI (e.g., \code{"100 (90, 110)"}).
#' \item \code{excess_CI}: Formatted string of excess (observed - expected) with 95% CI.
#' \item \code{excess_pct_CI}: Formatted string of excess percentage (excess/expected × 100) with 95% CI.
#' }
#'
#' @details
#' The function performs the following calculations:
#' 1. Excess Metrics:
#' - Excess counts: \code{excess = observed - expected}
#' - CI_lower: \code{excess_low = observed - expected_conf_hi} (lower excess bound)
#' - CI_upper: \code{excess_up = observed - expected_conf_lo} (upper excess bound)
#' 2. Percentage Excess:
#' - \code{excess_pct = (excess / expected) * 100} (and analogous for bounds).
#' 3. Formatted Outputs:
#' - Combines estimates and CIs into human-readable strings (e.g., \code{"50 (40, 60)"}).
#'
#' @note
#' - Input columns must be numeric. Confidence intervals are rounded to integers for counts and 1 decimal place for percentages.




func_excess_hosp <- function(df, observed, expected, expected_conf_lo, expected_conf_hi) {
  result <- df |>
    mutate(excess = !!sym(observed) - !!sym(expected),
          excess_low = !!sym(observed) - !!sym(expected_conf_hi),
          excess_up = !!sym(observed) - !!sym(expected_conf_lo),
          excess_pct = excess / !!sym(expected) * 100,
          excess_low_pct = excess_low / !!sym(expected) * 100,
          excess_up_pct = excess_up / !!sym(expected) * 100) |>
    mutate(expected_CI = paste0(round(!!sym(expected)),
                                " (",
                                round(!!sym(expected_conf_lo)),
                                ", ",
                                round(!!sym(expected_conf_hi)),
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
    dplyr::select(observed, expected_CI, excess_CI, excess_pct_CI)

  return(result)
}
