## children data

# union a) unnamed kids in had child in; b) named child
# a handful of named children don't have dob though probably have dob in wikidata 

bn_had_children_sparql <-
'SELECT distinct ?person ?personLabel ?childLabel ?date_value ?date_prec ?had_child_edtf ?note  ?child ?s

where {

  ?person bnwdt:P3 bnwd:Q3 . # select women
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .} #filter out project team
   
{   
  # had child (unnamed)
  ?person bnp:P131 ?s .
      ?s bnps:P131 ?had_child_edtf . # keep the edtf date for reference, though i think you can just use time value/prec with these.

  # get dates detail 
      ?s ?psv ?wdv .
        ?wdv wikibase:timeValue ?date_value .
        ?wdv wikibase:timePrecision ?date_prec .
  
  # filter edtf date.
  FILTER ( datatype(?had_child_edtf) = xsd:edtf ) . #shows only the raw EDTF string from the query results
    
   # not much added in quals for had child. only maybe note P47. some have sourcing circumstances.
   optional { ?s bnpq:P47 ?note .} 
   
  } 
  union 
  {
  # named children (are any in both sections??? from dates looks possible a couple might be [wherry / hodgson])
   ?person bnp:P45 ?s.
        ?s bnps:P45 ?child .
        optional { ?child bnp:P26 ?ss .
                    ?ss bnps:P26 ?dob . 
                     ?ss ?psv ?wdv .
                        ?wdv wikibase:timeValue ?date_value .
                        ?wdv wikibase:timePrecision ?date_prec .
               }
  }
  
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}
order by ?person ?date_value
'

bn_had_children_query <-
  bn_std_query(bn_had_children_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(child, s)) |>
  mutate(across(c(note, had_child_edtf, childLabel, child), ~na_if(., ""))) |>
  relocate(person, .after = last_col())



# need dob for mothers if i'm going to put kids on life timelines... now in std queries


## may be some dup kids... could be a little bit tricky if you really wanted to separate out every child? but just doing per year should be fine. 



bn_had_children_ages <-
bn_had_children_query |>
    mutate(date_value = if_else(str_detect(date_value, "^_:t"), NA, date_value))  |>
    mutate(date_value = parse_date_time(date_value, "ymdHMS"))  |>
    mutate(year = year(date_value)) |>
  relocate(year, .after = date_value) |>
  filter(!is.na(date_value)) |>
  filter(year>1810) |>
  # this will sort named children above had_child rows. then top_n
  arrange(bn_id, year, child) |>
  group_by(bn_id, year) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  #add_count(bn_id, date_value) |> filter(n>1)
  left_join(bn_women_dob_dod |> select(bn_id, bn_dob_yr, bn_dod_yr, bn_dob, bn_dod), by="bn_id") |>
  mutate(age = year-bn_dob_yr) |>
  filter(!is.na(age)) |>
  # first and last dates overall, for limits if doing by date. not currently in use.
  mutate(all_start_date = min(date_value)- years(1), all_end_date = max(date_value) + years(1))  |>
  # don't need group_id/lower/upper for this version, only earliest and latest.
  group_by(bn_id) |> 
  mutate(earliest = min(date_value), latest=max(date_value)) |>
  # why was start age min(age)-1 ? (ditto start date?)
  mutate(start_age = min(age), last_age = max(age) ) |>
  ungroup() |> 
   mutate(latest_year = year(latest) ) |>
   mutate(earliest_year=year(earliest) ) |> # renaming first_ to earliest_ to make consistent
   arrange(personLabel, bn_dob)
  #sorting has to happen in Obs Plot



## set an upper age cutoff for work and served. v few beyond 70 and it squishes things.
last_cutoff <- 70

##query without date property labels

bn_work_sparql <- 
'SELECT distinct ?person ?personLabel  ?positionLabel 
?date ?date_prop 
?position ?work  
?s

WHERE {
    
  ?person bnwdt:P3 bnwd:Q3 . # women
  
  # work activities: held position / held position (free text) /  employed as
  ?person (bnp:P17|bnp:P48|bnp:P105 ) ?s .  
     ?s (bnps:P17 | bnps:P48 | bnps:P105 ) ?position .  
     ?s ?work ?position . 
    
  # dates
      ?s (bnpq:P1 | bnpq:P27 | bnpq:P28  ) ?date.
         ?s ?date_prop ?date .   
      
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
  
} # /where

ORDER BY ?person
'

bn_work_query <-
  bn_std_query(bn_work_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(date_prop, position, work, s)) |>
  make_date_year() |>
  # add property labels
  mutate(date_propLabel = case_when(
    date_prop=="P1" ~ "point in time",
    date_prop=="P27" ~ "start time",
    date_prop=="P28" ~ "end time"
  ))  |>
  left_join(bn_properties |> select(bn_prop_id, propertyLabel), by=c("work"="bn_prop_id")) |>
  rename(workLabel=propertyLabel) |>
  relocate(s, person, .after = last_col())



bn_work_years_wide <-
bn_work_query |>
  # group by / top n to discard any extras before pivot
  #top_n -1 for the first of multi rows. arrange by date to ensure this is the earliest.
  group_by(s, date_propLabel) |>
  arrange(date, .by_group = T) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  select(-date, -date_prop) |>
  pivot_wider(names_from = date_propLabel, values_from = year) |>
  # don't forget this will rename *all* the camelCase columsn...
  clean_names("snake") |>
  mutate(start_year = if_else(!is.na(point_in_time), point_in_time, start_time)) |>
  #mutate(year1 = if_else(!is.na(year_point_in_time), year_point_in_time, year_start_time)) |>
  make_decade(start_year) |>
  #relocate(end_time, .after = start_time) |>
  mutate(end_year = case_when(
    !is.na(end_time) ~ end_time,
    !is.na(point_in_time) ~ point_in_time,
    !is.na(start_time) ~ start_time
  )) |>
  arrange(person_label,  start_year, end_year) |> 
  left_join(bn_women_dob_dod |> select(bn_dob_yr, bn_id), by="bn_id") |>
  mutate(work_age = start_year-bn_dob_yr) |>
  relocate(s, person, .after = last_col()) 

bn_work_years <-
bn_work_years_wide |>
  group_by(bn_id, person_label, start_year, bn_dob_yr, work_age) |>
  arrange(position_label, .by_group = T) |>
  summarise(n_yr=n(), positions = paste(unique(position_label), collapse = ", "), .groups = "drop_last") |>
  ungroup() |>
  rename(personLabel=person_label) |>
  left_join(bn_had_children_ages  |> count(bn_id, earliest, latest, start_age, last_age, name="n_kids"), by="bn_id") |>
  mutate(children = if_else(is.na(n_kids), "n", "y"))
  
bn_work_years_children <-
bn_work_years |>
	filter(children=="y" & work_age <= last_cutoff) |> 
	mutate(last_work_age = max(work_age), .by = bn_id) |>
  # just in case last child age is later than last work...
	mutate(last_work_age = if_else(last_work_age>last_age, last_work_age, last_age))
# bn_heldposition_years_active <-
# bn_heldposition_years |>
# semi_join(bn_women_list |> filter(statements>=20), by="bn_id") 




bn_served_sparql <-
  'SELECT distinct ?personLabel ?serviceLabel ?date_prop  ?date    ?person ?s ?service
WHERE {  
  ?person bnwdt:P3 bnwd:Q3 . # select women
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .} #filter out project team
   
  ?person bnp:P102 ?s .   # served on P102
     ?s bnps:P102 ?service .
    
  # dates
      ?s (bnpq:P1 | bnpq:P27 | bnpq:P28  ) ?date.
         ?s ?date_prop ?date .  

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb, en". } 
}

ORDER BY ?personLabel ?s'

bn_served_query <-
  bn_std_query(bn_served_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(date_prop, service, s)) |>
  make_date_year() |>
  # add property labels
  mutate(date_propLabel = case_when(
    date_prop=="P1" ~ "point in time",
    date_prop=="P27" ~ "start time",
    date_prop=="P28" ~ "end time"
  ))  |>
  relocate(s, person, .after = last_col())


##there are some start and end times... what was this here for?
# bn_served_query |>
#   count(date_propLabel)

# a few end date only; i think drop these?
bn_served_years_wide <-
  bn_served_query |>
  # group by / top n to discard any extras before pivot
  #top_n -1 for the first of multi rows. arrange by date to ensure this is the earliest.
  group_by(s, date_propLabel) |>
  arrange(date, .by_group = T) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  select(-date, -date_prop) |>
  pivot_wider(names_from = date_propLabel, values_from = year) |>
  # don't forget this will rename *all* the camelCase columsn...
  clean_names("snake") |>
  mutate(start_year = if_else(!is.na(point_in_time), point_in_time, start_time)) |>
  #mutate(year1 = if_else(!is.na(year_point_in_time), year_point_in_time, year_start_time)) |>
  make_decade(start_year) |>
  #relocate(end_time, .after = start_time) |>
  mutate(end_year = case_when(
    !is.na(end_time) ~ end_time,
    !is.na(point_in_time) ~ point_in_time,
    !is.na(start_time) ~ start_time
  )) |>
  arrange(person_label,  start_year, end_year) |> 
  left_join(bn_women_dob_dod |> select(bn_dob_yr, bn_id), by="bn_id") |>
  mutate(served_age = start_year-bn_dob_yr) |>
  relocate(s, person, .after = last_col()) 

bn_served_years <-
  bn_served_years_wide |>
  group_by(bn_id, person_label, start_year, bn_dob_yr, served_age) |>
  arrange(service_label, .by_group = T) |>
  summarise(n_yr=n(), service = paste(unique(service_label), collapse = ", "), .groups = "drop_last") |>
  ungroup() |>
  rename(personLabel=person_label) |>
  left_join(bn_had_children_ages  |> count(bn_id, earliest, latest, start_age, last_age, name="n_kids"), by="bn_id") |>
  mutate(children = if_else(is.na(n_kids), "n", "y"))

bn_served_years_children <-
  bn_served_years |>
  filter(children=="y" & served_age <= last_cutoff) |> 
  mutate(last_served_age = max(served_age), .by = bn_id) |>
  # just in case last child age is later than last work...
  mutate(last_served_age = if_else(last_served_age>last_age, last_served_age, last_age))


# repeat same process to add any other categories.


## spoke at
## restricting this to mothers only
## and to P1 dates, so won't need to faff with start-end

spoke_at_spql <-
'SELECT distinct ?person ?personLabel ?atLabel  ?at ?date ?s
WHERE {  
  values ?person {  <<bn_bnwd_values>> }
  #?person bnwdt:P3 bnwd:Q3 . # select women
   ?person bnp:P23 ?s .
      ?s bnps:P23 ?at . # women who spoke at 
  
  # may as well just get pit dates for this. only a handful of others.
    ?s bnpq:P1 ?date . 

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb". } 
}'

spoke_at_spql <-
'SELECT distinct ?person ?personLabel ?atLabel  ?at ?date ?s
WHERE {  
  values ?person {  <<bn_bnwd_values>> }
  #?person bnwdt:P3 bnwd:Q3 . # select women
   ?person bnp:P23 ?s .
      ?s bnps:P23 ?at . # women who spoke at 
  
  # may as well just get pit dates for this. only a handful of others.
    ?s bnpq:P1 ?date . 

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb". } 
}'

bn_spoke_sparql <-
bn_had_children_ages |>
  bn_make_union() |>
  mutate_glue_sparql(spoke_at_spql)

bn_spoke_query <-
  bn_std_query(bn_spoke_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(at, s)) |>
  make_date_year() |>
  select(-person)



bn_spoke_ages_years_children <-
bn_spoke_query |>
  distinct(bn_id, personLabel, atLabel, year) |>
  group_by(bn_id, year) |>
  arrange(atLabel, .by_group = TRUE) |>
  top_n(1, row_number()) |>
  ungroup() |>
  left_join(bn_had_children_ages  |> count(bn_id, bn_dob_yr, earliest, latest, start_age, last_age, name="n_kids"), by="bn_id") |>
  mutate(spoke_age = year-bn_dob_yr) |>
  # if you change your mind and get all, you can easily adjust this.
  mutate(children = "y")  |>
  filter(children=="y" & spoke_age <= last_cutoff) |> 
  mutate(last_spoke_age = max(spoke_age), .by = bn_id) |>
  # just in case last child age is later than last work...
  mutate(last_spoke_age = if_else(last_spoke_age>last_age, last_spoke_age, last_age))
  
  

# combine work/service into a single df

bn_work_served_years_children <-
 bind_rows( 
   bn_served_years |>
  filter(children=="y" & served_age <= last_cutoff) |> 
  mutate(last_activity_age = max(served_age), .by = bn_id) |>
  # just in case last child age is later than last work...
  mutate(last_activity_age = if_else(last_activity_age>last_age, last_activity_age, last_age)) |>
  rename(activity_age = served_age) |>
  mutate(activity="served")
  ,
  bn_work_years |>
	filter(children=="y" & work_age <= last_cutoff) |> 
	mutate(last_activity_age = max(work_age), .by = bn_id) |>
  # just in case last child age is later than last work...
	mutate(last_activity_age = if_else(last_activity_age>last_age, last_activity_age, last_age)) |>
  rename(activity_age=work_age) |>
  mutate(activity = "work")) |>
  relocate(positions, .after = service)  |>
  #if she has positions and service in the same year, drop service.
  group_by(bn_id, start_year) |>
  arrange(positions, service, .by_group = TRUE) |>
  top_n(-1, row_number()) |>
  ungroup()


## without spoke at (added in last ages all below)
## make updated last_age for ruleY. don't need first because start is fixed at 15.
## but do need bn_dob_yr for sorting

bn_last_ages <-
bind_rows(
  bn_had_children_ages |>
    distinct(bn_id, personLabel, bn_dob_yr, last_age) ,
  bn_served_years_children |>
    distinct(bn_id, personLabel, bn_dob_yr, last_served_age) ,
  bn_work_years_children |>
    distinct(bn_id, personLabel, bn_dob_yr, last_work_age)
  # add any further categories here...
) |>
  arrange(bn_id) |>
  pivot_longer(last_age:last_work_age, names_to = "age_type", values_to = "last", values_drop_na = TRUE) |>
  group_by(personLabel, bn_dob_yr) |>
  summarise(last_age = max(last), .groups = "drop_last") |>
  ungroup()





bn_work_served_spoke_years_children <-
 bind_rows( 
  bn_served_years |>
  filter(children=="y" & served_age <= last_cutoff) |> 
  mutate(last_activity_age = max(served_age), .by = bn_id) |>
  # just in case last child age is later than last work...
  mutate(last_activity_age = if_else(last_activity_age>last_age, last_activity_age, last_age)) |>
  rename(activity_age = served_age) |>
  mutate(activity="served", sort=2)
  ,
  bn_work_years |>
	filter(children=="y" & work_age <= last_cutoff) |> 
	mutate(last_activity_age = max(work_age), .by = bn_id) |>
  # just in case last child age is later than last work...
	mutate(last_activity_age = if_else(last_activity_age>last_age, last_activity_age, last_age)) |>
  rename(activity_age=work_age) |>
  mutate(activity = "work", sort=1)
  ,
  bn_spoke_ages_years_children |>
    rename(activity_age=spoke_age, last_activity_age=last_spoke_age, spoke=atLabel, start_year=year) |>
    mutate(activity="spoke", sort=3)
  ) |>
  relocate(positions, .after = service)  |>
  #in fact if you're going to toggle you only want to do the thing *per* activity type. i think. and i think this will work...
  #if she has positions / service  in the same year, positions first then service
  group_by(bn_id, start_year, activity) |>
  #arrange(positions, service,  .by_group = TRUE) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  # sort here so spoke is first, fixes tips priorities in the plot.
  arrange(-sort)


## make updated last_age for ruleY. don't need first because start is fixed at 15.
## but do need bn_dob_yr for sorting
## you may also need separate last_age per activity for the goggling... but let's start with this
bn_last_ages_all <-
bind_rows(
  bn_had_children_ages |>
    distinct(bn_id, personLabel, bn_dob_yr, last_age) ,
  bn_served_years_children |>
    distinct(bn_id, personLabel, bn_dob_yr, last_served_age) ,
  bn_work_years_children |>
    distinct(bn_id, personLabel, bn_dob_yr, last_work_age),
  bn_spoke_ages_years_children |>
    distinct(bn_id, personLabel, bn_dob_yr, last_spoke_age)
  # add any further categories here...
) |>
  arrange(bn_id) |>
  pivot_longer(last_age:last_spoke_age, names_to = "age_type", values_to = "last", values_drop_na = TRUE) |>
  group_by(personLabel, bn_dob_yr) |>
  summarise(last_age = max(last), .groups = "drop_last") |>
  ungroup()