# Internal helpers — not exported

# Resolve the API key from argument or environment variable
resolve_api_key <- function(api_key) {
  if (!is.null(api_key)) return(api_key)
  key <- Sys.getenv("ESPEN_API_KEY")
  if (nchar(trimws(key)) == 0)
    stop(
      "No API key found.\n",
      "  1. Request a key from: https://espen.afro.who.int\n",
      "  2. Run: usethis::edit_r_environ()\n",
      "  3. Add:  ESPEN_API_KEY=your_key_here\n",
      "  4. Save and restart R\n\n",
      "  Or call espen_key_setup() for guided instructions.",
      call. = FALSE
    )
  key
}

# Validate all user-supplied parameters before any network call
validate_inputs <- function(disease, level, subtype, start_year, end_year) {
  valid_diseases <- c("lf", "oncho", "loa", "sch", "sth",
                      "trachoma", "coendemicity")
  if (!disease %in% valid_diseases)
    stop("disease must be one of: ", paste(valid_diseases, collapse = ", "),
         call. = FALSE)

  if (!level %in% c("iu", "sitelevel"))
    stop("level must be 'iu' (implementation unit) or 'sitelevel'",
         call. = FALSE)

  if (!subtype %in% c("mda", "impact_assessment"))
    stop("subtype must be 'mda' or 'impact_assessment'", call. = FALSE)

  if (!is.null(start_year) && !is.null(end_year)) {
    if (!is.numeric(start_year) || !is.numeric(end_year))
      stop("start_year and end_year must be numeric", call. = FALSE)
    if (start_year > end_year)
      stop("start_year (", start_year, ") must be <= end_year (", end_year, ")",
           call. = FALSE)
  }
}

# Build the full API URL from validated parameters
build_url <- function(country, iso2, disease, level, type, subtype,
                      start_year, end_year, limit, offset, attributes,
                      api_key) {
  if (!is.null(country)) {
    location <- paste0(
      "country=",
      paste0(toupper(substr(country, 1, 1)), tolower(substr(country, 2, nchar(country)))),
      "&"
    )
  } else {
    location <- paste0("iso2=", toupper(iso2), "&")
  }

  paste0(
    "https://espenjapapi.afro.who.int/api/data?",
    location,
    "disease=", disease, "&",
    "level=",   level,   "&",
    if (type) paste0("type=forecast&subtype=", subtype, "&"),
    if (!is.null(start_year)) paste0("start_year=", as.integer(start_year), "&"),
    if (!is.null(end_year))   paste0("end_year=",   as.integer(end_year),   "&"),
    if (!is.null(limit))      paste0("limit=",      as.integer(limit),      "&"),
    if (!is.null(offset))     paste0("offset=",     as.integer(offset),     "&"),
    if (!is.null(attributes)) paste0("attributes=", attributes,              "&"),
    "api_key=", api_key
  )
}

# Parse the httr response — handles errors and content type checks
parse_espen_response <- function(res, url, df) {
  if (httr::http_type(res) != "application/json")
    stop("API did not return JSON. The endpoint may have changed.",
         call. = FALSE)

  if (httr::http_error(res)) {
    body <- rawToChar(res$content)
    msg  <- if (nchar(trimws(body)) > 0) {
      tryCatch(
        jsonlite::fromJSON(body, simplifyVector = FALSE)[["message"]] %||%
          "No message in response.",
        error = function(e) body
      )
    } else {
      "No error detail returned — check your API key is valid."
    }
    stop(sprintf("ESPEN API request failed [%s]: %s",
                 httr::status_code(res), msg),
         call. = FALSE)
  }

  if (df) {
    result <- jsonlite::fromJSON(rawToChar(res$content))
    # Ensure we always return a data frame, never a list
    if (!is.data.frame(result)) result <- as.data.frame(result)
    result
  } else {
    structure(
      list(
        content  = rawToChar(res$content),
        url      = url,
        response = res
      ),
      class = "ESPEN_api"
    )
  }
}

# Null-coalescing: x %||% y returns x if non-null, else y
`%||%` <- function(x, y) if (!is.null(x)) x else y
