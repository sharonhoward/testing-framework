bn_women_bm_sparql <-
'SELECT ?person ?personLabel ?date ?s
WHERE {  
  ?person bnwdt:P3 bnwd:Q3 . 
  ?person bnp:P67 ?s .
  ?s bnps:P67 bnwd:Q4379 . # was member of BM reading room
  
  ?s bnpq:P27 ?date .
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb". } 
}
order by ?personLabel'

bn_women_bm_query <-
  bn_std_query(bn_women_bm_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(s)) |>
  # use make date function; filter out any NAs 
  make_date_year() |>
  filter(!is.na(date)) |>
  relocate(person, s, .after = last_col())

# only 30 of 34 have dob so don't mandate that. sort by date of [first] admission instead. but do get the ages where available for tips.

bn_women_bm <-
bn_women_bm_query |>
	mutate(src="bm") |>
	group_by(bn_id) |>
	mutate(earliest_bm = min(year)) |>
	ungroup() |>
  left_join(
    bn_women_dob_dod |> select(bn_id, bn_dob, bn_dob_yr), by="bn_id"
  )  |>
  mutate(age = if_else(!is.na(bn_dob_yr), as.character(year-bn_dob_yr), "")) |>
  rename(person_label=personLabel) |>
  mutate(group = if_else(earliest_bm>=1890, "1890s", "1880s"))


bn_women_bm_educated_dates_sparql <-
'SELECT ?personLabel ?collegeLabel ?universityLabel ?organisedLabel ?subjectLabel ?date ?date_prop ?s ?college ?university ?subject ?organised ?person 

WHERE {  
  ?person bnwdt:P3 bnwd:Q3 . #select women
  ?person bnwdt:P67 bnwd:Q4379 . # was member of BM reading room
  
  # note: academic degree is P59. 
  ?person bnp:P94 ?s .  # educated at
    ?s bnps:P94 ?college .
      ?college bnwdt:P12 bnwd:Q2914 .   # tertiary ed inst
      optional {?college bnwdt:P4 ?university . } # a few college arent part of a university
      optional {?s bnpq:P109 ?organised . } # some extension centres
      optional {?s bnpq:P60 ?subject . } 
     
   # CHANGE: simple dates instead of precision. 
  # dates. 
         # pit/start/end
      ?s (bnpq:P1 | bnpq:P27 | bnpq:P28  ) ?date . 
      ?s ?date_prop ?date.
  
  SERVICE wikibase:label {bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb,en".}
}
order by ?personLabel ?collegeLabel ?date'

bn_women_bm_educated_dates_query <-
  bn_std_query(bn_women_bm_educated_dates_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(college, university, subject, date_prop, organised, s)) |>
  mutate(across(c(university, organised, subject, universityLabel, organisedLabel, subjectLabel), ~na_if(., ""))) |>
  mutate(date_label = date_property_labels(date_prop)) |>
  # CHANGES ####
  # use make date function; filter NAs 
  make_date_year() |>
  filter(!is.na(date)) |>
  relocate(person, s, .after = last_col())



bn_women_bm_educated_dates_wide <-
bn_women_bm_educated_dates_query |>
  # convert uv subject to NA, 
  mutate(across(c(subject, subjectLabel),  ~if_else( str_detect(., "^(_:)?t\\d+$"), NA, . ))) |>
  # want to drop alternative provision other than extension centres. but might be more than one in a year? i think it's ok if you're dropping subject...
  filter(college != "Q2485" | !is.na(organised)) |>
  # CHANGES from original for extension centres; work ok at present but might need to watch for this.
  # distinct fixes dups caused by subjects. maybe drop date?
  distinct(bn_id, personLabel, collegeLabel, college, universityLabel, university, organisedLabel, organised, date, year, date_label, s) |>
  # c() in values_from. that's all folks
  pivot_wider(names_from = date_label, values_from = c(date, year)) |>
  clean_names("snake") |>
  # create by_label to match degrees 
    mutate(by = case_when(
    college=="Q2485" ~ organised,
    !is.na(university) ~ university,
    !is.na(college) ~ college
  )) |>
  mutate(by_label = case_when(
  college=="Q2485" ~ organised_label,
    !is.na(university_label) ~ university_label,
    !is.na(college_label) ~ college_label
  )) |>
# end of extension centre changes
  # col names are long... if renaming, need to be careful that new col names will be unique.
  #rename_with(~str_remove(., "^date_"), starts_with("date_")) |>
  # no latest date in this version
  mutate(date_pairs = case_when(
    !is.na(date_point_in_time) ~ "1 single",
    !is.na(date_start_time) & !is.na(date_end_time) ~ "2 both",
    !is.na(date_start_time) ~ "3 start",
    !is.na(date_end_time) ~ "4 end"
  ))  |>
  left_join(
    bn_women_dob_dod |> select(bn_id, bn_dob, bn_dob_yr), by="bn_id"
  ) 


# start-end interval years filled in. start-end pairs only. is this used?
bn_women_bm_educated_start_end_years <-
bn_women_bm_educated_dates_wide |>
  filter(date_pairs=="2 both") |>
  # purrr::map2 and seq() to fill out a list from a start number to given end number. then unnest to put each one on a new row.
  mutate(year = map2(year_start_time, year_end_time, ~seq(.x, .y, by=1))) |>
  unnest(year)  |>
  mutate(src="educated")   
#  mutate(age = year-bn_dob_yr)  |>
#  mutate(age_death = bn_dod_yr-bn_dob_yr)  
  
  
# version with start-end interval years filled in. start/end only treated like point
bn_women_bm_educated_ages_long <-
bn_women_bm_educated_dates_wide |>
  mutate(start_year = case_when(
    date_pairs=="2 both" ~ year_start_time,
    date_pairs=="1 single" ~ year_point_in_time,
    date_pairs=="3 start" ~ year_start_time,
    date_pairs=="4 end" ~ year_end_time
  )) |>
  mutate(end_year = case_when(
    date_pairs=="2 both" ~ year_end_time,
    date_pairs=="1 single" ~ year_point_in_time,
    date_pairs=="3 start" ~ year_start_time,
    date_pairs=="4 end" ~ year_end_time
  ))  |>
  # purrr::map2 and seq() to fill out a list from a start number to given end number. then unnest to put each one on a new row.
  mutate(year = map2(start_year, end_year, ~seq(.x, .y, by=1))) |>
  unnest(year)  |>
  # CHANGE _ to space in year type 
  mutate(year_type= case_when(
    date_pairs=="1 single" ~ "point in time",
    date_pairs=="4 end" ~ "end time",
    date_pairs=="3 start" ~ "start time",
    date_pairs=="2 both" & year_start_time==year ~ "start time",
    date_pairs=="2 both" & year_end_time==year ~ "end time",
    date_pairs=="2 both" ~ "filled"
  )) |>
  mutate(age = if_else(!is.na(bn_dob_yr), as.character(year-bn_dob_yr), "")) |>
  select(bn_id, person_label, by_label, year, age, date_pairs, year_type,  bn_dob_yr, start_year, end_year, s) |>
  mutate(src="educated") |>
  arrange(bn_id, start_year, year) |>
  # add bm group
  left_join(
    bn_women_bm |>
    distinct(bn_id, group), by="bn_id"
  )
  
