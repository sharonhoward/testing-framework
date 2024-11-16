# general functions for network analysis ####

library(tidygraph)
#library(widyr)

# create an undirected tbl_graph using person id as node id ####
# n = nodes list, e = edges list. need to be in the right sort of format! 
bn_tbl_graph <- function(n, e){
  tbl_graph(
    nodes= n,
    edges= e,
    directed = FALSE,
    node_key = "person"
  )
}






## new function to dedup repeated pairs after doing joins
make_edge_ids <- function(data){
  data |>
  # make std edge1-edge2 ordering numerically. (don't really need names? that's nodes metadata too really)
  mutate(across(c(from, to), ~str_remove(., "Q"), .names="{.col}_n")) |>
  mutate(across(c(from_n, to_n), parse_number)) |>
  # standard from_to id according to which is lower number, for deduping repeated pairs
  mutate(edge_id = case_when(
    from_n<to_n ~ glue("{from}_{to}"),
    to_n<from_n ~ glue("{to}_{from}")
  )) |>
  mutate(edge1 = case_when(
    from_n<to_n ~ from,
    to_n<from_n ~ to
  )) |>
  mutate(edge2 = case_when(
    from_n<to_n ~ to,
    to_n<from_n ~ from
  )) |>
  select(-from_n, -to_n)
}




# network has to be a tbl_graph
# must have weight col, even if all the weights are 1.
# centrality scores: degree, betweenness, [closeness], harmony, eigenvector. 
bn_centrality <- function(network){
  network |>
    # tidygraph fixes renumbering for you... but you should keep bn ids anyway.
  filter(!node_is_isolated()) |>
  # doesn't use the weights column by default. 
    mutate(degree = centrality_degree(weights=weight),
           betweenness = centrality_betweenness(weights=weight), # number of shortest paths going through a node
           #closeness = centrality_closeness(weights=weight), # how many steps required to access every other node from a given node
           harmonic = centrality_harmonic(weights=weight), # variant of closeness for disconnected networks
           eigenvector = centrality_eigen(weights=weight) # how well connected to well-connected nodes
    )  |>
    # make rankings. wondering whether to use dense_rank which doesn't leave gaps.
    mutate(across(c(degree, betweenness, harmonic, eigenvector),  ~min_rank(desc(.)), .names = "{.col}_rank")) 
    # if you do closeness lower=more central so needs to be ranked the other way round from the rest !
    # mutate(across(c(closeness),  min_rank, .names = "{.col}_rank"))
}



# community detection
# doing unweighted; seemed to work better for events?
# run this *after* centrality function otherwise you might need isolated filter

bn_clusters <- function(network){
  network |>
    mutate(grp_edge_btwn = as.factor(group_edge_betweenness(directed=FALSE))) |>
    mutate(grp_infomap = as.factor(group_infomap())) |>  
    mutate(grp_leading_eigen = as.factor(group_leading_eigen())) |> 
    mutate(grp_louvain = as.factor(group_louvain())) 
}






## gender 
# list of all the named people (not just women) with gender  

# list of all the named people (not just women) with gender  
bn_gender_sparql <-
  'SELECT DISTINCT ?person ?personLabel ?genderLabel
WHERE {  
  ?person bnwdt:P12 bnwd:Q2137 .
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .} #filter out project team 
   optional { ?person bnwdt:P3 ?gender . } # a few without/uv, some named individuals
  SERVICE wikibase:label {bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en-gb,en".}
}
order by ?personLabel'

bn_gender_query <-
  bn_std_query(bn_gender_sparql) |>
  make_bn_ids(person) 

bn_gender <-
  bn_gender_query |>
# drop the not recorded, indecipherable, unnamed person kind of things.
  filter(!person %in% c("Q17", "Q2753", "Q576", "Q47") & personLabel !="??????????") |>
# make blank/uv gender "unknown" (only about a dozen, may well drop them.)
  mutate(genderLabel = case_when(
    is.na(genderLabel) | genderLabel=="" ~ "unknown",
    str_detect(genderLabel, "t\\d") ~ "unknown",
    .default = genderLabel
  )) |>
   # do slightly different gender column <uv> gender for excavations. tidy up later 
   mutate(gender = if_else(genderLabel %in% c("man", "woman"), genderLabel, NA))  |>
  rename(name = personLabel)





## this is not the all-the-dates query
bn_dates_sparql <-
'SELECT distinct ?person (year(?dod) as ?year_death) (year(?dob) as ?year_birth) ?s
  WHERE {
   ?person bnwdt:P12 bnwd:Q2137 . #humans
   FILTER NOT EXISTS { ?person bnwdt:P4 bnwd:Q12 . } # not project team
   
  optional { ?person bnwdt:P15 ?dod .   }
  optional { ?person bnwdt:P26 ?dob .   }
    
} # /where
ORDER BY ?person ?date'

bn_dates_query <-
  bn_std_query(bn_dates_sparql) |>
  make_bn_ids(c(person, s))  



bn_birth_dates <-
bn_dates_query |>
  filter(!is.na(year_birth)) |> 
  distinct(person, year_birth) |>
  group_by(person) |>
  arrange(year_birth, .by_group = T) |>
  top_n(-1, row_number()) |>
  ungroup() 

# dod seems fine on year, but should you assume it'll stay that way?
bn_death_dates <-
bn_dates_query |>
  filter(!is.na(year_death)) |>
  distinct(person, year_death)|>
  group_by(person) |>
  arrange(year_death, .by_group = T) |>
  top_n(-1, row_number()) |>
  ungroup() 



bn_person_list <-
bn_gender |>
  left_join(bn_birth_dates, by="person") |>
  left_join(bn_death_dates, by="person")



## network specific from here


# query adds make_date_year. otherwise the same apart from name changes. i should change mutate across anyway!
# needs to start with everyone, not just women!

bn_interactions_sparql <-
'select distinct ?personLabel ?propLabel ?qual_propLabel ?interactionLabel ?valueLabel ?qual_date ?person ?interaction ?prop ?qual_prop ?value
?s
where
{
  ?person  bnwdt:P12 bnwd:Q2137. 
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .}  
  
  ?person ?p ?s .
     ?prop wikibase:claim ?p .
     ?prop wikibase:statementProperty ?ps.
  {
      ?s ?ps ?interaction.
      ?interaction bnwdt:P12 bnwd:Q2137.
  }
    union
  {
     ?s ?ps ?value .
     ?s ?qual_p ?interaction .   
     ?qual_prop wikibase:qualifier ?qual_p. 
        ?interaction bnwdt:P12 bnwd:Q2137 .
        FILTER NOT EXISTS {?interaction bnwdt:P4 bnwd:Q12 .} 
      # filter not exists { ?interaction bnwdt:P2753 ?spouse .} # doesnt seem to work, also dont know why.
  }
    
    optional {
      ?s ( bnpq:P1 | bnpq:P27 ) ?qual_date
    }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". }
}
ORDER BY ?personLabel'



bn_interactions_query <-
  bn_std_query(bn_interactions_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(interaction, prop, qual_prop, value, s)) |>
  mutate(across(c(qual_date, qual_propLabel, qual_prop, value, valueLabel), ~na_if(., ""))) |>
  select(-person)



# drop stuff you don't want
bn_interactions_filtered <-
  bn_interactions_query |>
  # P20 evidence (raised a question). P91 specific reference information; think the latter are gone now but keep this anyway.
  filter(!qual_prop %in% c("P91", "P20") | is.na(qual_prop)) |>
  # p152/151 may be same as/different from. 
  # p36/37 excavations which will be done separately
  # elections to be done separately
  filter(!prop %in% c("P152", "P151", "P36", "P37", "P7", "P16", "P49", "P155")) |>
  # not named people
  filter(!interaction %in% c("Q2753", "Q17", "Q1587", "Q47")) |>
  # not a self join (!) (shouldn't really happen here, nevermind)
  filter(bn_id != interaction)

# drop all the spouses
bn_interactions_ex_spouses <-
  bn_interactions_filtered |>
  filter(!str_detect(propLabel, "married|spouse"))

# spouses only. dedup married in/named spouse to one row per spouse per person
bn_spouses_deduped <-
bn_interactions_filtered |>
  filter(str_detect(propLabel, "married|spouse"))|>
  group_by(bn_id, interaction) |>
  arrange(propLabel, .by_group = T) |>
  top_n(1, row_number()) |>
  ungroup()


# put the two sets back together
bn_interactions_all <-
bind_rows(
  bn_interactions_ex_spouses,
  bn_spouses_deduped) |>
  arrange(personLabel)  |>
  mutate(interaction_type = case_when(
    !is.na(qual_propLabel) ~ qual_propLabel,
    .default = propLabel
  )) |>
  mutate(interaction_type_id = case_when(
    !is.na(qual_prop) ~ qual_prop,
    .default = prop
  )) |>
  mutate(interaction_prop = case_when(
    !is.na(qual_prop) ~ propLabel,
    .default = "main"
  )) |>
  mutate(date = case_when(
    str_detect(value, "T00:00:00Z") ~ value,
    .default = qual_date
  )) |>
  make_date_year() |>
  # sorted properties is not set up in OF. can you do without it?
  # left_join(
  #   bn_sorted_properties|>
  #     select(bn_prop_id, section), by=c("interaction_type_id"="bn_prop_id")) |>
  # mutate(section=case_when(
  #   interaction_type_id=="P126" ~ "Personal details", # reclassify P126 has personal connection to
  #   !is.na(section) ~ section,
  #   is.na(section) & interaction_type_id %in% c("P109", "P156", "P32", "P50", "P8", "P82") ~ "Public and Professional Activities",
  #   .default = section
  # )) |>
  # mutate(section = str_to_lower(section)) |>
  # relocate(interactionLabel, interaction, interaction_type, interaction_type_id, interaction_prop, section, date, year, .after = personLabel) |>
  relocate(interactionLabel, interaction, interaction_type, interaction_type_id, interaction_prop, date, year, .after = personLabel) |>
  rename(from=bn_id, to=interaction, from_name=personLabel, to_name=interactionLabel) |>
  # make std edge1-edge2 ordering numerically. (don't really need names? that's nodes metadata too really)
  make_edge_ids()

## initial simplifications
# drop exact date and keep year only; drop s
# keep one row for each pair per interaction type per year
# unlike elections you do want counts as weights for this one.

bn_interactions_pairs <-
  bn_interactions_all |>
  distinct(edge_id, edge1, edge2, interaction_type, interaction_type_id, year, interaction_prop) |>
  #distinct(edge_id, edge1, edge2, interaction_type, interaction_type_id, section, year, interaction_prop) |>
# ignoring interaction types entirely...
  group_by(edge1, edge2) |>
  summarise(weight=n(), edge_start_year=min(year), edge_end_year=max(year), .groups = "drop_last") |>
  ungroup() 




# this is nodes metadata, don't do it here?
# use inner join for gender. then you drop any unnamed persons if you haven't already.
#  inner_join(bn_gender |> select(from=person, from_gender=genderLabel), by="from") |>
#  inner_join(bn_gender |> select(to=person, to_gender=genderLabel), by="to")


## pairs, sep elections and others.

# node info: name, gender
# edge info: from-to, interaction type, section, date/year



bn_interactions_nodes <-
bn_interactions_pairs |>
  pivot_longer(edge1:edge2, values_to = "person") |>
  distinct(person) |>
  inner_join(bn_person_list, by="person")


bn_interactions_edges <-
bn_interactions_pairs |>
  mutate(from=edge1, to=edge2) |>
  relocate(from, to)


bn_interactions_network <-
  bn_tbl_graph(bn_interactions_nodes, bn_interactions_edges)  |>
	#filter(!node_is_isolated()) |> # not needed if using bn_centrality
  bn_centrality() |>
  bn_clusters()



# version uisng names instead of numerical ids, like the miserables example

bn_interactions_nodes_d3 <-
bn_interactions_network |>
  as_tibble() |>
  select(id=name, person, gender, year_birth, year_death,degree, betweenness, eigenvector, harmonic, ends_with("_rank"), starts_with("grp")) |>
  # make a slighlty artificial group for testing filtering, if you ever get that far
  mutate(group = case_when(
    degree >8 ~ "group1",
  	degree >3 ~ "group2",
  	degree >1 ~ "group3",
  	.default = "group4"
  )) |>
  mutate(
    name_label = if_else(degree>3, id, ""), 
  	full_name=id) |>
  arrange(id)



bn_interactions_edges_d3 <-
bn_interactions_network |>
  activate(edges) |>
  as_tibble() |>
  select(from=edge1, to=edge2, weight, edge_start_year, edge_end_year) |>
  left_join(bn_interactions_nodes_d3 |> distinct(source=id, from=person), by="from") |>
  left_join(bn_interactions_nodes_d3 |> distinct(target=id, to=person), by="to") |>
  relocate(source, target, from, to)

  
# put in named list ready to write_json  
bn_interactions_json <-
list(
     nodes= bn_interactions_nodes_d3,
     links= bn_interactions_edges_d3
     )    


  
  
  