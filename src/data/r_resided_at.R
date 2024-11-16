
#this needs to go before dates_resided_** but be careful not to do it twice...
#forgot that won't work from rstudio
#source("./src/data/r_dates_all_simplified.R")

##########


bn_dates_main_sparql <-
  'SELECT distinct ?person  ?date ?date_prop 
  WHERE {
   ?person bnwdt:P3 bnwd:Q3 . #women
   FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . } # not project team
   ?person ?p ?s .   
      ?date_prop wikibase:claim ?p . 
      ?date_prop wikibase:statementProperty ?ps.
      ?date_prop wikibase:propertyType wikibase:Time . # PIT only.  
      ?s ?ps ?date .
  
} # /where
ORDER BY ?person ?date'


bn_dates_main_query <-
  bn_std_query(bn_dates_main_sparql) |>
  make_bn_item_id(person)  |>
  make_bn_ids(date_prop) |>
  inner_join(bn_properties |> select(bn_prop_id, propertyLabel), by=c("date_prop"="bn_prop_id")) |>
  make_date_year() |> 
  select(-person) 


bn_dates_edtf_sparql <-
  'SELECT distinct ?person ?date ?date_prop
   WHERE {
    ?person bnwdt:P3 bnwd:Q3 . 
    FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . } 
    ?person ( bnp:P131 | bnp:P132 | bnp:P133  ) ?s .
         ?s ( bnps:P131 | bnps:P132 | bnps:P133 ) ?date .
         ?s ?date_prop ?date .   
     # avoid dups though it doesnt really matter here; use dateTime version
      FILTER ( datatype(?date) = xsd:dateTime  ) .
} # /where
ORDER BY ?person ?date'

bn_dates_edtf_query <-
  bn_std_query(bn_dates_edtf_sparql) |>
  make_bn_item_id(person)  |>
  make_bn_ids(date_prop)  |>
  inner_join(bn_properties |> select(bn_prop_id, propertyLabel), by=c("date_prop"="bn_prop_id")) |>
  make_date_year() |> 
  select(-person) 



bn_dates_qual_sparql <-
  'SELECT distinct ?person  ?date  ?date_prop
WHERE {
    ?person bnwdt:P3 bnwd:Q3 .
    FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . } 
    ?person ?date_prop ?s .   
        ?s ?pq ?date .   
          ?qual_date_prop wikibase:qualifier ?pq .
          ?qual_date_prop wikibase:propertyType wikibase:Time.  
} # /where
ORDER BY ?person'

# adding date_prop makes quite a big difference to this one...
bn_dates_qual_query <-
  bn_std_query(bn_dates_qual_sparql) |>
  make_bn_item_id(person)  |>
  make_bn_ids(date_prop)  |>
  inner_join(bn_properties |> select(bn_prop_id, propertyLabel), by=c("date_prop"="bn_prop_id")) |>
  make_date_year() |> 
  select(-person) 

bn_dates_all <-
  bind_rows(
    bn_dates_main_query,
    bn_dates_edtf_query,
    bn_dates_qual_query
  )

# without properties
bn_dates_all_distinct <-
  bn_dates_all |>
  distinct(bn_id, date, year)



bn_dates_ages <-
  bn_dates_all |> 
  filter(year<2020) |>
  inner_join(bn_women_list_deduped |> select(bn_id, bn_dob_yr), by="bn_id") |>
  mutate(age = year-bn_dob_yr) |>
  arrange(bn_id, age) 



bn_dates_ages_distinct <-
  bn_dates_ages |>
  distinct(bn_id, date, year, bn_dob_yr, age)

##############


bn_women_birth <-
  bn_women_dob_dod |>
  filter(!is.na(bn_dob)) |>
  select(bn_id, personLabel, bn_dob_yr)



resided_sparql <-
'SELECT distinct ?person ?personLabel ?residedLabel 
?address_text ?address_itemLabel ?geo ?date ?date_prop ?sourcingLabel ?note
 ?s ?resided ?address_item


WHERE {
  ?person bnwdt:P3 bnwd:Q3 .
   FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .} 
  
  # P29 resided at
  ?person bnp:P29 ?s .
    ?s bnps:P29 ?resided . 
  
  #  ?s ?pq ?qual .
  #  ?qual_prop wikibase:qualifier ?pq .
  
   optional { ?s bnpq:P31 ?address_text . }
   optional { ?s bnpq:P100 ?address_item . }
   optional { ?s bnpq:P153 ?geo . }
  
   optional { 
     ?s ( bnpq:P1 | bnpq:P27 | bnpq:P28 | bnpq:P51 | bnpq:P53 ) ?date .
     ?s ?date_prop ?date .
     }
  
  optional {?s bnpq:P55 ?sourcing .}
  
  optional {?s bnpq:P47 ?note .}
  
  SERVICE wikibase:label {
      bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb".
    }
}'

resided_query <-
  bn_std_query(resided_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(resided, address_item, date_prop, s)) |>
  mutate(across(c(address_text, address_item, address_itemLabel, geo, date, date_prop, sourcingLabel, note), ~na_if(., ""))) |>
  make_date_year() |>
  mutate(date_prop_label = date_property_labels(date_prop)) |>
  filter(year < 2022 | is.na(year)) |>
  relocate(s, person, .after = last_col())

# don't worry about having death...
# but hang on a minute, you can't drop NAs yet if you're going to use this for young/old
resided_birth_age <-
resided_query |>
  #filter(!is.na(date)) |>
  inner_join(bn_women_birth |> select(bn_id, bn_dob_yr), by="bn_id") |>
  # there will be NAs here now
  mutate(age = year-bn_dob_yr) |>
  select(bn_id, personLabel, year, date_prop_label, age, yob=bn_dob_yr, s) 

resided_dated <-
	resided_query |>
	filter(!is.na(year))
	
resided <-
	resided_query |>
	mutate(date_prop_label = if_else(is.na(date_prop_label), "undated", date_prop_label)) |>
	select(bn_id, personLabel, residedLabel, date, year, date_prop_label)



#################


# set age thresholds
young_age <- 30
old_age <- 60


## naming: _exclusion = preparing for exclude; _exclude for actually doing it

# initially exclude any with any NA dates and anyone born before 1831 and after 1910
resided_exclusion <-
resided_birth_age |>
  anti_join(
    resided_birth_age |>
      filter(is.na(year)) |>
      distinct(bn_id), by="bn_id") |>
  filter(between(yob, 1831, 1910))

# make wide start-end pairs
resided_exclusion_start_end_wide <-
resided_exclusion |>
  filter(date_prop_label %in% c("start time", "end time")) |>
  distinct(bn_id, date_prop_label, age, s) |>
  pivot_wider(names_from = date_prop_label, values_from = age ) |>
  clean_names("snake") |>
  arrange(bn_id, start_time, end_time)


# for anti joins/filters (by bn_id)
# don't actually need final distinct(bn_id) if doing anti join. so if you want info for anything...

# old: anyone with a latest date, whatever their age at the time
resided_exclude_old_latest <-
resided_exclusion |>
  filter(date_prop_label %in% c("latest date") & age>old_age) |>
  distinct(bn_id)

# old: anyone with an end time that has no start time, whatever their age at the time
resided_exclude_old_end_no_start <-
resided_exclusion_start_end_wide |>
  filter(is.na(start_time)) |>
  distinct(bn_id)

# young: anyone with any earliest date, whatever their age at the time
resided_exclude_young_earliest <-
resided_exclusion |>
  filter(date_prop_label == "earliest date" & age<young_age) |>
  distinct(bn_id)

# young: anyone with any start time that has no end time, whatever the age at the time
resided_exclude_young_start_no_end <-
resided_exclusion_start_end_wide |>
  filter(is.na(end_time)) |>
  distinct(bn_id)


# young: any date that's > young_age
resided_exclude_young_age <-
  resided_exclusion |>
  filter(age>young_age) |>
  distinct(bn_id)

# old: any date that's < old_age
resided_exclude_old_age <-
resided_exclusion |>
  filter(age<old_age) |>
  distinct(bn_id)


## put it all together

resided_late <-
resided_exclusion |>
  anti_join(resided_exclude_old_age, by="bn_id") |>
  anti_join(resided_exclude_old_end_no_start, by="bn_id") |>
  anti_join(resided_exclude_old_latest, by="bn_id")  |>
  left_join(bn_women_list_deduped |> select(bn_id, statements), by="bn_id") 


resided_early <-
resided_exclusion |>
  anti_join(resided_exclude_young_age, by="bn_id") |>
  anti_join(resided_exclude_young_earliest, by="bn_id") |>
  anti_join(resided_exclude_young_start_no_end, by="bn_id")  |>
  left_join(bn_women_list_deduped |> select(bn_id, statements), by="bn_id") 


resided_other <-
resided_birth_age  |>
  left_join(bn_women_list_deduped |> select(bn_id, statements), by="bn_id")  |>
  anti_join(resided_late, by="bn_id") |>
  anti_join(resided_early, by="bn_id")
  


# if you're doing these in beeswarms i don't think you want the ages_distinct dfs
dates_resided_late <-
bn_dates_ages |>
#bn_dates_ages_distinct |>
  # only dates for women who are in resided_late
  semi_join(resided_late, by="bn_id") |>
  # which of those years have p.i.t. residence data. [shoudl be all pit.]
  left_join(
    resided_late |>
     # semi_join(resided_age_multi_pit_only, by="bn_id") |>
      distinct(bn_id, age) |>
      mutate(residence="resided at"), by=c("bn_id", "age")
  ) |>
  mutate(residence = if_else(!is.na(residence), residence, "other")) 

dates_resided_early <-
#bn_dates_ages_distinct |>
bn_dates_ages |>
  # only dates for women who are in resided_early
  semi_join(resided_early, by="bn_id") |>
  # which of those years have p.i.t. residence data. 
  left_join(
    resided_early |>
      distinct(bn_id, age) |>
      mutate(residence="resided at"), by=c("bn_id", "age")
  ) |>
  mutate(residence = if_else(!is.na(residence), residence, "other")) 
  
  
  
  
dates_resided_other <-
bn_dates_ages |>
  # only dates for women who are in resided_late
  semi_join(resided_other, by="bn_id") |>
  # which of those years have p.i.t. residence data. they're all pit so only need to join isn't needed.
  left_join(
    resided_other |>
     # semi_join(resided_age_multi_pit_only, by="bn_id") |>
      distinct(bn_id, age) |>
      mutate(residence="resided at"), by=c("bn_id", "age")
  ) |>
  mutate(residence = if_else(!is.na(residence), residence, "other")) 


dates_resided_early_late <-
bind_rows(
  dates_resided_early |> mutate(group="early"),
  dates_resided_late |> mutate(group="late") 
) 