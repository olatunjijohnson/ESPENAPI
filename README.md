
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ESPENAPI

<!-- badges: start -->

[![R-CMD-check](https://github.com/olatunjijohnson/ESPENAPI/workflows/R-CMD-check/badge.svg)](https://github.com/olatunjijohnson/ESPENAPI/actions)
<!-- badges: end -->

An R package for downloading Neglected Tropical Disease (NTD) data
directly from the [ESPEN portal](https://espen.afro.who.int) API — no
browser, no manual exports.

## Features

- Download data for any ESPEN country with a single function call
- Pass a **vector of countries** and get one combined data frame back
- All **7 NTD disease types**: lf, oncho, loa, sch, sth, trachoma,
  coendemicity
- Both spatial levels: **implementation unit** and **site level**
- Optional **forecast data** (MDA and impact assessment)
- Pagination support for large datasets
- Reference tables: `espen_diseases()`, `espen_levels()`

## Installation

``` r
# install.packages("remotes")
remotes::install_github("olatunjijohnson/ESPENAPI")
```

## API key setup

Request a free API key from <https://espen.afro.who.int>, then store it
in your `.Renviron`:

``` r
usethis::edit_r_environ()
# Add this line: ESPEN_API_KEY=your_key_here
# Save the file and restart R
```

Or call `espen_key_setup()` for step-by-step instructions.

## Usage

### Single country

``` r
library(ESPENAPI)

dat <- ESPEN_API_data(
  country    = "Nigeria",
  disease    = "sth",
  level      = "sitelevel",
  start_year = 2010,
  end_year   = 2015
)
head(dat)
```

### Multiple countries in one call

``` r
multi <- ESPEN_API_data(
  country    = c("Nigeria", "Ghana", "Kenya"),
  disease    = "lf",
  level      = "iu",
  start_year = 2015,
  end_year   = 2020,
  verbose    = TRUE
)
table(multi$Country)
```

### Using ISO2 codes

``` r
dat <- ESPEN_API_data(
  iso2       = c("NG", "GH"),
  disease    = "sth",
  level      = "sitelevel",
  start_year = 2010,
  end_year   = 2010
)
```

### Browse valid options

``` r
espen_diseases()   # all disease codes with full names
espen_levels()     # spatial level descriptions
```

## Available diseases

| Code           | Disease                    |
|----------------|----------------------------|
| `lf`           | Lymphatic filariasis       |
| `oncho`        | Onchocerciasis             |
| `loa`          | Loiasis                    |
| `sch`          | Schistosomiasis            |
| `sth`          | Soil-transmitted helminths |
| `trachoma`     | Trachoma                   |
| `coendemicity` | Co-endemicity              |

## Further information

See `vignette("Introduction", package = "ESPENAPI")` for a full tutorial
covering forecast data, pagination, column filtering, and worked
examples.
