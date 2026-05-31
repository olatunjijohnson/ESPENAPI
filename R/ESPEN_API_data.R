#' Download NTD data from the ESPEN portal
#'
#' Fetches Neglected Tropical Disease (NTD) data from the ESPEN portal API
#' for one or more countries. The function accepts a vector of country names
#' or ISO2 codes and returns a single combined data frame.
#'
#' @details
#' An API key is required. Run \code{\link{espen_key_setup}()} for setup
#' instructions, or see the package documentation.
#'
#' Use \code{\link{espen_diseases}()} and \code{\link{espen_levels}()} to
#' browse valid values for the \code{disease} and \code{level} arguments.
#'
#' @param api_key API key from the ESPEN portal. Defaults to \code{NULL},
#'   which reads the \code{ESPEN_API_KEY} environment variable.
#' @param country Character. Country name(s), e.g. \code{"Nigeria"} or
#'   \code{c("Nigeria", "Ghana", "Kenya")}. Case-insensitive. Either
#'   \code{country} or \code{iso2} must be supplied, not both.
#' @param iso2 Character. ISO2 country code(s), e.g. \code{"NG"} or
#'   \code{c("NG", "GH")}. Used only when \code{country} is \code{NULL}.
#' @param disease Disease code. One of \code{"lf"}, \code{"oncho"},
#'   \code{"loa"}, \code{"sch"}, \code{"sth"}, \code{"trachoma"},
#'   \code{"coendemicity"}. Default \code{"sth"}.
#'   See \code{\link{espen_diseases}()} for full names and descriptions.
#' @param level Spatial level. \code{"iu"} (implementation unit) or
#'   \code{"sitelevel"}. Default \code{"sitelevel"}.
#'   See \code{\link{espen_levels}()} for descriptions.
#' @param type Logical. \code{TRUE} to request forecast data (MDA or impact
#'   assessment). Default \code{FALSE}.
#' @param subtype Used only when \code{type = TRUE}. One of \code{"mda"} or
#'   \code{"impact_assessment"}. Default \code{"mda"}.
#' @param start_year Integer. First year of data, e.g. \code{2010}.
#' @param end_year Integer. Last year of data, e.g. \code{2020}.
#'   Must be >= \code{start_year}.
#' @param limit Integer. Maximum number of records to return per request.
#'   Useful for pagination. Default returns all available records.
#' @param offset Integer. Number of records to skip. Use with \code{limit}
#'   to page through large datasets.
#' @param attributes Character. Comma-separated list of column names to
#'   return, e.g. \code{"IU_ID,Endemicity,MDA,EffMDA"}. Default returns all
#'   columns.
#' @param df Logical. Return a data frame (\code{TRUE}, default) or an
#'   \code{ESPEN_api} object containing the raw JSON and response
#'   (\code{FALSE}).
#' @param verbose Logical. Print progress messages when downloading data for
#'   multiple countries. Default \code{FALSE}.
#'
#' @return A \code{data.frame} (when \code{df = TRUE}) or an object of class
#'   \code{ESPEN_api} (when \code{df = FALSE}).
#'   When multiple countries are requested, rows are combined with
#'   \code{rbind}.
#'
#' @export
#' @importFrom httr GET http_type http_error status_code
#' @importFrom jsonlite fromJSON
#'
#' @author Olatunji Johnson \email{olatunjijohnson21111@@gmail.com}
#'
#' @examples
#' \dontrun{
#' # Single country — STH data at site level
#' dat <- ESPEN_API_data(
#'   country    = "Nigeria",
#'   disease    = "sth",
#'   level      = "sitelevel",
#'   start_year = 2010,
#'   end_year   = 2015
#' )
#' head(dat)
#'
#' # Multiple countries in one call
#' dat_multi <- ESPEN_API_data(
#'   country    = c("Nigeria", "Ghana", "Kenya"),
#'   disease    = "lf",
#'   level      = "iu",
#'   start_year = 2015,
#'   end_year   = 2020,
#'   verbose    = TRUE
#' )
#' table(dat_multi$Country)
#'
#' # Using ISO2 codes
#' dat_iso <- ESPEN_API_data(
#'   iso2       = c("NG", "GH"),
#'   disease    = "sth",
#'   level      = "sitelevel",
#'   start_year = 2010,
#'   end_year   = 2010
#' )
#'
#' # Return raw JSON instead of a data frame
#' raw <- ESPEN_API_data(
#'   country = "Nigeria",
#'   disease = "sth",
#'   df      = FALSE
#' )
#' print(raw)
#'
#' # Browse available diseases and levels
#' espen_diseases()
#' espen_levels()
#' }
ESPEN_API_data <- function(api_key    = NULL,
                           country    = NULL,
                           iso2       = NULL,
                           disease    = "sth",
                           level      = "sitelevel",
                           type       = FALSE,
                           subtype    = "mda",
                           start_year = NULL,
                           end_year   = NULL,
                           limit      = NULL,
                           offset     = NULL,
                           attributes = NULL,
                           df         = TRUE,
                           verbose    = FALSE) {

  api_key <- resolve_api_key(api_key)

  if (is.null(country) && is.null(iso2))
    stop("Supply country name(s) (country = 'Nigeria') or ",
         "ISO2 code(s) (iso2 = 'NG').", call. = FALSE)

  validate_inputs(disease, level, subtype, start_year, end_year)

  # Support vectors of country names or ISO2 codes
  locations  <- if (!is.null(country)) country else iso2
  use_iso2   <- is.null(country)

  if (length(locations) > 1) {
    if (verbose)
      message("Downloading ", disease, " data for ", length(locations),
              " countries...")
    results <- lapply(locations, function(loc) {
      if (verbose) message("  Fetching: ", loc)
      args <- list(
        api_key = api_key, disease = disease, level = level,
        type = type, subtype = subtype,
        start_year = start_year, end_year = end_year,
        limit = limit, offset = offset, attributes = attributes,
        df = df, verbose = FALSE
      )
      args[[if (use_iso2) "iso2" else "country"]] <- loc
      do.call(ESPEN_API_data, args)
    })
    if (df) return(do.call(rbind, results))
    # For df = FALSE, return a list of ESPEN_api objects
    return(results)
  }

  # Single location
  url <- build_url(
    country    = if (!use_iso2) locations else NULL,
    iso2       = if (use_iso2)  locations else NULL,
    disease    = disease,
    level      = level,
    type       = type,
    subtype    = subtype,
    start_year = start_year,
    end_year   = end_year,
    limit      = limit,
    offset     = offset,
    attributes = attributes,
    api_key    = api_key
  )

  res <- httr::GET(url)
  parse_espen_response(res, url, df)
}
