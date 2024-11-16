## this has to go AFTER shared r.

## it is quite slow but Obs caches it so it doesn't need to be run very often.

## fetch all dates for women from wikibase ####

bn_precise_dates_all_sparql <-
  'SELECT distinct ?person ?personLabel ?propLabel ?prop_valueLabel ?date  ?date_precision ?qual_date_prop ?prop_value ?prop ?s

WHERE {
    ?person bnwdt:P3 bnwd:Q3 . # women
    FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . } 
  
    # get stuff about ?person   
    ?person ?p ?s .   
  
      # the claim for ?p .  do i need psv as well as ps?
      ?prop wikibase:claim ?p;      
         wikibase:statementProperty ?ps.
 
  # the direct value (usually item) for the property, things like annual meeting, girton college. .
        ?s ?ps ?prop_value.
     
  # qualifier timevalue and precision. 
  # pit/start/end/earliest/latest 
      ?s ?qual_date_prop ?pqv.
          ?pqv wikibase:timeValue ?date .  
          ?pqv wikibase:timePrecision ?date_precision .
      
 SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en, en-gb". } 
  
} # /where

ORDER BY ?personLabel ?s ?prop_label'


bn_precise_dates_all_query <-
  bn_std_query(bn_precise_dates_all_sparql) |>
  make_bn_item_id(person) |> 
  make_bn_ids(c(qual_date_prop, prop_value, prop, s)) |>
  select(-person) |>
  # drop pit versions of edtf dates
  filter(!prop %in% c("P131", "P132", "P133") | !str_detect(prop_valueLabel, "T00:00:00Z")) 


# pre processing

bn_precise_dates_pre_qual <-
bn_precise_dates_all_query |>
  filter(!prop %in% c("P131", "P132", "P133") & prop_value != date ) 

bn_precise_dates_pre_edtf <-
bn_precise_dates_all_query |> 
  filter(prop %in% c("P131", "P132", "P133")) |>
  select(bn_id, personLabel, date_propLabel= propLabel, date=prop_value, date_precision, date_prop= prop, s) 

bn_precise_dates_pre_pit <-
bn_precise_dates_all_query |> 
  filter(!prop %in% c("P131", "P132", "P133") & prop_value==date) |>
  select(bn_id, personLabel, date_propLabel= propLabel, date, date_precision, date_prop= prop, s) 




# pretty sure these queries drop <uv> dates. but might not always be the case
# qual prop value can contain stuff other than Qs


## edtf-notes ####

## docs: The characters '?', '~' and '%' are used to mean "uncertain", "approximate", and "uncertain" as well as "approximate", respectively. These characters may occur only at the end of the date string and apply to the entire date.

#    parse_date_time('1984?', "y")  # ? is ignored and date parsed as 1984-01-01  
#    parse_date_time('2004-06~', "ym") # ~ is ignored and date parsed as 2004-06-01
#    parse_date_time('2004-06-11%', "ymd")   # **fails to parse**
# parse_date_time(str_remove('2004%', "%$"), "y") # ok

## edtf documentation https://www.loc.gov/standards/datetime/
## wikibase Time datatype https://www.wikidata.org/wiki/Help:Dates#Time_datatype




## dates processing ####


bn_precise_dates_qual <-
  bn_precise_dates_pre_qual |>
  mutate(date = if_else(str_detect(date, "t"), NA, date))  |> # shouldn't be any of these actually!
  mutate(date = parse_date_time(date, "ymdHMS"))  |>
  mutate(year = year(date)) |>
  mutate(date_label = date_property_labels(qual_date_prop)) |>
  mutate(date_string = case_when(
    date_precision==11 ~  as.character(date),
    date_precision==10 ~ str_replace(as.character(date), "-\\d\\d$", "-00"),
    date_precision==9 ~ paste0(year, "-00-00")
  ) ) |>
  mutate(date_precision = case_when(
    date_precision==11  ~ "ymd",
    date_precision==10 ~ "ym",
    date_precision==9 ~ "y",
  )) |>
  mutate(date_certainty = case_when(
    str_detect(date_label, "earliest") ~ "earliest",
    str_detect(date_label, "latest") ~ "latest"
  ))  |>
  mutate(date_level = "qual") |>
  relocate(date, year, date_precision, date_certainty, date_label, date_level, date_string, .after = personLabel) |>
  # AT recorded by dates. other than being c.2022 can't be differentiated from historical dates.
  filter(year < 2020 ) 



bn_precise_dates_edtf <-
  bn_precise_dates_pre_edtf |>
  # edtf certainty. currently little used but could become more significant
  # The characters '?', '~' and '%' = "uncertain", "approximate", and "uncertain" as well as "approximate", respectively. only at the end of the date string and apply to the entire date.
  # parse_date_time ignores ? and ~ but fails on % . handle with str_remove() 
  mutate(date_certainty = case_when(
    str_detect(date, "%$") ~ "approx-uncertain", 
    str_detect(date, "\\?$") ~ "uncertain",
    str_detect(date, "~$") ~ "approx"
  )) |>
  #mutate(date_edtf = date) |>
  # remove any % from edtf dates before parsing. do same to ~ and ? as well just in case
  mutate(date = parse_date_time(str_remove(date, "[%?~]$"), c("ymd", "ym", "y")) )  |>
  # make single date / year column. 
  mutate(year = year(date))  |>
  mutate(date_string = case_when(
    date_precision==11 ~  as.character(date),
    date_precision==10 ~ str_replace(as.character(date), "-\\d\\d$", "-00"),
    date_precision==9 ~ paste0(year, "-00-00")
  ) ) |>
  mutate(date_precision = case_when(
    date_precision==11  ~ "ymd",
    date_precision==10 ~ "ym",
    date_precision==9 ~ "y",
  ))  |>
  mutate(date_label="edtf")|>
  mutate(date_level = "main") |>
  relocate(date, year, date_precision, date_certainty, date_label, date_level, date_string, .after = date_propLabel) 




bn_precise_dates_pit <-
  bn_precise_dates_pre_pit  |>
  # in case there are any <uv>
  mutate(date = if_else(str_detect(date, "t"), NA, date))  |>
  mutate(date = parse_date_time(date, "ymdHMS"))  |>
  # make single date / year column. 
  mutate(year = year(date)) |>
  mutate(date_string = case_when(
    date_precision==11 ~  as.character(date),
    date_precision==10 ~ str_replace(as.character(date), "-\\d\\d$", "-00"),
    date_precision==9 ~ paste0(year, "-00-00")
  ) )  |>
  mutate(date_precision = case_when(
    date_precision==11  ~ "ymd",
    date_precision==10  ~ "ym",
    date_precision==9 ~ "y",
  )) |>
  # add a type label
  mutate(date_label="point in time") |>
  mutate(date_level = "main") |>
  relocate(date, year, date_precision,  date_label, date_level, date_string, .after = date_propLabel) 






bn_precise_dates <-
  bind_rows(
    bn_precise_dates_qual |>
      rename(date_prop=prop, date_propLabel= propLabel) ,
    bn_precise_dates_pit ,
    bn_precise_dates_edtf
  )  |>
  mutate(month = month(date)) |>
  mutate(day = yday(date)) |> # numeric day of year for sorting
  mutate(m = as.character(month(date, label=TRUE, abbr=FALSE))) |>
  mutate(nice_date = case_when(
    date_precision=="y" ~ as.character(year),
    date_precision=="ym" ~ paste(m, year ),
    date_precision=="ymd" ~ paste( day(date) , m, year)
  ))  |>
  # add date categories we want to highlight
  mutate(category = case_when(
    date_prop =="P26" ~ "birth",
    date_prop=="P15" ~ "death",
    date_prop %in% c("P17", "P48", "P105") ~ "work",
    date_prop %in% c("P94", "P59") ~ "education",
    .default = "other"
  ))  |>
  # not sure about this one...
  mutate(prop_label = str_remove(date_propLabel, " *\\((EDTF value|PIT value|free text|item)\\)$"))  |>
  # is this necessary?
  mutate(date2 = as.Date(date)) |>
  relocate(prop_value, prop_label, .after = date_prop) |>
  relocate(s, .after = last_col()) |>
  rename(person=bn_id) |>
  #relocate(psvLabel, qual_dateLabel, prop_label, .after = propLabel) |>
  arrange(year, day, category, prop_label, prop_valueLabel)


