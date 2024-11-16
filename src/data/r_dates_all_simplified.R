
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