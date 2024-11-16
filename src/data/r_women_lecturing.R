# shared libraries, functions etc ####


##query without date property labels

bn_lecturers_sparql <- 
'SELECT distinct ?person ?personLabel ?workLabel  ?positionLabel 
?date ?date_precision ?pq
?organisedLabel ?ofLabel 
?position ?of  ?work ?organised 
?s

WHERE {
    
  ?person bnwdt:P3 bnwd:Q3 . # women
  
  # work activities: held position / held position (free text) /  employed as
  #?person ( bnp:P17|bnp:P48|bnp:P105 ) ?s .  
  
  ?person ?work_p ?s . # for activity type label
    ?work wikibase:claim ?work_p .  

    ?s ?bnps ?position .  
    # freelance and extension lecturing (q701 and q3021)
    { ?s ?bnps bnwd:Q701  . } union { ?s ?bnps bnwd:Q3021 .  }
  
    # employer / organised by / of (incl free text). 
    # dont appear to be any employer for this subset
    #OPTIONAL { ?s bnpq:P18 ?employer .}  
    OPTIONAL { ?s bnpq:P109 ?organised .}
    OPTIONAL { ?s ( bnpq:P78 | bnpq:P66 ) ?of .}
 
   # optional { ?s bnpq:P2 ?location . } # do locations separately.
    
  # dates - get precision here because some are almost certainly yyyy
    optional {
      ?s (bnpqv:P1 | bnpqv:P27 | bnpqv:P28  ) ?pqv.
      ?s ?pq ?pqv . # just gets the uri but doesnt seem to cause dups
         ?pqv wikibase:timeValue ?date .  
         ?pqv wikibase:timePrecision ?date_precision .
      
      # doesnt seem to make much difference to time here, but does change number of results
      #?s ?pq ?date .   
      #    ?date_prop wikibase:qualifier ?pq .
      #    ?date_prop wikibase:propertyType wikibase:Time.  
      
      } # /dates
   
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
  
} # /where

ORDER BY ?person
'

bn_lecturers_query <-
  bn_std_query(bn_lecturers_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(pq, position, of, work, organised, s)) |>
  mutate(across(c(organisedLabel, ofLabel, of, organised, pq), ~na_if(., ""))) |>
  make_date_year() |>
  # add the date property labels
  mutate(date_propLabel = case_when(
    pq=="P1" ~ "point in time",
    pq=="P27" ~ "start time",
    pq=="P28" ~ "end time"
  )) |>
  rename(date_prop=pq)  |>
  relocate(person, .after = last_col())


bn_lecturers_dates <-
bn_lecturers_query |>
  filter(!is.na(date)) |>
  select(bn_id, personLabel, date, date_propLabel, year, date_precision, positionLabel, organisedLabel, ofLabel, organised, of, position, work, s) |>
  # group by / top n to discard any extras before pivot
  #top_n -1 for the first of multi rows. arrange by date to ensure this is the earliest.
  group_by(s, date_propLabel) |>
  arrange(date, .by_group = T) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  pivot_wider(names_from = date_propLabel, values_from = c(date, date_precision, year)) |>
  # don't forget this will rename *all* the camelCase columsn...
  clean_names("snake") |>
  #not sure why r prefixes all the pivoted cols 
  rename_with(~str_remove(., "^date_"), starts_with("date_")) |>
  mutate(start_date = if_else(!is.na(point_in_time), point_in_time, start_time)) |>
  mutate(year1 = if_else(!is.na(year_point_in_time), year_point_in_time, year_start_time)) |>
  make_decade(year1) |>
  relocate(end_time, .after = start_time) |>
  relocate(year_end_time, .after = year_start_time) |>
  mutate(end_date = case_when(
    !is.na(end_time) ~ end_time,
    !is.na(point_in_time) ~ point_in_time,
    !is.na(start_time) ~ start_time
  )) |>
  mutate(precision = case_when(
    precision_end_time>precision_start_time ~ precision_end_time,
    !is.na(precision_start_time) ~ precision_start_time,
    !is.na(precision_point_in_time) ~ precision_point_in_time
  )) |>
  # consolidate of/organised by; "none recorded" for NA if extension.
  mutate(organisation = case_when(
    !is.na(of_label) ~ of_label,
    !is.na(organised_label) ~ organised_label,
    #position=="Q701" ~ "none (freelance)",
    .default = "none recorded"
  )) |>
  relocate(organisation, .after = of) |>
  mutate(is_mm = if_else(bn_id=="Q569", "MM", "other")) |>
  arrange(person_label,  start_date) |> 
  left_join(bn_women_dob_dod, by="bn_id")  |>
  add_count(organisation, name="n_ext") |>
  mutate(organisation_ext = case_when(
    #n_ext<2 & str_detect(organisation, "[Ee]xten.ion") ~ "Other extension centres",
    n_ext<2 & position_label=="Lecturer (Extension)" ~ "Other extension centres",
    .default = organisation
  ))|>
  mutate(m = as.character(month(start_date, label=TRUE, abbr=FALSE))) |>
  mutate(d = day(start_date)) |>
  mutate(nice_date = case_when(
    precision==9 ~ as.character(year1),
    precision==10 ~ paste(m, year1 ),
    precision==11 ~ paste(d, m, year1)
  )) |>
  relocate(s, .after = last_col()) 
  

 