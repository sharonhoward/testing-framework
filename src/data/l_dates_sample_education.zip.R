
# shared libraries, functions etc ####


source("./src/data/shared.R") 

source("./src/data/r_dates_education.R")
  
bn_women_education_degrees <-
	head(bn_women_education_degrees)
	
# 10 women only
bn_women_education_degrees2 <-
bn_women_education_degrees2 |>
	distinct(bn_id) |>
	head(10) |>
	left_join(bn_women_education_degrees2, by="bn_id")

## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
jsonlite::write_json(bn_women_education_degrees, "educated_degrees.json")
jsonlite::write_json(bn_women_education_degrees2, "educated_degrees2.json")
jsonlite::write_json(bn_women_educated_start_end_years, "start_end_pairs.json")

system("zip - -r .")
  