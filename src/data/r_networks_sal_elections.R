# general functions for network analysis ####

library(tidygraph)
#library(ggraph)
#library(widyr)
#library(networkD3)


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





bn_elections_sparql <-
  'select distinct ?personLabel ?proposerLabel ?qual_propLabel ?interactionLabel ?date ?person ?prop ?proposer ?qual_prop ?interaction ?s

where
{
  ?person bnwdt:P3 bnwd:Q3 .
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .}  
  
  # proposed: sal p16 , rai p7, rhs p155.
  ?person ( bnp:P16 | bnp:P7 | bnp:P155 ) ?s .
     ?s (bnps:P16 | bnps:P7 | bnps:P155 ) ?proposer .
     ?s ?prop ?proposer .
     
  optional {
  # will this just be supporters? if so should probabl get them explicitly
     ?s ?qual_p ?interaction .   
     ?qual_prop wikibase:qualifier ?qual_p. 
        ?interaction bnwdt:P12 bnwd:Q2137 .
        FILTER NOT EXISTS {?interaction bnwdt:P4 bnwd:Q12 .} 
  } 
  
    optional {
      ?s bnpq:P1 ?date
      }
  
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". }
}
ORDER BY ?personLabel'


bn_elections_query <-
  bn_std_query(bn_elections_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(proposer, interaction, qual_prop, prop, s)) |>
  mutate(across(c(qual_prop, qual_propLabel, prop, interaction, interactionLabel), ~na_if(., ""))) |>
  make_date_year() |>
  select(-person)



bn_sal_proposers <-
bn_elections_query |>
  filter(prop=="P16") |> 
  distinct(bn_id, personLabel, supporterLabel= proposerLabel, supporter= proposer, date, year, prop, s) |>
  #keep only known gender.
  semi_join(bn_gender, by=c("supporter"="person"))

bn_sal_signers <-
bn_elections_query |>
  filter(prop=="P16" & qual_prop=="P32") |>
  distinct(bn_id, personLabel, supporterLabel= interactionLabel, supporter= interaction, date, year, prop=qual_prop, s) |>
  # not named people
  filter(!supporter %in% c("Q2753", "Q17", "Q1587", "Q47")) |>
  semi_join(bn_gender, by=c("supporter"="person"))


# fsa and supporters per election
bn_sal_supporters_elections <-
  bind_rows(
    bn_sal_proposers,
    bn_sal_signers
  ) |>
  mutate(support= if_else(prop=="P16", "proposer", "signer")) |>
  rename(support_id=prop)



#this still seems a bit weird.
bn_sal_election_edges <-
bn_sal_supporters_elections |>
  distinct(from=bn_id, to=supporter, year) |>
  group_by(from, to) |>
  # year of election. max for the handful who tried twice. ignore the odd fail.
  summarise(fsa_year = max(year), .groups = "drop_last") |>
  ungroup() |>
  # naming to match other networks.
  mutate(edge1 = from, edge2 = to) |>
  mutate(weight=1) # is this right htough


bn_sal_election_nodes <-
bn_sal_election_edges |>
  pivot_longer(from:to, values_to = "person") |>
  distinct(person) |>
  inner_join(bn_person_list, by="person")


bn_sal_election_network <-
bn_tbl_graph(bn_sal_election_nodes, bn_sal_election_edges) |>
	#filter(!node_is_isolated()) |> # not needed if using bn_centrality
  bn_centrality() |>
  bn_clusters()

# is it worth doing a count of support actions/events? (n_event in events network)
# apparently no isolated nodes... but therell be plenty with only one link.



# version uisng names instead of numerical ids, like the miserables example
# will this break now... removing id_no=id, 

bn_sal_nodes_d3 <-
bn_sal_election_network |>
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



bn_sal_edges_d3 <-
bn_sal_election_network |>
  activate(edges) |>
  as_tibble() |>
  select(from=edge1, to=edge2, weight, fsa_year) |>
  left_join(bn_sal_nodes_d3 |> distinct(source=id, from=person), by="from") |>
  left_join(bn_sal_nodes_d3 |> distinct(target=id, to=person), by="to") |>
  relocate(source, target, from, to)

  
# put in named list ready to write_json  
bn_sal_elections_json <-
list(
     nodes= bn_sal_nodes_d3,
     links= bn_sal_edges_d3
     )    

