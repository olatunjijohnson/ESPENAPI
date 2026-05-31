#' NTD indicators available via the WHO GHO API
#'
#' Returns a reference table mapping ESPEN disease codes to their
#' corresponding WHO Global Health Observatory (GHO) indicator codes.
#' The GHO API is publicly accessible with no authentication required.
#'
#' @details
#' The GHO API covers **national-level** NTD programme indicators (treatment
#' numbers, endemicity status, populations requiring treatment). It does not
#' contain the site-level survey data (sample sizes, prevalence) available
#' through ESPEN.
#'
#' Diseases with no GHO coverage (\code{NA} indicator codes) can only be
#' accessed via the ESPEN API.
#'
#' @return A data frame with columns \code{espen_code}, \code{disease_name},
#'   \code{gho_code}, \code{gho_name}, and \code{gho_available}.
#' @export
#' @seealso \code{\link{gho_ntd_data}} to download data using these codes.
#' @examples
#' gho_ntd_indicators()
gho_ntd_indicators <- function() {
  data.frame(
    espen_code   = c("oncho",    "oncho",   "oncho",
                     "trachoma", "trachoma", "trachoma", "trachoma",
                     "lf",  "sth", "sch", "loa", "coendemicity"),
    disease_name = c(
      "Onchocerciasis", "Onchocerciasis", "Onchocerciasis",
      "Trachoma", "Trachoma", "Trachoma", "Trachoma",
      "Lymphatic filariasis", "Soil-transmitted helminths",
      "Schistosomiasis", "Loiasis", "Co-endemicity"
    ),
    gho_code     = c(
      "NTD_ONCTREAT",  "NTD_ONCHSTATUS", "NTD_ONCHEMO",
      "NTD_8",         "NTD_7",          "NTD_6",    "NTD_TRA5",
      NA, NA, NA, NA, NA
    ),
    gho_name     = c(
      "Number of individuals treated for onchocerciasis",
      "Status of endemicity of onchocerciasis",
      "Number requiring preventive chemotherapy for onchocerciasis",
      "Number of people treated with antibiotics for trachoma",
      "Population in areas warranting treatment for trachoma",
      "Status of elimination of trachoma as a public health problem",
      "Number of people operated for trachomatous trichiasis",
      NA, NA, NA, NA, NA
    ),
    gho_available = c(
      TRUE, TRUE, TRUE,
      TRUE, TRUE, TRUE, TRUE,
      FALSE, FALSE, FALSE, FALSE, FALSE
    ),
    stringsAsFactors = FALSE
  )
}

#' Download NTD data from the WHO Global Health Observatory API
#'
#' Queries the WHO GHO OData API for NTD-related indicators. No API key or
#' authentication is required. Use \code{\link{gho_ntd_indicators}()} to see
#' which indicators are available and their GHO codes.
#'
#' @details
#' The GHO API provides **national-level** aggregated indicators such as
#' treatment numbers and endemicity status. It does not contain site-level
#' survey data. For site-level data (prevalence, sample sizes), the ESPEN
#' API is required — see \code{\link{ESPEN_API_data}}.
#'
#' The full GHO OData API documentation is at
#' \url{https://www.who.int/data/gho/info/gho-odata-api}.
#'
#' @param indicator Character. One or more GHO indicator codes, e.g.
#'   \code{"NTD_ONCTREAT"}. Use \code{\link{gho_ntd_indicators}()} for a
#'   full list. A vector of codes returns a combined data frame.
#' @param country Character. Optional ISO3 country code(s) to filter by,
#'   e.g. \code{"NGA"} or \code{c("NGA", "GHA", "KEN")}. Default
#'   \code{NULL} returns all countries.
#' @param start_year Integer. Optional lower year bound (inclusive).
#' @param end_year Integer. Optional upper year bound (inclusive).
#' @param verbose Logical. Print progress when downloading multiple
#'   indicators. Default \code{FALSE}.
#'
#' @return A data frame with columns: \code{indicator_code},
#'   \code{indicator_name}, \code{country_iso3}, \code{year},
#'   \code{value}, \code{low}, \code{high}, \code{comments}.
#'
#' @export
#' @importFrom httr GET http_type http_error status_code
#' @importFrom jsonlite fromJSON
#' @seealso \code{\link{gho_ntd_indicators}} for available indicator codes.
#' @examples
#' \dontrun{
#' # Onchocerciasis treatment data — no API key needed
#' oncho <- gho_ntd_data("NTD_ONCTREAT")
#' head(oncho)
#'
#' # Filter to specific countries and years
#' oncho_wa <- gho_ntd_data(
#'   indicator  = "NTD_ONCTREAT",
#'   country    = c("NGA", "GHA", "CMR"),
#'   start_year = 2015,
#'   end_year   = 2022
#' )
#'
#' # Multiple indicators at once
#' oncho_all <- gho_ntd_data(
#'   indicator = c("NTD_ONCTREAT", "NTD_ONCHSTATUS", "NTD_ONCHEMO"),
#'   verbose   = TRUE
#' )
#'
#' # Trachoma data
#' trachoma <- gho_ntd_data(
#'   indicator  = "NTD_8",
#'   start_year = 2015,
#'   end_year   = 2022
#' )
#' }
gho_ntd_data <- function(indicator,
                         country    = NULL,
                         start_year = NULL,
                         end_year   = NULL,
                         verbose    = FALSE) {

  if (missing(indicator) || length(indicator) == 0)
    stop("Provide at least one indicator code. ",
         "Run gho_ntd_indicators() to see available codes.", call. = FALSE)

  if (length(indicator) > 1) {
    if (verbose)
      message("Downloading ", length(indicator), " GHO indicators...")
    results <- lapply(indicator, function(ind) {
      if (verbose) message("  Fetching: ", ind)
      gho_ntd_data(indicator = ind, country = country,
                   start_year = start_year, end_year = end_year)
    })
    return(do.call(rbind, results))
  }

  # Build OData $filter string
  filters <- character(0)

  filters <- c(filters, "SpatialDimType eq 'COUNTRY'")

  if (!is.null(country)) {
    iso3_list <- paste0("'", toupper(country), "'", collapse = ", ")
    filters   <- c(filters, paste0("SpatialDim in (", iso3_list, ")"))
  }

  if (!is.null(start_year))
    filters <- c(filters, paste0("TimeDim ge ", as.integer(start_year)))

  if (!is.null(end_year))
    filters <- c(filters, paste0("TimeDim le ", as.integer(end_year)))

  filter_str <- paste(filters, collapse = " and ")
  url <- paste0(
    "https://ghoapi.azureedge.net/api/", indicator,
    "?$filter=", utils::URLencode(filter_str, reserved = TRUE),
    "&$select=SpatialDim,ParentLocation,TimeDim,Value,NumericValue,Low,High,Comments"
  )

  res <- httr::GET(url)

  if (httr::http_type(res) != "application/json")
    stop("GHO API did not return JSON.", call. = FALSE)

  if (httr::http_error(res)) {
    body <- rawToChar(res$content)
    msg  <- tryCatch(
      jsonlite::fromJSON(body)[["message"]] %||% body,
      error = function(e) body
    )
    stop(sprintf("GHO API request failed [%s]: %s",
                 httr::status_code(res), msg), call. = FALSE)
  }

  parsed <- jsonlite::fromJSON(rawToChar(res$content))
  rows   <- parsed[["value"]]

  if (is.null(rows) || nrow(rows) == 0) {
    message("No data returned for indicator '", indicator,
            "' with the given filters.")
    return(
      data.frame(
        indicator_code = character(), indicator_name = character(),
        country_iso3   = character(), who_region     = character(),
        year           = integer(),   value          = numeric(),
        value_text     = character(), low            = numeric(),
        high           = numeric(),   comments       = character(),
        stringsAsFactors = FALSE
      )
    )
  }

  # Look up the human-readable name from our indicator table
  ind_table  <- gho_ntd_indicators()
  ind_name   <- ind_table$gho_name[match(indicator, ind_table$gho_code)]
  if (is.na(ind_name) || length(ind_name) == 0) ind_name <- indicator

  data.frame(
    indicator_code = indicator,
    indicator_name = ind_name[1],
    country_iso3   = rows$SpatialDim,
    who_region     = if ("ParentLocation" %in% names(rows)) rows$ParentLocation else NA_character_,
    year           = as.integer(rows$TimeDim),
    value          = rows$NumericValue,
    value_text     = if ("Value"    %in% names(rows)) rows$Value    else NA_character_,
    low            = if ("Low"      %in% names(rows)) rows$Low      else NA_real_,
    high           = if ("High"     %in% names(rows)) rows$High     else NA_real_,
    comments       = if ("Comments" %in% names(rows)) rows$Comments else NA_character_,
    stringsAsFactors = FALSE
  )
}
