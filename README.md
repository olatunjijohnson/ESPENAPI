
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ESPENAPI

<!-- badges: start -->

<!-- badges: end -->

The goal of ESPENAPI is to provide access to Neglected Tropical Diseases
(NTDs) data from the ESPEN portal and provide a minimum
visualisation/summary of the data. Instead of having to visit the ESPEN
portal to download the data, this R package allows the user to acquire
the data and process it directly from R. A web application to visualise
the data is currently under development, a preliminary version can be
found here
<https://olatunjijohnson.shinyapps.io/espenshiny/>

## Installation

<!-- You can install the released version of ESPENAPI from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("ESPENAPI")
```
-->

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("olatunjijohnson/ESPENAPI", ref="main")
```

## Set up ESPEN API key

In order to access the ESPEN Platform APIs, you must first request an
API key from the [ESPENE
website](https://admin.espen.afro.who.int/docs/api).

Although it is possible to provide the ESPEN API key as a function
argument we recommend to store it safely in the R environment. A quick
way to do this is by using the `edit_r_environ` function from the
`usethis` package.

``` r
usethis::edit_r_environ()
```

This will open the `.Renviron` file for editing. Add this line to store
your key:

    ESPEN_API_KEY="my_key"

save it and restart R for changes to take effect.

## Example

This is a basic example which shows how to download the STH data at site
level from Kenya for 2010.

``` r
library(ESPENAPI)
data  <- ESPENAPI::ESPEN_API_data(country = "Kenya", disease = "sth", level = "sitelevel",
                                  start_year = 2010, end_year = 2010)
```

## Further improvements

1.  Develop another function to download maps from ESPEN portal

2.  Develop dashboard to summarise the data
