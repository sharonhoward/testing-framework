
# shared libraries, functions etc ####

source("./src/data/shared.R") 


source("./src/data/events_code.R")



bn_women_events_of_dates_types |>
	select(event_instance_id, event_type) |>
   jsonlite::toJSON()
#  write_csv(stdout()) # work out how to do this at some point...


# bn_id, personLabel, ppa_type, ppa, event_title, event_type, year, event_instance_date, event_org, org_id, event_instance_id, event_org_id, dob, yob

 
# zip(zipfile, files)

