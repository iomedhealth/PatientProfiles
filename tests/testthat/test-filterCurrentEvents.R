test_that("filterCurrentEvents works with datetime method", {
  cdm <- mockPatientProfiles(source = "duckdb")

  mock_conditions <- dplyr::tibble(
    condition_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    condition_concept_id = c(1L, 1L, 1L),
    condition_start_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    condition_start_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    condition_end_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    condition_end_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    condition_type_concept_id = c(32831L, 2100000506L, 32831L)
  )
  
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "condition_occurrence", table = mock_conditions, overwrite = TRUE)
  
  cdm_filtered <- filterCurrentEvents(cdm, method = "datetime")
  
  res <- cdm_filtered$condition_occurrence |> dplyr::collect()
  
  expect_equal(nrow(res), 2)
  expect_true(1L %in% res$condition_occurrence_id)
  expect_true(3L %in% res$condition_occurrence_id)
  expect_false(2L %in% res$condition_occurrence_id)
  
  omopgenerics::cdmDisconnect(cdm)
})

test_that("filterCurrentEvents works with type_concept_id method", {
  cdm <- mockPatientProfiles(source = "duckdb")

  mock_conditions <- dplyr::tibble(
    condition_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    condition_concept_id = c(1L, 1L, 1L),
    condition_start_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    condition_start_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    condition_end_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    condition_end_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    condition_type_concept_id = c(32831L, 2100000506L, 32831L)
  )
  
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "condition_occurrence", table = mock_conditions, overwrite = TRUE)
  
  cdm_filtered <- filterCurrentEvents(cdm, method = "type_concept_id")
  
  res <- cdm_filtered$condition_occurrence |> dplyr::collect()
  
  expect_equal(nrow(res), 2)
  expect_true(1L %in% res$condition_occurrence_id)
  expect_true(3L %in% res$condition_occurrence_id)
  expect_false(2L %in% res$condition_occurrence_id)
  
  omopgenerics::cdmDisconnect(cdm)
})

test_that("filterCurrentEvents works across multiple tables", {
  cdm <- mockPatientProfiles(source = "duckdb")

  mock_conditions <- dplyr::tibble(
    condition_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    condition_concept_id = c(1L, 1L, 1L),
    condition_start_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    condition_start_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    condition_end_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    condition_end_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    condition_type_concept_id = c(32831L, 2100000506L, 32831L)
  )
  
  mock_procedures <- dplyr::tibble(
    procedure_occurrence_id = c(1L, 2L, 3L),
    person_id = c(1L, 1L, 1L),
    procedure_concept_id = c(1L, 1L, 1L),
    procedure_date = as.Date(c("2020-01-01", "2012-01-01", "2021-01-01")),
    procedure_datetime = as.POSIXct(c("2020-01-01 10:00:00", "2018-01-01 10:00:00", NA), tz = "UTC"),
    procedure_type_concept_id = c(32831L, 2100000506L, 32831L)
  )

  cdm <- omopgenerics::insertTable(cdm = cdm, name = "condition_occurrence", table = mock_conditions, overwrite = TRUE)
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "procedure_occurrence", table = mock_procedures, overwrite = TRUE)
  
  person_count <- cdm$person |> dplyr::tally() |> dplyr::pull()
  
  # Method datetime
  cdm_datetime <- filterCurrentEvents(cdm, method = "datetime")
  res_cond <- cdm_datetime$condition_occurrence |> dplyr::collect()
  res_proc <- cdm_datetime$procedure_occurrence |> dplyr::collect()
  res_person <- cdm_datetime$person |> dplyr::tally() |> dplyr::pull()
  
  expect_equal(nrow(res_cond), 2)
  expect_false(2L %in% res_cond$condition_occurrence_id)
  
  expect_equal(nrow(res_proc), 2)
  expect_false(2L %in% res_proc$procedure_occurrence_id)
  
  expect_equal(res_person, person_count) # Unaffected tables should be identical

  # Method type_concept_id
  cdm_type <- filterCurrentEvents(cdm, method = "type_concept_id")
  res_cond2 <- cdm_type$condition_occurrence |> dplyr::collect()
  res_proc2 <- cdm_type$procedure_occurrence |> dplyr::collect()
  
  expect_equal(nrow(res_cond2), 2)
  expect_false(2L %in% res_cond2$condition_occurrence_id)
  
  expect_equal(nrow(res_proc2), 2)
  expect_false(2L %in% res_proc2$procedure_occurrence_id)
  
  omopgenerics::cdmDisconnect(cdm)
})

test_that("filterCurrentEvents edge cases", {
  cdm <- mockPatientProfiles(source = "duckdb")

  mock_device <- dplyr::tibble(
    device_exposure_id = c(1L, 2L),
    person_id = c(1L, 1L),
    device_concept_id = c(1L, 1L),
    device_exposure_start_date = as.Date(c("2020-01-01", "2012-01-01")),
    device_exposure_end_date = as.Date(c("2020-01-01", "2012-01-01")),
    device_type_concept_id = c(32831L, 32831L),
    # missing device_exposure_start_datetime
  )
  
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "device_exposure", table = mock_device, overwrite = TRUE)
  
  cdm_filtered1 <- filterCurrentEvents(cdm, method = "datetime")
  cdm_filtered2 <- filterCurrentEvents(cdm, method = "type_concept_id")
  
  expect_equal(cdm_filtered1$device_exposure |> dplyr::tally() |> dplyr::pull(), 2)
  expect_equal(cdm_filtered2$device_exposure |> dplyr::tally() |> dplyr::pull(), 2)

  omopgenerics::cdmDisconnect(cdm)
})
