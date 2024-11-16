# shared libraries, functions etc ####

source("./src/data/shared.R") 



bn_instance_of_paths_sparql <- 
  'SELECT distinct ?item ?itemLabel ?instance ?instanceLabel ?instance2 ?instance2Label ?s
  WHERE {  
 
   ?item bnp:P12 ?s .
      ?s bnps:P12 ?instance  . # instance of 

      ?instance bnwdt:P12* ?instance2 .

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb, en". } 
}
ORDER BY ?itemLabel'

bn_instance_of_paths_query <-
  bn_std_query(bn_instance_of_paths_sparql) |>
  make_bn_ids(c(item, instance, instance2, s))



bn_instance_of_paths_qual_sparql <-
  'SELECT distinct ?item ?itemLabel ?instance ?instanceLabel  ?instance2 ?instance2Label ?s
WHERE {  

    ?i ?p ?s .
      ?prop wikibase:claim ?p .
      ?prop wikibase:statementProperty ?ps .
    
      ?s ?ps ?item .
  
      ?s bnpq:P12 ?instance .
   
    ?instance bnwdt:P12* ?instance2 .

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb, en". } 
}
ORDER BY ?itemLabel'

bn_instance_of_paths_qual_query <-
  bn_std_query(bn_instance_of_paths_qual_sparql) |>
  make_bn_ids(c(item, instance, instance2, s))


## combine main and quals

bn_instance_of_paths_main_qual <-
bn_instance_of_paths_query |>
  mutate(path="main") |>
  bind_rows(bn_instance_of_paths_qual_query |> mutate(path="qual")) 
  
  
bn_instance_of_paths_collapsed <-
bn_instance_of_paths_main_qual  |>
  distinct(instanceLabel, instance, instance2Label, instance2) |>
  group_by(instance) |>
  mutate(rn = row_number()) |>
  mutate(depth = max(rn)) |>
  ungroup() |>
  # is bucket always highest rn. 
  #filter(instance2Label=="bucket" & rn != depth)
  group_by(instanceLabel, instance, depth) |>
  arrange(-rn, .by_group = TRUE) |>
  summarise(paths = paste0(instance2Label, collapse = "/"), .groups = "drop_last") |>
  ungroup()
  
  
bn_instance_of_paths_collapsed |>
  pull(paths) |>
  jsonlite::toJSON()