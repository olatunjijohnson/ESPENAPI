#' @title Request data from the ESPEN portal API
#' @description Downloads Neglected Tropical Disease (NTD) data from the ESPEN
#'   portal for one or more countries. Parameters follow the ESPEN API
#'   specification at \url{https://espenjapapi.afro.who.int/docs/api/data}.
#' @details An API key is required. Request one from the ESPEN portal at
#'   \url{https://espen.afro.who.int}. The recommended approach is to store it
#'   in your \code{.Renviron} file as \code{ESPEN_API_KEY=your_key} (run
#'   \code{usethis::edit_r_environ()} to open the file). The function will then
#'   pick it up automatically without you needing to pass it each time.
#'
#' @param api_key API key from the ESPEN portal. If \code{NULL} (default) the
#'   function reads the \code{ESPEN_API_KEY} environment variable.
#' @param country Country name, e.g. \code{"Nigeria"}. Either \code{country}
#'   or \code{iso2} must be supplied.
#' @param iso2 ISO2 country code, e.g. \code{"NG"}. Alternative to
#'   \code{country}; ignored if \code{country} is also supplied.
#' @param disease Disease of interest. One of \code{"lf"}, \code{"oncho"},
#'   \code{"loa"}, \code{"sch"}, \code{"sth"}, \code{"trachoma"},
#'   \code{"coendemicity"}. Default \code{"sth"}.
#' @param level Spatial level of the data. \code{"iu"} (implementation unit)
#'   or \code{"sitelevel"}. Default \code{"sitelevel"}.
#' @param type Logical. Set \code{TRUE} to request forecast data
#'   (MDA or impact assessment). Default \code{FALSE}.
#' @param subtype Used only when \code{type = TRUE}. One of \code{"mda"} or
#'   \code{"impact_assessment"}. Default \code{"mda"}.
#' @param start_year Starting year, e.g. \code{2010}.
#' @param end_year Ending year, e.g. \code{2020}.
#' @param limit Maximum number of records to return.
#' @param offset Number of records to skip (for pagination).
#' @param attributes Character string of attribute names to return, e.g.
#'   \code{"IU_ID,Endemicity,MDA,EffMDA"}.
#' @param df Logical. Return a data frame (\code{TRUE}, default) or a list
#'   containing the raw JSON string and response object (\code{FALSE}).
#'
#' @return A data frame or a named list of class \code{"ESPEN_api"}.
#' @export
#' @import httr jsonlite
#' @author Olatunji Johnson \email{olatunjijohnson21111@@gmail.com}
#' @examples
#' \dontrun{
#' # Store your key in .Renviron first:
#' #   usethis::edit_r_environ()
#' #   Add line: ESPEN_API_KEY=your_key_here
#'
#' # STH data for Nigeria at site level, 2010-2015
#' data <- ESPEN_API_data(
#'   country    = "Nigeria",
#'   disease    = "sth",
#'   level      = "sitelevel",
#'   start_year = 2010,
#'   end_year   = 2015
#' )
#' head(data)
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
                           df         = TRUE) {

  # ---- API key ----------------------------------------------------------
  if (is.null(api_key)) {
    api_key <- Sys.getenv("ESPEN_API_KEY")
    if (nchar(trimws(api_key)) == 0)
      stop(
        "No API key found. Set ESPEN_API_KEY in your .Renviron ",
        "(run usethis::edit_r_environ()) or pass api_key directly.",
        call. = FALSE
      )
  }

  # ---- Input validation -------------------------------------------------
  if (is.null(country) && is.null(iso2))
    stop("Supply a country name (country='Nigeria') or ISO2 code (iso2='NG').",
         call. = FALSE)

  valid_diseases <- c("lf", "oncho", "loa", "sch", "sth", "trachoma",
                      "coendemicity")
  if (!disease %in% valid_diseases)
    stop("disease must be one of: ", paste(valid_diseases, collapse = ", "),
         call. = FALSE)

  if (!level %in% c("iu", "sitelevel"))
    stop("level must be 'iu' or 'sitelevel'", call. = FALSE)

  if (!subtype %in% c("mda", "impact_assessment"))
    stop("subtype must be 'mda' or 'impact_assessment'", call. = FALSE)

  # ---- Build query string -----------------------------------------------
  if (!is.null(country)) {
    country <- paste0(
      toupper(substr(country, 1, 1)),
      tolower(substr(country, 2, nchar(country)))
    )
    location <- paste0("country=", country, "&")
  } else {
    location <- paste0("iso2=", toupper(iso2), "&")
  }

  disease_q <- paste0("disease=", disease, "&")
  level_q   <- paste0("level=",   level,   "&")

  if (type) {
    type_q    <- "type=forecast&"
    subtype_q <- paste0("subtype=", subtype, "&")
  } else {
    type_q    <- NULL
    subtype_q <- NULL
  }

  if (!is.null(start_year)) start_year <- paste0("start_year=", start_year, "&")
  if (!is.null(end_year))   end_year   <- paste0("end_year=",   end_year,   "&")
  if (!is.null(limit))      limit      <- paste0("limit=",      limit,      "&")
  if (!is.null(offset))     offset     <- paste0("offset=",     offset,     "&")
  if (!is.null(attributes)) attributes <- paste0("attributes=", attributes, "&")

  api_url <- paste0(
    "https://espenjapapi.afro.who.int/api/data?",
    location, disease_q, level_q, type_q, subtype_q,
    start_year, end_year, limit, offset, attributes,
    "api_key=", api_key
  )

  # ---- HTTP request -----------------------------------------------------
  res <- httr::GET(api_url)

  if (httr::http_type(res) != "application/json")
    stop("API did not return JSON — the endpoint may have changed.",
         call. = FALSE)

  if (httr::http_error(res)) {
    body <- rawToChar(res$content)
    msg  <- if (nchar(trimws(body)) > 0) {
      tryCatch(
        jsonlite::fromJSON(body, simplifyVector = FALSE)$message %||%
          "No message in response.",
        error = function(e) body
      )
    } else {
      "No error detail returned by the API."
    }
    stop(sprintf("ESPEN API request failed [%s]: %s",
                 httr::status_code(res), msg),
         call. = FALSE)
  }

  # ---- Parse and return -------------------------------------------------
  if (df) {
    jsonlite::fromJSON(rawToChar(res$content))
  } else {
    structure(
      list(content = rawToChar(res$content), url = api_url, response = res),
      class = "ESPEN_api"
    )
  }
}

# null-coalescing helper (avoids a purrr dependency)
`%||%` <- function(x, y) if (!is.null(x)) x else y
