
# shared libraries, functions etc ####

source("./src/data/shared.R") 

source("./src/data/r_dates_simple_all.R")

bn_simple_dates |>
   jsonlite::toJSON()
