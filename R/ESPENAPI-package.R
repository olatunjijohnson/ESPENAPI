#' ESPENAPI: Access NTD Data from the ESPEN Portal API
#'
#' Provides R access to the ESPEN (Expanded Special Project for Elimination
#' of Neglected Tropical Diseases) portal API. Users can download
#' programme-level and site-level NTD data for African countries directly
#' into R without visiting the ESPEN web portal.
#'
#' @section Main function:
#' \itemize{
#'   \item \code{\link{ESPEN_API_data}} — download NTD data for one or more
#'     countries
#' }
#'
#' @section Helper functions:
#' \itemize{
#'   \item \code{\link{espen_diseases}} — table of valid disease codes and names
#'   \item \code{\link{espen_levels}}   — table of valid spatial levels
#'   \item \code{\link{espen_key_setup}} — guide for setting up your API key
#' }
#'
#' @section API key:
#' An API key is required. Request one from \url{https://espen.afro.who.int}.
#' Store it in your \code{.Renviron} file as \code{ESPEN_API_KEY=your_key}
#' (run \code{usethis::edit_r_environ()} to open the file). All functions
#' read it automatically via \code{Sys.getenv("ESPEN_API_KEY")}.
#'
#' @keywords internal
"_PACKAGE"
