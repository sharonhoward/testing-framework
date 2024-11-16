# need date types and probably precise values as well?
# in fact nearly all year only

bn_women_educated_dates_sparql <-
'SELECT ?personLabel ?collegeLabel ?universityLabel ?organisedLabel ?subjectLabel ?date_qual ?date_prop ?date_precision ?s ?college ?university ?subject ?organised ?person

WHERE {  
  ?person bnwdt:P3 bnwd:Q3 . #select women
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .} #filter out project team
  
  # note: academic degree is P59. 
  ?person bnp:P94 ?s .  # educated at
    ?s bnps:P94 ?college .
      ?college bnwdt:P12 bnwd:Q2914 .   # tertiary ed inst
      optional {?college bnwdt:P4 ?university . } # a few college arent part of a university
      optional {?s bnpq:P109 ?organised . } # some extension centres
      optional {?s bnpq:P60 ?subject . } 
   
  # dates. timevalue and precision.
         # pit/start/end. there are a few earliest/latest as well.
      ?s (bnpqv:P1 | bnpqv:P27 | bnpqv:P28  ) ?pqv. 
      ?s ?date_prop ?pqv.
          ?pqv wikibase:timeValue ?date_qual .
          ?pqv wikibase:timePrecision ?date_precision .  
  
  SERVICE wikibase:label {bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb,en".}
}
order by ?personLabel ?collegeLabel ?date_qual'

bn_women_educated_dates_query <-
  bn_std_query(bn_women_educated_dates_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(college, university, subject, date_prop, organised, s)) |>
  mutate(across(c(university, organised, subject, universityLabel, organisedLabel, subjectLabel), ~na_if(., ""))) |>
  mutate(date_label = date_property_labels(date_prop)) |>
  # precision
  mutate(date_precision = case_when(
    date_precision==9 ~ "y",
    date_precision==10 ~ "ym",
    date_precision==11 ~ "ymd"
  )) |>
  # parsed posixct date
  mutate(date = parse_date_time(date_qual, "ymdHMS"))  |>
  mutate(year = year(date)) |>
  relocate(person, s, .after = last_col())
  

bn_women_educated_dates_wide <-
bn_women_educated_dates_query |>
  # convert uv subject to NA, 
  mutate(across(c(subject, subjectLabel),  ~if_else( str_detect(., "^(_:)?t\\d+$"), NA, . ))) |>
  # drop all alternative provision including extension centres for now. then don't need date_precision as all are year.
  filter(college != "Q2485") |>
  # distinct fixes dups caused by subjects (for now...)
  distinct(bn_id, personLabel, collegeLabel, college, universityLabel, university, date, date_qual, year, date_label, s) |>
  # c() in values_from. that's all folks
  pivot_wider(names_from = date_label, values_from = c(date, date_qual, year)) |>
  clean_names("snake") |>
  # create by_label to match degrees 
    mutate(by = case_when(
    !is.na(university) ~ university,
    !is.na(college) ~ college
  )) |>
  mutate(by_label = case_when(
    !is.na(university_label) ~ university_label,
    !is.na(college_label) ~ college_label
  )) |>
  # col names are long... if renaming, need to be careful that new col names will be unique.
  #rename_with(~str_remove(., "^date_"), starts_with("date_")) |>
  mutate(date_pairs = case_when(
    !is.na(date_point_in_time) ~ "1 single",
    !is.na(date_start_time) & !is.na(date_end_time) ~ "2 both",
    !is.na(date_start_time) ~ "3 start",
    !is.na(date_end_time) ~ "4 end"
  ))  |>
  # no point in keeping women who don't have dob...
  left_join(
    bn_women_dob_dod |> select(bn_id, statements, bn_dob, bn_dod, bn_dob_yr, bn_dod_yr), by="bn_id"
  ) |>
  filter(!is.na(bn_dob_yr))




bn_women_educated_dates_long <-
bn_women_educated_dates_wide |>
  select(bn_id, person_label, college_label, university_label, by_label, year_start_time, year_end_time, year_point_in_time, 
         date_pairs, bn_dob_yr, bn_dod_yr, s ) |>
  pivot_longer(c(year_start_time, year_end_time, year_point_in_time ), names_to = "year_type", values_to = "year", values_drop_na = TRUE) |>
  mutate(year_type=str_remove(year_type, "year_")) |>
  mutate(age = year-bn_dob_yr) |>
  mutate(age_death = bn_dod_yr-bn_dob_yr) |>
  relocate(year, year_type, age, age_death, .after = college_label)
  
  
# don't need this if you've already filtered ages...
#bn_women_educated_ages_long <-
#bn_women_educated_dates_long |>
#	filter(!is.na(bn_dob_yr))







bn_academic_degrees_sparql <-
'SELECT distinct ?person ?personLabel ?degreeLabel ?byLabel ?subjectLabel ?date ?date_precision ?date_prop ?s ?by ?degree ?subject

WHERE {  
  ?person bnwdt:P3 bnwd:Q3 . #select women
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .} #filter out project team
  
  # academic degree = P59. 
  ?person bnp:P59 ?s .  
    ?s bnps:P59 ?degree . # type of degree
  
  # P61 conferred by
    optional { ?s bnpq:P61 ?by . }
  
  # p60 subject
    optional { ?s bnpq:P60 ?subject . }
  
  # dates. timevalue and precision.  # pit/start/end. no earliest p53; about 30 latest. omit start time p27. 
  optional {
      ?s (bnpqv:P1 | bnpqv:P28 |  bnpqv:P51  ) ?pqv. 
      ?s ?date_prop ?pqv.
          ?pqv wikibase:timeValue ?date .
          ?pqv wikibase:timePrecision ?date_precision . 
  }
  SERVICE wikibase:label {bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb,en".}
}
order by ?personLabel'


bn_academic_degrees_query <-
  bn_std_query(bn_academic_degrees_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(degree, by, subject, date_prop, s)) |>
  mutate(across(c(by, subject, byLabel, subjectLabel, date, date_prop), ~na_if(., ""))) |>
  make_date_year() |>
  mutate(date_propLabel = date_property_labels(date_prop)) |>
  relocate(s, person, .after = last_col())






bn_academic_degrees <-
bn_academic_degrees_query |>
  # convert uv by/subject to NA
  mutate(across(c(by, subject, byLabel, subjectLabel),  ~if_else( str_detect(., "^(_:)?t\\d+$"), NA, . ))) |>
  # drop latest date if there is a more precise date available, otherwise keep them for now
  add_count(s) |> 
  filter(date_prop !="P51" | n==1  ) |> # seems to be ok for NAs
  select(-n) |>
  # make a date type for latest v others
  mutate(year_type = case_when(
    is.na(date_prop) ~ NA,
    date_prop=="P51"~ "latest_date", 
    .default = "point_in_time")) |>
  relocate(year_type, .after = date) |>
  left_join(bn_women_dob_dod |> select(bn_id, bn_dob_yr, bn_dod_yr), by="bn_id") |>
  filter(!is.na(bn_dob_yr)) |>
  mutate(age= year-bn_dob_yr, age_death=bn_dod_yr-bn_dob_yr)


# shouldn't be any dup now...
# bn_academic_degrees |>
#   add_count(s) |> filter(n>1)


bn_academic_degrees_ages <-
bn_academic_degrees |>
  select(bn_id, personLabel, degreeLabel, byLabel, year, year_type, age, age_death, bn_dob_yr, bn_dod_yr, s) |>
  # make colnames match
  clean_names("snake")|>
  filter(!is.na(year)) |>
	#filter(!is.na(bn_dob_yr)) |> # only drop 8 rows
#  group_by(bn_id) |>
#  mutate(age_last = max(age), year_last=max(year)) |>
#  ungroup() |>
  mutate(date_pairs = "1 single")



bn_women_education_degrees <-
bind_rows(
  bn_women_educated_dates_long |> 
  	mutate(src="educated") |> 		
  	select(-university_label, -college_label) ,
  bn_academic_degrees_ages |> 
  mutate(src="degrees") 
) |>
  relocate(s, .after = last_col()) |>
  relocate(src, .after = bn_id) |>
  arrange(bn_id, year, by_label)  |>
  # surely this needs to go in after combining all dates?
  group_by(bn_id) |>
  mutate(age_last = max(age), year_last=max(year)) |>
  ungroup() 



# start-end interval years filled in. start-end pairs only.
bn_women_educated_start_end_years <-
bn_women_educated_dates_wide |>
  # not sure where this should go? see if you have any problems
	#filter(!is.na(bn_dob_yr)) |>
  filter(date_pairs=="2 both") |>
  # purrr::map2 and seq() to fill out a list from a start number to given end number. then unnest to put each one on a new row.
  mutate(year = map2(year_start_time, year_end_time, ~seq(.x, .y, by=1))) |>
  unnest(year)  |>
  mutate(age = year-bn_dob_yr)  |>
  mutate(src="educated")   |>
  mutate(age_death = bn_dod_yr-bn_dob_yr)  
#  group_by(bn_id) |>
#  mutate(age_last = max(age)) |>
#  ungroup()  
  
  
  
  
# version with start-end interval years filled in. start/end only treated like point
bn_women_educated_ages_long <-
bn_women_educated_dates_wide |>
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
    # no latest in educated...?
  mutate(year_type= case_when(
    date_pairs=="1 single" ~ "point_in_time",
    date_pairs=="4 end" ~ "end_time",
    date_pairs=="3 start" ~ "start_time",
    date_pairs=="2 both" & year_start_time==year ~ "start_time",
    date_pairs=="2 both" & year_end_time==year ~ "end_time",
    date_pairs=="2 both" ~ "filled"
  )) |>
  mutate(age = year-bn_dob_yr) |>
  # not sure if this should be before doing start/end years? see if you have any problems. but how can you do age_last before adding degrees?
	#filter(!is.na(bn_dob_yr)) |>
  mutate(age_death = bn_dod_yr-bn_dob_yr)  |>
#  group_by(bn_id) |>
#  mutate(age_last = max(age), year_last=max(year)) |>
#  ungroup()  |>
  select(bn_id, person_label, by_label, year, age, date_pairs, year_type,
  # age_last, year_last, 
  bn_dob_yr, bn_dod_yr, age_death, start_year, end_year, s) |>
  mutate(src="educated") |>
  arrange(bn_id, start_year, year)
  
  
# ## to go with v2 of educated
bn_academic_degrees_ages2 <-
bn_academic_degrees_ages |>
  mutate(src="degrees") |>
  relocate(age, date_pairs, .after = year)
  

bn_women_education_degrees2 <-
	bind_rows(bn_women_educated_ages_long, bn_academic_degrees_ages2)  |>
  group_by(bn_id) |>
  mutate(age_last = max(age), year_last=max(year)) |>
  ungroup() 