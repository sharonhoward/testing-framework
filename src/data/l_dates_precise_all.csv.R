
# shared libraries, functions etc ####

source("./src/data/shared.R") 

source("./src/data/r_dates_precise_all.R")

   
# Convert data frame to delimited string, then write to standard output
cat(format_csv(bn_precise_dates))