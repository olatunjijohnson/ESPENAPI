
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ESPENAPI <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/olatunjijohnson/ESPENAPI/workflows/R-CMD-check/badge.svg)](https://github.com/olatunjijohnson/ESPENAPI/actions)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)
<!-- badges: end -->

**ESPENAPI** gives R users access to Neglected Tropical Disease (NTD)
data from two sources:

| Source | Auth needed | Diseases | Level |
|----|----|----|----|
| [ESPEN portal API](https://espen.afro.who.int) | API key | All 7 NTDs | Country + site level |
| [WHO GHO API](https://www.who.int/data/gho/info/gho-odata-api) | **None** | Onchocerciasis, Trachoma | Country level only |

> **Note on ESPEN API keys:** ESPEN has paused issuing new API keys.
> Existing keys may also have expired. If you cannot get a key, use the
> WHO GHO functions (`gho_ntd_data()`) as a no-auth alternative for
> onchocerciasis and trachoma data, or contact the ESPEN team directly
> at <ntd.espen@who.int> to request data access.

------------------------------------------------------------------------

## What is ESPEN?

The **Expanded Special Project for Elimination of Neglected Tropical
Diseases** (ESPEN) is a WHO/AFRO initiative that coordinates NTD
surveillance and control programmes across African countries. The ESPEN
portal hosts:

- **Implementation unit (IU) level data** — MDA coverage and endemicity
  status aggregated to district or sub-district level, used for
  programme planning
- **Site level data** — individual survey results from specific sentinel
  or community sites, containing sample sizes and prevalence estimates

Data is available for seven NTDs across up to 47 African countries,
spanning multiple decades of programme activity.

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("olatunjijohnson/ESPENAPI")
```

------------------------------------------------------------------------

## No API key? Use the WHO GHO alternative

If you cannot get an ESPEN API key, `gho_ntd_data()` provides
**no-authentication** access to country-level onchocerciasis and
trachoma data via the WHO Global Health Observatory API:

``` r
library(ESPENAPI)

# Works immediately — no key, no registration
oncho <- gho_ntd_data(
  indicator  = "NTD_ONCTREAT",
  country    = c("NGA", "GHA", "CMR"),
  start_year = 2015,
  end_year   = 2022
)
head(oncho)

# See which indicators are available
gho_ntd_indicators()
```

See the [WHO GHO section](#who-gho-api-no-key-required) below for full
details.

------------------------------------------------------------------------

## ESPEN API key setup

ESPEN API keys are **currently not being issued**. If you already have a
key or manage to obtain one, store it in your `.Renviron`:

**Step 1** — Request a key at <https://espen.afro.who.int> or email
<ntd.espen@who.int> directly.

**Step 2** — Store it in your `.Renviron` file:

``` r
usethis::edit_r_environ()
```

Add this line, save and restart R:

    ESPEN_API_KEY=your_key_here

**Step 3** — Verify it is found:

``` r
nchar(Sys.getenv("ESPEN_API_KEY")) > 0
#> [1] TRUE
```

All ESPENAPI functions read the key automatically. You only need to pass
`api_key` explicitly if you are managing multiple keys.

For a guided walkthrough, call:

``` r
espen_key_setup()
#> ESPEN API key setup
#> -------------------
#> Step 1: Request a free key from https://espen.afro.who.int
#> ...
```

------------------------------------------------------------------------

## Quick start

``` r
library(ESPENAPI)

# STH survey data for Nigeria at site level, 2010–2015
dat <- ESPEN_API_data(
  country    = "Nigeria",
  disease    = "sth",
  level      = "sitelevel",
  start_year = 2010,
  end_year   = 2015
)

dim(dat)
#> [1] 1842   24

head(dat[, 1:6])
#>   IU_ID        Country  Admin1    Admin2  Year  Prev_1Plus
#> 1  ...   Nigeria        ...       ...     2010  0.42
#> ...
```

------------------------------------------------------------------------

## Reference tables

Two helper functions let you browse valid input values without visiting
the documentation:

``` r
espen_diseases()
#>          code                      name
#> 1          lf      Lymphatic filariasis
#> 2       oncho           Onchocerciasis
#> 3         loa                   Loiasis
#> 4         sch          Schistosomiasis
#> 5         sth Soil-transmitted helminths
#> 6    trachoma                 Trachoma
#> 7 coendemicity            Co-endemicity

espen_levels()
#>       code               name
#> 1       iu Implementation unit
#> 2 sitelevel         Site level
```

------------------------------------------------------------------------

## Detailed examples

### 1. Single country, single disease

The most common use case — download all STH site-level records for a
country within a year range:

``` r
dat <- ESPEN_API_data(
  country    = "Nigeria",
  disease    = "sth",
  level      = "sitelevel",
  start_year = 2010,
  end_year   = 2020
)
nrow(dat)
#> [1] 3214
names(dat)
#>  [1] "IU_ID"       "Country"     "Admin1"      "Admin2"
#>  [5] "Year"        "Prev_1Plus"  "ExaminedNo"  "PositiveNo"
#>  ...
```

Country names are case-insensitive — `"nigeria"`, `"NIGERIA"`, and
`"Nigeria"` all work.

### 2. Multiple countries in one call

Pass a character vector to download data for several countries at once.
The results are combined into a single data frame:

``` r
west_africa <- ESPEN_API_data(
  country    = c("Nigeria", "Ghana", "Senegal", "Cameroon"),
  disease    = "sth",
  level      = "sitelevel",
  start_year = 2015,
  end_year   = 2020,
  verbose    = TRUE        # shows progress per country
)
#> Downloading sth data for 4 countries...
#>   Fetching: Nigeria
#>   Fetching: Ghana
#>   Fetching: Senegal
#>   Fetching: Cameroon

nrow(west_africa)
#> [1] 5628

table(west_africa$Country)
#>  Cameroon     Ghana   Nigeria   Senegal
#>       312       891      3814       611
```

### 3. Using ISO2 country codes

If you prefer working with two-letter country codes, use the `iso2`
argument instead of `country`. Both support vectors:

``` r
dat <- ESPEN_API_data(
  iso2       = c("NG", "GH", "KE", "ET"),
  disease    = "lf",
  level      = "iu",
  start_year = 2010,
  end_year   = 2020
)
table(dat$Country)
#>  Ethiopia     Ghana     Kenya   Nigeria
#>       ...       ...       ...       ...
```

### 4. Implementation unit vs site level

**Use `level = "iu"`** when you want programme-level summaries
(endemicity status, MDA coverage, effective MDA) for planning purposes:

``` r
lf_iu <- ESPEN_API_data(
  country    = "Ghana",
  disease    = "lf",
  level      = "iu",
  start_year = 2015,
  end_year   = 2020
)
# Typical columns at IU level:
names(lf_iu)
#>  [1] "IU_ID"       "Country"     "Admin1"      "Admin2"
#>  [5] "Endemicity"  "MDA"         "EffMDA"      "Year"  ...
```

**Use `level = "sitelevel"`** when you want individual survey data with
sample sizes and prevalence — for epidemiological analysis:

``` r
lf_sites <- ESPEN_API_data(
  country    = "Ghana",
  disease    = "lf",
  level      = "sitelevel",
  start_year = 2015,
  end_year   = 2020
)
# Typical columns at site level:
names(lf_sites)
#>  [1] "IU_ID"       "Country"     "Admin1"      "Site_ID"
#>  [5] "Year"        "ExaminedNo"  "PositiveNo"  "Prev" ...
```

### 5. Different diseases

The `disease` argument accepts any of the seven ESPEN disease codes. Use
`espen_diseases()` as a cheat sheet:

``` r
# Onchocerciasis at site level
oncho <- ESPEN_API_data(
  country    = "Cameroon",
  disease    = "oncho",
  level      = "sitelevel",
  start_year = 2010,
  end_year   = 2020
)

# Schistosomiasis at IU level
sch <- ESPEN_API_data(
  country    = "Ethiopia",
  disease    = "sch",
  level      = "iu",
  start_year = 2015,
  end_year   = 2019
)

# Trachoma at IU level
trachoma <- ESPEN_API_data(
  country = "Niger",
  disease = "trachoma",
  level   = "iu"
)
```

### 6. Forecast data (MDA and impact assessment)

Set `type = TRUE` to request forecast data rather than observed records.
Use `subtype` to choose between MDA plans and impact assessment:

``` r
# MDA forecast
mda_plan <- ESPEN_API_data(
  country = "Nigeria",
  disease = "sth",
  level   = "iu",
  type    = TRUE,
  subtype = "mda"
)

# Impact assessment forecast
impact <- ESPEN_API_data(
  country = "Nigeria",
  disease = "sth",
  level   = "iu",
  type    = TRUE,
  subtype = "impact_assessment"
)
```

### 7. Selecting specific columns

Large downloads can be made leaner by requesting only the columns you
need. Pass a comma-separated string to `attributes`:

``` r
# Only return endemicity and MDA columns at IU level
slim <- ESPEN_API_data(
  country    = "Nigeria",
  disease    = "sth",
  level      = "iu",
  start_year = 2015,
  end_year   = 2020,
  attributes = "IU_ID,Country,Admin1,Admin2,Year,Endemicity,MDA,EffMDA"
)
names(slim)
#> [1] "IU_ID"      "Country"    "Admin1"     "Admin2"
#> [5] "Year"       "Endemicity" "MDA"        "EffMDA"
```

### 8. Pagination for large datasets

For very large queries, use `limit` and `offset` to page through
results:

``` r
# First 500 records
page1 <- ESPEN_API_data(
  country = "Nigeria",
  disease = "sth",
  level   = "sitelevel",
  limit   = 500,
  offset  = 0
)

# Next 500 records
page2 <- ESPEN_API_data(
  country = "Nigeria",
  disease = "sth",
  level   = "sitelevel",
  limit   = 500,
  offset  = 500
)

# Combine
all_records <- rbind(page1, page2)
```

### 9. Accessing the raw JSON response

Set `df = FALSE` to get the raw API response object instead of a parsed
data frame. Useful for debugging or custom parsing:

``` r
raw <- ESPEN_API_data(
  country = "Nigeria",
  disease = "sth",
  df      = FALSE
)

print(raw)
#> <ESPEN API response>
#>   URL     : https://espenjapapi.afro.who.int/api/data?country=Nigeria&...
#>   Status  : 200
#>   Size    : 248,312 characters

# Access the raw JSON string
substr(raw$content, 1, 100)
#> [1] "[{\"IU_ID\":\"NGA...\",\"Country\":\"Nigeria\", ..."

# Access the httr response object
raw$response$status_code
#> [1] 200
```

------------------------------------------------------------------------

## Worked analysis: STH burden across West Africa

A full end-to-end example — download, summarise, and visualise:

``` r
library(ESPENAPI)
library(dplyr)
library(ggplot2)

# Download site-level STH data for five countries
dat <- ESPEN_API_data(
  country    = c("Nigeria", "Ghana", "Senegal", "Mali", "Burkina Faso"),
  disease    = "sth",
  level      = "sitelevel",
  start_year = 2010,
  end_year   = 2020,
  verbose    = TRUE
)

# Summarise: mean prevalence per country per year
summary_dat <- dat %>%
  filter(!is.na(Prev_1Plus)) %>%
  group_by(Country, Year) %>%
  summarise(
    mean_prev  = mean(Prev_1Plus, na.rm = TRUE),
    n_sites    = n(),
    .groups    = "drop"
  )

# Plot trends
ggplot(summary_dat, aes(x = Year, y = mean_prev, colour = Country)) +
  geom_line(linewidth = 0.8) +
  geom_point(aes(size = n_sites), alpha = 0.7) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    title    = "STH prevalence trends — West Africa (2010–2020)",
    subtitle = "Point size proportional to number of survey sites",
    y        = "Mean prevalence (any STH)",
    x        = "Year",
    colour   = "Country",
    size     = "Sites"
  ) +
  theme_bw()
```

------------------------------------------------------------------------

## WHO GHO API — no key required

The WHO [Global Health
Observatory](https://www.who.int/data/gho/info/gho-odata-api) OData API
is publicly accessible with no authentication. The package provides
`gho_ntd_data()` as a no-key alternative for onchocerciasis and trachoma
data.

**Scope of GHO vs ESPEN:**

|  | ESPEN | WHO GHO |
|----|----|----|
| Auth required | Yes (API key) | **No** |
| Diseases | All 7 NTDs | Onchocerciasis, trachoma only |
| Data level | Country + **site level** | Country only |
| Data content | Survey prevalence, MDA records | Treatment numbers, endemicity status |

### GHO examples

``` r
# Onchocerciasis treatment — no API key needed
oncho <- gho_ntd_data(
  indicator  = "NTD_ONCTREAT",
  start_year = 2015,
  end_year   = 2022
)
head(oncho)
#>   indicator_code                    indicator_name country_iso3 year    value
#> 1  NTD_ONCTREAT  Number of individuals treated...          SDN 2024        0
#> 2  NTD_ONCTREAT  Number of individuals treated...          MLI 2021        0
#> 3  NTD_ONCTREAT  Number of individuals treated...          LBR 2024  3115708

# Filter to specific countries
oncho_wa <- gho_ntd_data(
  indicator  = "NTD_ONCTREAT",
  country    = c("NGA", "GHA", "CMR", "CIV"),
  start_year = 2015,
  end_year   = 2022
)

# Multiple indicators at once
oncho_all <- gho_ntd_data(
  indicator = c("NTD_ONCTREAT", "NTD_ONCHSTATUS", "NTD_ONCHEMO"),
  country   = c("NGA", "GHA"),
  verbose   = TRUE
)

# See all available NTD indicators in GHO
gho_ntd_indicators()
```

### Available GHO indicators

    #> Warning in attr(x, "align"): 'xfun::attr()' is deprecated.
    #> Use 'xfun::attr2()' instead.
    #> See help("Deprecated")
    #> Warning in attr(x, "format"): 'xfun::attr()' is deprecated.
    #> Use 'xfun::attr2()' instead.
    #> See help("Deprecated")

| ESPEN disease | GHO code | Description |
|:---|:---|:---|
| oncho | NTD_ONCTREAT | Number of individuals treated for onchocerciasis |
| oncho | NTD_ONCHSTATUS | Status of endemicity of onchocerciasis |
| oncho | NTD_ONCHEMO | Number requiring preventive chemotherapy for onchocerciasis |
| trachoma | NTD_8 | Number of people treated with antibiotics for trachoma |
| trachoma | NTD_7 | Population in areas warranting treatment for trachoma |
| trachoma | NTD_6 | Status of elimination of trachoma as a public health problem |
| trachoma | NTD_TRA5 | Number of people operated for trachomatous trichiasis |

------------------------------------------------------------------------

## Troubleshooting

**`No API key found`** Your key is not in the environment. Run
`usethis::edit_r_environ()`, add `ESPEN_API_KEY=your_key`, save, and
restart R. Verify with `nchar(Sys.getenv("ESPEN_API_KEY")) > 0`.

**`ESPEN API request failed [401]`** Your key is invalid, expired, or
new keys are not currently being issued. Try the WHO GHO alternative
(`gho_ntd_data()`) or contact <ntd.espen@who.int> directly.

**`API did not return JSON`** The ESPEN API endpoint has changed or is
temporarily unavailable. The current endpoint is
`https://espenjapapi.afro.who.int/api/data`.

**`start_year must be <= end_year`** Year arguments are swapped — check
the order.

**Empty data frame returned** The query is valid but no data exists for
that combination of country, disease, level, and year range. Try
widening the year range or switching spatial level.

------------------------------------------------------------------------

## Citation

If you use this package in published research, please cite:

> Johnson, O. (2024). *ESPENAPI: Access NTD Data from the ESPEN Portal
> API* (R package version 0.3.0).
> <https://github.com/olatunjijohnson/ESPENAPI>

------------------------------------------------------------------------

## Contributing

Bug reports and feature requests are welcome at
<https://github.com/olatunjijohnson/ESPENAPI/issues>.
