# frequently used libraries ####

#library(knitr)
#library(kableExtra)

#library(readxl) 
#library(writexl)

library(jsonlite)
library(janitor)
#library(scales)
library(glue)

library(tidytext)

#library(tidyverse)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(purrr)

library(lubridate)
library(httr)
library(curl)

# viz/ggplot extras

#library(patchwork)

#library(ggthemes)
#library(ggalt)


# wikidata/sparql etc
#library(SPARQLchunks) # can't get chunks working! but it's fine for inline queries.


#' Fetch data from a SPARQL endpoint and store the output in a dataframe
#' @param endpoint The SPARQL endpoint (a URL)
#' @param query The SPARQL query (character)
#' @param autoproxy Try to detect a proxy automatically (boolean). Useful on Windows machines behind corporate firewalls
#' @param auth Authentication Information (httr-authenticate-object)
#' @examples library(SPARQLchunks)
#' endpoint <- "https://lindas.admin.ch/query"
#' query <- "PREFIX schema: <http://schema.org/>
#'   SELECT * WHERE {
#'   ?sub a schema:DataCatalog .
#'   ?subtype a schema:DataType .
#' }"
#' result_df <- sparql2df(endpoint, query)
#' @export
sparql2df <- function(endpoint, query, autoproxy = FALSE, auth = NULL) {
  if (autoproxy) {
    proxy_config <- autoproxyconfig(endpoint)
  } else {
    proxy_config <- httr::use_proxy(url = NULL)
  }
  acceptype <- "text/csv"
  outcontent <- get_outcontent(endpoint, query, acceptype, proxy_config, auth)
  out <- textConnection(outcontent)
  df <- utils::read.csv(out)
  return(df)
}



#' Try to determine the proxy settings automatically
#' @param endpoint The SPARQL endpoint (URL)
autoproxyconfig <- function(endpoint) {
  message("Trying to determine proxy parameters")
  proxy_url <- tryCatch(
    {
      curl::ie_get_proxy_for_url(endpoint)
    },
    error = function(e) {
      message("Automatic proxy detection with curl::curl::ie_get_proxy_for_url() failed.")
      return(NULL)
    }
  )
  if (!is.null(proxy_url)) {
    message(paste("Using proxy:", proxy_url))
  } else {
    message(paste("No proxy found or needed to access the endpoint", endpoint))
  }
  return(httr::use_proxy(url = proxy_url))
}

#' Get the content from the endpoint
#' @param endpoint The SPARQL endpoint (URL)
#' @param query The SPARQL query (character)
#' @param acceptype 'text/csv' or 'text/xml' (character)
#' @param proxy_config Detected proxy configuration (list)
#' @param auth Authentication Information (httr-authenticate-object)
get_outcontent <- function(endpoint, query, acceptype, proxy_config, auth = NULL) {
  qm <- paste(endpoint, "?", "query", "=",
    gsub("\\+", "%2B", utils::URLencode(query, reserved = TRUE)), "",
    sep = ""
  )

  outcontent <- tryCatch(
    {
      out <- httr::GET(
        qm,
        proxy_config, auth,
        httr::timeout(60),
        httr::add_headers(c(Accept = acceptype))
      )
      httr::content(out, "text", encoding = "UTF-8")
    },
    error = function(e) {
      # @see https://github.com/r-lib/httr/issues/417 The download.file function in base R uses IE settings, including proxy password, when you use download
      # method wininet which is now the default on windows.
      if (.Platform$OS.type == "windows") {
        tempfile <- file.path(tempdir(), "temp.txt")
        utils::download.file(qm,
          method = "wininet",
          headers = c(Accept = acceptype),
          tempfile
        )
        temp <- paste(readLines(tempfile), collapse = "\n")
        unlink(tempfile)
        return(temp)
      }
    }
  )
  if (nchar(outcontent) < 1) {
    warning(paste0(
      "First query attempt result is empty. Trying without '",
      acceptype,
      "' header. The result is not guaranteed to be a list."
    ))
    outcontent <- tryCatch(
      {
        out <- httr::GET(
          qm,
          proxy_config, auth,
          httr::timeout(60)
        )
        if (out$status == 401) {
          warning("Authentication required. Provide valid authentication with the auth parameter")
        } else {
          httr::warn_for_status(out)
        }
        httr::content(out, "text", encoding = "UTF-8")
      },
      error = function(e) {
        if (.Platform$OS.type == "windows") {
          tempfile <- file.path(tempdir(), "temp.txt")
          utils::download.file(qm, method = "wininet", tempfile)
          temp <- paste(readLines(tempfile), collapse = "\n")
          unlink(tempfile)
          return(temp)
        }
      }
    )
    if (nchar(outcontent) < 1) {
      warning("The query result is still empty")
    }
  }
  return(outcontent)
}




# standard query using bn_prefixes and bn_endpoint. sparql= 'query string (excluding prefixes)'
bn_std_query <- function(sparql){
  c(paste(
    bn_prefixes,
    sparql
  )) |>
    sparql2df(endpoint=bn_endpoint) 
}


## endpoint ####

bn_endpoint <- "https://beyond-notability.wikibase.cloud/query/sparql"

## prefixes 

bn_prefixes <- 
"PREFIX bnwd: <https://beyond-notability.wikibase.cloud/entity/>
PREFIX bnwds: <https://beyond-notability.wikibase.cloud/entity/statement/>
PREFIX bnwdv: <https://beyond-notability.wikibase.cloud/value/>
PREFIX bnwdt: <https://beyond-notability.wikibase.cloud/prop/direct/>
PREFIX bnp: <https://beyond-notability.wikibase.cloud/prop/>
PREFIX bnps: <https://beyond-notability.wikibase.cloud/prop/statement/>
PREFIX bnpq: <https://beyond-notability.wikibase.cloud/prop/qualifier/> 
PREFIX bnpsv: <https://beyond-notability.wikibase.cloud/prop/statement/value/>
PREFIX bnpqv: <https://beyond-notability.wikibase.cloud/prop/qualifier/value/>
  PREFIX bnwdref: <https://beyond-notability.wikibase.cloud/reference/>
  PREFIX bnpr: <https://beyond-notability.wikibase.cloud/prop/reference/>
  PREFIX bnprv: <https://beyond-notability.wikibase.cloud/prop/reference/value/>
"


## dates of birth/death. - using this a lot now and it's not a heavy query, so it seems worth adding to the shared file.

bn_women_list_sparql <-
  'SELECT distinct ?person ?personLabel ?statements ?dob ?dod
WHERE {
   ?person bnwdt:P3 bnwd:Q3 ;
         wikibase:statements ?statements .
   FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .}

      optional { ?person bnwdt:P15 ?dod .   }
      optional { ?person bnwdt:P26 ?dob .   }

    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}'

# minimal processing to use as is or for dob/dod
women <-
  bn_std_query(bn_women_list_sparql) 


# Convert data frame to delimited string, then write to standard output
cat(format_csv(women))