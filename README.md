
# PatientProfiles <img src="man/figures/logo.png" align="right" height="200"/>

[![CRAN
status](https://www.r-pkg.org/badges/version/PatientProfiles)](https://CRAN.R-project.org/package=PatientProfiles)
[![R-CMD-check](https://github.com/darwin-eu/PatientProfiles/workflows/R-CMD-check/badge.svg)](https://github.com/darwin-eu/PatientProfiles/actions)
[![Lifecycle:stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![metacran
downloads](https://cranlogs.r-pkg.org/badges/PatientProfiles)](https://cran.r-project.org/package=PatientProfiles)
[![metacran
downloads](https://cranlogs.r-pkg.org/badges/grand-total/PatientProfiles)](https://cran.r-project.org/package=PatientProfiles)

## Package overview

PatientProfiles contains functions for adding characteristics to OMOP
CDM tables containing patient level data (e.g. condition occurrence,
drug exposure, and so on) and OMOP CDM cohort tables. The
characteristics that can be added include an individual´s sex, age, and
days of prior observation Time varying characteristics, such as age, can
be estimated relative to any date in the corresponding table. In
addition, PatientProfiles also provides functionality for identifying
intersections between a cohort table and OMOP CDM tables containing
patient level data or other cohort tables.

## Package installation

You can install the latest version of PatientProfiles like so:

``` r
install.packages("PatientProfiles")
```

## Citation

``` r
citation("PatientProfiles")
#> To cite package 'PatientProfiles' in publications use:
#> 
#>   Català M, Guo Y, Du M, Lopez-Guell K, Burn E, Mercade-Besora N
#>   (????). _PatientProfiles: Identify Characteristics of Patients in the
#>   OMOP Common Data Model_. R package version 1.5.0,
#>   <https://darwin-eu.github.io/PatientProfiles/>.
#> 
#> A BibTeX entry for LaTeX users is
#> 
#>   @Manual{,
#>     title = {PatientProfiles: Identify Characteristics of Patients in the OMOP Common Data Model},
#>     author = {Martí Català and Yuchen Guo and Mike Du and Kim Lopez-Guell and Edward Burn and Nuria Mercade-Besora},
#>     note = {R package version 1.5.0},
#>     url = {https://darwin-eu.github.io/PatientProfiles/},
#>   }
```

## Example usage

### Create a reference to data in the OMOP CDM format

The PatientProfiles package is designed to work with data in the OMOP
CDM format, so our first step is to create a reference to the data using
the CDMConnector package.

``` r
library(PatientProfiles)
library(dplyr)
```

Creating a connection to a Postgres database would for example look
like:

``` r
library(RPostgres)
library(CDMConnector)

con <- dbConnect(
  drv = Postgres(),
  dbname = Sys.getenv("CDM5_POSTGRESQL_DBNAME"),
  host = Sys.getenv("CDM5_POSTGRESQL_HOST"),
  user = Sys.getenv("CDM5_POSTGRESQL_USER"),
  password = Sys.getenv("CDM5_POSTGRESQL_PASSWORD")
)

cdm <- cdmFromCon(
  con = con,
  cdmSchema = Sys.getenv("CDM5_POSTGRESQL_CDM_SCHEMA"),
  writeSchema = Sys.getenv("CDM5_POSTGRESQL_RESULT_SCHEMA")
)
```

To see how you would create a reference to your database please consult
the CDMConnector package
[documentation](https://darwin-eu.github.io/CDMConnector/articles/a04_DBI_connection_examples.html).
For this example though we’ll work with simulated data, and we’ll
generate an example cdm reference like so:

``` r
cdm <- mockPatientProfiles(numberIndividuals = 1000, source = "duckdb")
```

### Filtering Current Events (IOMED Specific)

If you are working with an IOMED database where both current events and
medical history are stored in the same clinical tables, you can use the
`filterCurrentEvents()` function to ensure PatientProfiles only uses
current events when computing intersections.

``` r
cdm <- filterCurrentEvents(cdm, method = "datetime")
```

### Adding individuals´ characteristics

#### Adding characteristics to patient-level data

Say we wanted to get individuals´sex and age at condition start date for
records in the condition occurrence table. We can use the `addAge` and
`addSex` functions to do this:

``` r
cdm$condition_occurrence |>
  glimpse()
#> Rows: ??
#> Columns: 6
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ person_id                 <int> 942, 543, 509, 530, 712, 29, 554, 690, 248, …
#> $ condition_start_date      <date> 1927-03-25, 1978-07-17, 1956-03-19, 1963-04…
#> $ condition_end_date        <date> 1930-08-10, 1978-07-20, 1960-07-26, 1976-06…
#> $ condition_occurrence_id   <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 1…
#> $ condition_concept_id      <int> 10, 9, 2, 9, 6, 7, 7, 10, 4, 7, 8, 9, 1, 5, …
#> $ condition_type_concept_id <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…

cdm$condition_occurrence <- cdm$condition_occurrence |>
  addAge(indexDate = "condition_start_date") |>
  addSex()

cdm$condition_occurrence |>
  glimpse()
#> Rows: ??
#> Columns: 8
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ person_id                 <int> 4, 5, 6, 7, 17, 27, 29, 36, 37, 39, 42, 45, …
#> $ condition_start_date      <date> 1992-11-20, 1986-03-12, 1983-05-15, 1925-03…
#> $ condition_end_date        <date> 1993-01-13, 1986-03-30, 1984-02-27, 1927-04…
#> $ condition_occurrence_id   <int> 16, 204, 103, 192, 168, 117, 6, 99, 223, 73,…
#> $ condition_concept_id      <int> 3, 4, 8, 1, 5, 5, 7, 7, 3, 10, 10, 5, 7, 7, …
#> $ condition_type_concept_id <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
#> $ age                       <int> 35, 43, 9, 19, 19, 15, 0, 3, 14, 10, 29, 2, …
#> $ sex                       <chr> "Female", "Female", "Male", "Male", "Male", …
```

We could, for example, then limit our data to only males aged between 18
and 65

``` r
cdm$condition_occurrence |>
  filter(age >= 18 & age <= 65) |>
  filter(sex == "Male")
#> # Source:   SQL [?? x 8]
#> # Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#>    person_id condition_start_date condition_end_date condition_occurrence_id
#>        <int> <date>               <date>                               <int>
#>  1         7 1925-03-25           1927-04-24                             192
#>  2        17 1982-03-02           2003-10-20                             168
#>  3        42 1930-12-18           1942-01-29                             148
#>  4        89 1993-12-02           1996-10-10                              92
#>  5       100 1943-02-26           1948-09-13                              20
#>  6       112 1982-10-03           1986-04-18                              53
#>  7       134 1988-04-23           1995-12-05                             190
#>  8       144 2003-02-12           2015-01-15                              91
#>  9       186 1983-11-07           1984-09-16                              38
#> 10       210 1975-01-04           1979-12-18                             247
#> # ℹ more rows
#> # ℹ 4 more variables: condition_concept_id <int>,
#> #   condition_type_concept_id <int>, age <int>, sex <chr>
```

#### Adding characteristics of a cohort

As with other tables in the OMOP CDM, we can work in a similar way with
cohort tables. For example, say we have the below cohort table

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 1, 1, 2, 1, 1, 1, 2, 3, 1, 1, 3, 1, 3, 1, 3, 1, 1…
#> $ subject_id           <int> 851, 843, 650, 481, 789, 454, 364, 250, 838, 717,…
#> $ cohort_start_date    <date> 1972-05-12, 1950-07-01, 1921-08-04, 1962-12-27, …
#> $ cohort_end_date      <date> 1972-05-28, 1952-04-19, 1933-02-01, 1968-04-29, …
```

We can add age, age groups, sex, and days of prior observation to a
cohort like so

``` r
cdm$cohort1 <- cdm$cohort1 |>
  addAge(
    indexDate = "cohort_start_date",
    ageGroup = list(c(0, 18), c(19, 65), c(66, 100))
  ) |>
  addSex() |>
  addPriorObservation()

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 8
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 1, 1, 2, 1, 1, 1, 2, 3, 1, 1, 3, 1, 3, 1, 3, 1, 1…
#> $ subject_id           <int> 851, 843, 650, 481, 789, 454, 364, 250, 838, 717,…
#> $ cohort_start_date    <date> 1972-05-12, 1950-07-01, 1921-08-04, 1962-12-27, …
#> $ cohort_end_date      <date> 1972-05-28, 1952-04-19, 1933-02-01, 1968-04-29, …
#> $ age                  <int> 6, 5, 1, 18, 7, 4, 15, 14, 18, 25, 16, 12, 3, 8, …
#> $ age_group            <chr> "0 to 18", "0 to 18", "0 to 18", "0 to 18", "0 to…
#> $ sex                  <chr> "Male", "Female", "Male", "Male", "Female", "Male…
#> $ prior_observation    <int> 2323, 2007, 581, 6935, 2616, 1504, 5711, 5474, 67…
```

We could use this information to subset the cohort. For example limiting
to those with at least 365 days of prior observation available before
their cohort start date like so

``` r
cdm$cohort1 |>
  filter(prior_observation >= 365)
#> # Source:   SQL [?? x 8]
#> # Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#>    cohort_definition_id subject_id cohort_start_date cohort_end_date   age
#>                   <int>      <int> <date>            <date>          <int>
#>  1                    1        851 1972-05-12        1972-05-28          6
#>  2                    1        843 1950-07-01        1952-04-19          5
#>  3                    2        650 1921-08-04        1933-02-01          1
#>  4                    1        481 1962-12-27        1968-04-29         18
#>  5                    1        789 1908-03-01        1910-11-29          7
#>  6                    1        454 1972-02-13        1974-05-06          4
#>  7                    2        364 1973-08-21        2007-07-05         15
#>  8                    3        250 1966-12-27        1969-09-28         14
#>  9                    1        838 1934-06-03        1947-01-03         18
#> 10                    1        717 1965-08-25        1981-10-15         25
#> # ℹ more rows
#> # ℹ 3 more variables: age_group <chr>, sex <chr>, prior_observation <int>
```

### Cohort intersections

#### Detect the presence of another cohort in a certain window

We can use `addCohortIntersectFlag` to add a flag for the presence (or
not) of a cohort in a certain window.

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 1, 3, 3, 1, 1, 2, 3, 1, 3
#> $ subject_id           <int> 5, 1, 6, 7, 8, 10, 3, 4, 9, 2
#> $ cohort_start_date    <date> 2003-02-17, 1956-04-12, 1977-03-01, 1922-08-31, 2…
#> $ cohort_end_date      <date> 2006-05-15, 1958-01-04, 1984-10-15, 1926-06-21, 2…

cdm$cohort1 <- cdm$cohort1 |>
  addCohortIntersectFlag(
    targetCohortTable = "cohort2",
    window = c(-Inf, -1)
  )

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 7
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 1, 3, 3, 1, 2, 2, 1, 3, 1, 3
#> $ subject_id           <int> 1, 6, 7, 8, 3, 5, 10, 4, 9, 2
#> $ cohort_start_date    <date> 1956-04-12, 1977-03-01, 1922-08-31, 2010-08-15, 1…
#> $ cohort_end_date      <date> 1958-01-04, 1984-10-15, 1926-06-21, 2017-12-14, 1…
#> $ cohort_3_minf_to_m1  <dbl> 1, 1, 0, 1, 0, 0, 0, 0, 0, 0
#> $ cohort_2_minf_to_m1  <dbl> 0, 0, 1, 0, 1, 0, 0, 0, 0, 0
#> $ cohort_1_minf_to_m1  <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
```

#### Count appearances of a certain cohort in a certain window

If we wanted the number of appearances, we could instead use the
`addCohortIntersectCount` function

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 3, 2, 2, 2, 3, 1, 2, 3, 2
#> $ subject_id           <int> 10, 1, 2, 3, 9, 5, 7, 4, 8, 6
#> $ cohort_start_date    <date> 1948-01-08, 1947-07-17, 1967-01-30, 1976-01-15, 1…
#> $ cohort_end_date      <date> 1955-09-01, 1971-09-16, 1977-01-27, 1976-08-19, 1…

cdm$cohort1 <- cdm$cohort1 |>
  addCohortIntersectCount(
    targetCohortTable = "cohort2",
    targetCohortId = 1,
    window = list("short_term" = c(1, 30), "mid_term" = c(31, 180))
  )

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 6
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 3, 2, 2, 2, 3, 1, 2, 3, 2
#> $ subject_id           <int> 10, 1, 2, 3, 9, 5, 7, 4, 8, 6
#> $ cohort_start_date    <date> 1948-01-08, 1947-07-17, 1967-01-30, 1976-01-15, 1…
#> $ cohort_end_date      <date> 1955-09-01, 1971-09-16, 1977-01-27, 1976-08-19, 1…
#> $ cohort_1_short_term  <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
#> $ cohort_1_mid_term    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
```

#### Add a column with the first/last event in a certain window

Say we wanted the date at which an individual was in another cohort then
we can use the `addCohortIntersectDate` function. As there might be
multiple records for the other cohort, we can also choose the first or
the last appearance in that cohort.

First occurrence:

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 3, 1, 3, 2, 1, 1, 2, 3, 3
#> $ subject_id           <int> 8, 6, 7, 3, 5, 4, 2, 1, 10, 9
#> $ cohort_start_date    <date> 1974-04-05, 1964-09-03, 1934-05-28, 1932-07-31, 1…
#> $ cohort_end_date      <date> 1975-08-14, 1968-02-05, 1937-08-26, 1936-10-12, 1…

cdm$cohort1 <- cdm$cohort1 |>
  addCohortIntersectDate(
    targetCohortTable = "cohort2",
    targetCohortId = 1,
    order = "first",
    window = c(-Inf, Inf)
  )

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 5
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 1, 3, 1, 3, 2, 1, 2, 3, 3
#> $ subject_id           <int> 8, 4, 6, 7, 3, 5, 2, 1, 10, 9
#> $ cohort_start_date    <date> 1974-04-05, 1964-06-04, 1964-09-03, 1934-05-28, 1…
#> $ cohort_end_date      <date> 1975-08-14, 1968-07-20, 1968-02-05, 1937-08-26, 1…
#> $ cohort_1_minf_to_inf <date> 1975-08-08, 1969-04-15, NA, NA, NA, NA, NA, NA, …
```

Last occurrence:

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 1, 3, 3, 2, 3, 3, 3, 2, 2, 2
#> $ subject_id           <int> 3, 2, 1, 4, 7, 6, 10, 5, 9, 8
#> $ cohort_start_date    <date> 1928-11-19, 1977-02-23, 1924-02-06, 1947-02-17, 1…
#> $ cohort_end_date      <date> 1930-04-22, 1977-12-10, 1925-09-21, 1949-07-22, 1…

cdm$cohort1 <- cdm$cohort1 |>
  addCohortIntersectDate(
    targetCohortTable = "cohort2",
    targetCohortId = 1,
    order = "last",
    window = c(-Inf, Inf)
  )

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 5
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 3, 2, 2, 1, 3, 3, 3, 3, 2
#> $ subject_id           <int> 4, 7, 5, 9, 3, 2, 1, 6, 10, 8
#> $ cohort_start_date    <date> 1947-02-17, 1977-02-13, 1941-10-26, 1934-03-23, 1…
#> $ cohort_end_date      <date> 1949-07-22, 1989-06-18, 1963-01-11, 1934-08-24, 1…
#> $ cohort_1_minf_to_inf <date> 1936-01-20, 1967-07-18, 1945-06-26, 1937-12-17, …
```

#### Add the number of days instead of the date

Instead of returning a date, we could return the days to the
intersection by using `addCohortIntersectDays`

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 1, 1, 1, 2, 1, 1, 3, 2, 1
#> $ subject_id           <int> 6, 4, 3, 2, 7, 9, 10, 1, 5, 8
#> $ cohort_start_date    <date> 1968-08-21, 1964-12-02, 1940-10-01, 1938-10-10, 1…
#> $ cohort_end_date      <date> 1972-07-17, 1965-07-19, 1942-07-25, 1962-04-22, 1…

cdm$cohort1 <- cdm$cohort1 |>
  addCohortIntersectDays(
    targetCohortTable = "cohort2",
    targetCohortId = 1,
    order = "last",
    window = c(-Inf, Inf)
  )

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 5
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 2, 1, 1, 1, 1, 2, 1, 3, 2, 1
#> $ subject_id           <int> 6, 4, 3, 2, 9, 7, 10, 1, 5, 8
#> $ cohort_start_date    <date> 1968-08-21, 1964-12-02, 1940-10-01, 1938-10-10, 1…
#> $ cohort_end_date      <date> 1972-07-17, 1965-07-19, 1942-07-25, 1962-04-22, 1…
#> $ cohort_1_minf_to_inf <dbl> 427, -1174, 1622, -3379, -8852, NA, NA, NA, NA, NA
```

#### Combine multiple cohort intersects

If we want to combine multiple cohort intersects we can concatenate the
operations using the `pipe` operator:

``` r
cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 4
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 3, 1, 3, 1, 3, 2, 3, 1, 3, 2
#> $ subject_id           <int> 8, 1, 2, 10, 6, 9, 7, 4, 3, 5
#> $ cohort_start_date    <date> 1962-05-03, 1947-12-29, 1937-04-08, 1990-05-28, 1…
#> $ cohort_end_date      <date> 1964-06-21, 1956-07-27, 1946-08-27, 1990-07-01, 1…

cdm$cohort1 <- cdm$cohort1 |>
  addCohortIntersectDate(
    targetCohortTable = "cohort2",
    targetCohortId = 1,
    order = "last",
    window = c(-Inf, Inf)
  ) |>
  addCohortIntersectCount(
    targetCohortTable = "cohort2",
    targetCohortId = 1,
    window = c(-Inf, Inf)
  )

cdm$cohort1 |>
  glimpse()
#> Rows: ??
#> Columns: 5
#> Database: DuckDB 1.4.0 [gabriel.maeztu@Darwin 25.3.0:R 4.5.2/:memory:]
#> $ cohort_definition_id <int> 1, 3, 3, 3, 1, 2, 3, 1, 3, 2
#> $ subject_id           <int> 1, 6, 8, 2, 10, 9, 7, 4, 3, 5
#> $ cohort_start_date    <date> 1947-12-29, 1949-04-24, 1962-05-03, 1937-04-08, 1…
#> $ cohort_end_date      <date> 1956-07-27, 1950-04-05, 1964-06-21, 1946-08-27, 1…
#> $ cohort_1_minf_to_inf <dbl> 1, 1, 0, 0, 0, 0, 0, 0, 0, 0
```

``` r
mockDisconnect(cdm)
```
