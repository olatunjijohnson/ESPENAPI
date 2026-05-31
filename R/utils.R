#' Valid disease codes and their full names
#'
#' Returns a reference table of all disease codes accepted by the ESPEN API,
#' together with their full names and a brief description.
#'
#' @return A data frame with columns \code{code}, \code{name}, and
#'   \code{description}.
#' @export
#' @examples
#' espen_diseases()
espen_diseases <- function() {
  data.frame(
    code = c("lf", "oncho", "loa", "sch", "sth", "trachoma", "coendemicity"),
    name = c(
      "Lymphatic filariasis",
      "Onchocerciasis",
      "Loiasis",
      "Schistosomiasis",
      "Soil-transmitted helminths",
      "Trachoma",
      "Co-endemicity"
    ),
    description = c(
      "Caused by filarial worms transmitted by mosquitoes; leads to lymphoedema",
      "River blindness caused by Onchocerca volvulus; transmitted by blackflies",
      "Eye worm disease caused by Loa loa; endemic in Central and West Africa",
      "Bilharzia caused by Schistosoma flatworms; linked to freshwater exposure",
      "Roundworm, hookworm and whipworm infections from contaminated soil",
      "Bacterial eye infection (Chlamydia trachomatis) leading to blindness",
      "Reporting for areas co-endemic for multiple NTDs"
    ),
    stringsAsFactors = FALSE
  )
}

#' Valid spatial level codes
#'
#' Returns a reference table of the two spatial levels accepted by the ESPEN
#' API.
#'
#' @return A data frame with columns \code{code}, \code{name}, and
#'   \code{description}.
#' @export
#' @examples
#' espen_levels()
espen_levels <- function() {
  data.frame(
    code = c("iu", "sitelevel"),
    name = c("Implementation unit", "Site level"),
    description = c(
      paste0("Administrative unit used for MDA programme planning. Typically ",
             "a district or sub-district. Aggregated prevalence and MDA coverage."),
      paste0("Individual survey site or sentinel site. Contains site-specific ",
             "survey results including sample sizes and prevalence estimates.")
    ),
    stringsAsFactors = FALSE
  )
}

#' Guide for setting up your ESPEN API key
#'
#' Prints step-by-step instructions for obtaining and storing an ESPEN API
#' key so that it is available to all ESPENAPI functions automatically.
#'
#' @return \code{NULL} invisibly.
#' @export
#' @examples
#' espen_key_setup()
espen_key_setup <- function() {
  message(
    "ESPEN API key setup\n",
    "-------------------\n",
    "Step 1: Request a free key from https://espen.afro.who.int\n\n",
    "Step 2: Open your .Renviron file:\n",
    "        usethis::edit_r_environ()\n\n",
    "Step 3: Add this line (replacing the placeholder):\n",
    "        ESPEN_API_KEY=your_key_here\n\n",
    "Step 4: Save the file and restart R.\n\n",
    "Once set, all ESPENAPI functions will use it automatically via\n",
    "Sys.getenv('ESPEN_API_KEY') — you never need to pass it as an argument."
  )
  invisible(NULL)
}

#' Print an ESPEN API response object
#'
#' @param x An object of class \code{ESPEN_api}.
#' @param ... Ignored.
#' @export
print.ESPEN_api <- function(x, ...) {
  cat("<ESPEN API response>\n")
  cat("  URL     : ", x$url, "\n", sep = "")
  cat("  Status  : ", x$response$status_code, "\n", sep = "")
  cat("  Size    : ", format(nchar(x$content), big.mark = ","),
      " characters\n", sep = "")
  invisible(x)
}
