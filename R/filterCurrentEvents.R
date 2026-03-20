# Copyright 2024 DARWIN EU (C)
#
# This file is part of PatientProfiles
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Filter OMOP clinical tables to only include current events
#'
#' @description
#' This function filters out non-current (historical) events from OMOP clinical tables.
#' In some IOMED implementations, "Current Events" are differentiated from 
#' "Medical History" by checking if the start date perfectly matches the start datetime.
#' A new approach will use the `type_concept_id` field.
#' 
#' **Note on First Diagnoses:** If you are trying to find the very first diagnosis 
#' of a patient, be aware that blindly filtering for "Current Events" might 
#' hide previous historical mentions of the condition, making a recent current 
#' event incorrectly appear as the "first" diagnosis.
#'
#' @param cdm A cdm_reference object.
#' @param method Character string specifying the filtering method: "datetime" (default) or "type_concept_id".
#'
#' @return A cdm_reference object with filtered clinical tables.
#' @export
#'
filterCurrentEvents <- function(cdm, method = "datetime") {
  omopgenerics::assertClass(cdm, "cdm_reference")
  omopgenerics::assertChoice(method, choices = c("datetime", "type_concept_id"), length = 1)

  domains <- list(
    "condition_occurrence" = c(date = "condition_start_date", datetime = "condition_start_datetime", type = "condition_type_concept_id"),
    "procedure_occurrence" = c(date = "procedure_date", datetime = "procedure_datetime", type = "procedure_type_concept_id"),
    "observation"          = c(date = "observation_date", datetime = "observation_datetime", type = "observation_type_concept_id"),
    "drug_exposure"        = c(date = "drug_exposure_start_date", datetime = "drug_exposure_start_datetime", type = "drug_type_concept_id"),
    "measurement"          = c(date = "measurement_date", datetime = "measurement_datetime", type = "measurement_type_concept_id"),
    "visit_occurrence"     = c(date = "visit_start_date", datetime = "visit_start_datetime", type = "visit_type_concept_id"),
    "device_exposure"      = c(date = "device_exposure_start_date", datetime = "device_exposure_start_datetime", type = "device_type_concept_id"),
    "specimen"             = c(date = "specimen_date", datetime = "specimen_datetime", type = "specimen_type_concept_id"),
    "note"                 = c(date = "note_date", datetime = "note_datetime", type = "note_type_concept_id"),
    "episode"              = c(date = "episode_start_date", datetime = "episode_start_datetime", type = "episode_type_concept_id")
  )

  for (tableName in names(domains)) {
    if (tableName %in% names(cdm)) {
      date_col <- domains[[tableName]]["date"]
      datetime_col <- domains[[tableName]]["datetime"]
      type_col <- domains[[tableName]]["type"]

      table_cols <- colnames(cdm[[tableName]])

      if (method == "datetime") {
        if (date_col %in% table_cols && datetime_col %in% table_cols) {
          cdm[[tableName]] <- cdm[[tableName]] |>
            dplyr::filter(
              .data[[date_col]] == as.Date(.data[[datetime_col]]) |
                is.na(.data[[datetime_col]])
            )
        }
      } else if (method == "type_concept_id") {
        if (type_col %in% table_cols) {
          historical_concept_id <- 2100000506L
          cdm[[tableName]] <- cdm[[tableName]] |>
            dplyr::filter(.data[[type_col]] != .env$historical_concept_id)
        }
      }
    }
  }

  return(cdm)
}
