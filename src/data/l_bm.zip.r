# shared libraries, functions etc ####

source("./src/data/shared.R") 
source("./src/data/r_bm.R")
#source("./src/data/r_dates_education.R")


## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
#write_json(bn_women_educated_dates_wide, "educated.json")
#write_json(bn_women_educated_start_end_years, "start-end-pairs.json")
## will it work better with csv than json...
write_csv(bn_women_bm_educated_ages_long, "educated.csv")
write_csv(bn_women_bm_educated_start_end_years, "start-end-pairs.csv")
write_csv(bn_women_bm, "bm.csv")
system("zip - -r .")

