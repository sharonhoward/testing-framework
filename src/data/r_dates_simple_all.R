
bn_simple_main_date_sparql <-
'SELECT distinct   ?person ?personLabel ?propLabel  ?date_value ?s   ?prop 
WHERE {
   ?person bnwdt:P3 bnwd:Q3 . # women  
   FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . }  
   ?person ?p ?s .        
     ?prop wikibase:claim ?p .
     ?prop wikibase:statementProperty ?ps .

      {   ?prop wikibase:propertyType wikibase:Time.  }
      union
      {    ?prop wikibase:propertyType wikibase:Edtf . }

       ?s ?ps ?date_value . 
    
   FILTER ( datatype(?date_value) = xsd:dateTime ) .

 SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb,en". } 
        
} # /where

ORDER BY ?person'

bn_simple_main_date_query <-
  bn_std_query(bn_simple_main_date_sparql) |>
  make_bn_ids(c(person, prop, s))

# TODO need to add named child/widowed...



bn_simple_qual_date_sparql <-
'SELECT distinct   ?person ?personLabel ?propLabel ?psvLabel ?qual_dateLabel ?date_value ?s  ?psv ?prop ?qual_date
WHERE {
   ?person bnwdt:P3 bnwd:Q3 . # women   
   FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . } 
   ?person ?p ?s .        
     ?prop wikibase:claim ?p .
     ?prop wikibase:statementProperty ?ps .
  
        ?s ?ps ?psv .
        
        ?s ?pq ?date_value .   
          ?qual_date wikibase:qualifier ?pq .
          ?qual_date wikibase:propertyType wikibase:Time. 
  
 SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb,en". } 
        
} # /where

ORDER BY ?person '

bn_simple_qual_date_query <-
  bn_std_query(bn_simple_qual_date_sparql) |>
  make_bn_ids(c(person, prop, psv, qual_date, s))
  
  
  
bn_simple_dates <-  
bind_rows(bn_simple_main_date_query, 
          bn_simple_qual_date_query
          ) |>
  mutate(prop_label = str_remove(propLabel, " *\\((EDTF value|PIT value|free text|item)\\)$"))  |>
    mutate(date = if_else(str_detect(date_value, "^_:t"), NA, date_value))  |>
    mutate(date = parse_date_time(date, "ymdHMS"))  |>
    filter(!is.na(date)) |>
    mutate(year = year(date))  |>
    mutate(month = month(date)) |>
    mutate(day = yday(date)) |> # numeric day of year
    #filter(between(year, 1900, 1910)) |>
  mutate(date = as.character(date)) |>
  # add some date categories for colours
  mutate(category = case_when(
    prop =="P26" ~ "birth",
    prop=="P15" ~ "death",
    prop %in% c("P17", "P48", "P105") ~ "work",
    prop %in% c("P94", "P59") ~ "education",
    .default = "other"
  )) |>
  #relocate(psvLabel, qual_dateLabel, prop_label, .after = propLabel) |>
  arrange(year, day, category, prop_label, psvLabel)
  


