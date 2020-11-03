# ESPEN_API_data.R
#
#' @title A function to request data from the ESPEN portal using API
#' @description Allows users to request data for countries through the ESPEN API.  Users provide parameters as specified in <\url{https://admin.espen.afro.who.int/docs/api/data}> or as described below and the function returns a JSON string or data frame.
#' @details See <\url{https://espen.afro.who.int/tools-resources/download-data}>  for more details on the data available.
#' @param api_key the API key from ESPEN. You can request the key from ESPEN portal. To use the default API key, ignore the argument or set api_key = NULL.
#' @param country the name of the country. E.g `Ghana`
#' @param iso2 optional: country ISO2 code, e.g. `GH`. you can either specify a country name or the ISO2 code
#' @param disease specify the disease of interest, options are lf , oncho , loa , sch , sth , trachoma , coendemicity
#' @param level specify which the level of the data, options are `iu` and  `sitelevel`. iu means implemantation unit.
#' @param type logical: should you want a forcast of MDA or impact assessment. default is FALSE.
#' @param subtype only use when type =TRUE, options are mda and impact_assessment.
#' @param start_year specify the starting year of the data, e.g start_year = 2010
#' @param end_year specify the starting year of the data, e.g end_year = 2020
#' @param limit to specify how many records to return
#' @param offset to specify how many records to skip
#' @param attributes options are IU_ID, Endemicity, MDA, EffMDA. This is basically used to reduce the data.
#' @param df logical: should the function return a dataframe (default) or JSON.
#' @export
#' @import httr jsonlite
#' @return A dataframe or JSON file of the data
#' @examples
#' library(ESPENAPI)
#' # extract the STH data from Nigeria at site level from year 2010 to 2020.
#' data  <- ESPEN_API_data(country="Nigeria", disease="sth",
#' level="sitelevel", start_year=2010, end_year=2010)
#' head(data)



ESPEN_API_data <- function(api_key=NULL, country= NULL, iso2=NULL, disease="sth", level="sitelevel", type= FALSE,
                           subtype= "mda", start_year= NULL, end_year=NULL, limit=NULL, offset=NULL, attributes=NULL,   df=TRUE){


  if(is.null(api_key)){
    api_key = paste0("api_key=3268f2ddeeba435a9a1b090e81330ca0")
  } else{
    api_key = paste0("api_key=", api_key)
  }


  if(is.null(country) & is.null(iso2)) stop(paste0("Please specify the country you are requesting the data.
                                            You are either supply the name of the country or ISO2 code for the country.
                                                   E.g country=`Ghana', or iso2=`GH'"))



  if(!is.null(country)) {
    country <- tolower(country)
    country <- paste0(toupper(substr(country, 1, 1)), substr(country, 2, nchar(country)))  # capitalise the first letter
    country <-  paste0("country=", country, "&")
  }


  if(!is.null(iso2)){
    iso2 <- toupper(iso2)
    iso2 = paste0("iso2=", iso2, "&")
  }

  if(any(disease==c("lf" , "oncho" , "loa" , "sch" , "sth" , "trachoma" , "coendemicity"))==FALSE) stop("disease should be of the following: lf , oncho , loa , sch , sth , trachoma , coendemicity")

  disease = paste0("disease=", disease, "&")

  if(any(level==c("iu" , "sitelevel"))==FALSE) stop("level should be iu or  sitelevel")

  level = paste0("level=", level, "&")

  if(any(subtype==c("mda" , "impact_assessment"))==FALSE) stop("subtype should be mda or impact_assessment")

  if(type){
    type = paste0("type= forecast", "&")
    subtype = paste0("subtype=", subtype, "&")
  } else{
    type <- NULL
    subtype <- NULL
  }

  switch(which(c(!is.null(country), !is.null(iso2)))[1], country, iso2)


  if(!is.null(start_year)) start_year = paste0("start_year=", start_year, "&")

  if(!is.null(end_year)) end_year = paste0("end_year=", end_year, "&")

  if(any(c(is.null(country), is.null(iso2)))==TRUE)





    param <- paste0(switch(which(c(!is.null(country), !is.null(iso2)))[1], country, iso2), disease, level, type, subtype, start_year,
                    end_year, limit, offset, attributes, api_key)
  param
  api_url <- paste0("https://admin.espen.afro.who.int/api/data?", param)
  api_url

  res <- httr::GET(api_url)

  if(df){
    result = jsonlite::fromJSON(rawToChar(res$content))
  }else{
    ### return JSON result
    result = rawToChar(res$content)
  }
  return(result)
}

