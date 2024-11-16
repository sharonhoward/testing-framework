
# shared libraries, functions etc ####

source("./src/data/shared.R") 


source("./src/data/r_events_code.R")





bn_women_events_of_dates_types |>
  distinct(bn_id, personLabel, event_title, event_type, event_instance_date, event_instance_id, year, event_org, org_id) |>  
  add_count(bn_id, name="n_bn") |>
  filter(n_bn>=5) |>
  #select(bn_id, personLabel, event_type, n_bn, event_org) |>
  # make it json
  jsonlite::toJSON()

 
# zip(zipfile, files)

