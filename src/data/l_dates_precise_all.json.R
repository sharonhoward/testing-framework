
# shared libraries, functions etc ####

source("./src/data/shared.R") 

source("./src/data/r_dates_precise_all.R")

bn_precise_dates |>
   jsonlite::toJSON()
   
   
   