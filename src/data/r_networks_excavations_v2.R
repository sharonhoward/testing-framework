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





## general data for list of people for nodes data. - gender, birth and death., could add other stuff.


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





## from here network specific


## temporary dates from descriptions
## for convenience make eg "1930s" first half of decade "1930-1935" (really only using start dates and broad periods so it's not a big deal)
bn_excavations_circa_dates <-
  tribble(
    ~id , ~circa_dates, ~circa_year1, ~circa_year2,
    "Q3200" , "1937-39" , 1937, 1939,
    "Q3893" , "1932", 1932, 1932,
    "Q1631" , "early 20th century", 1900, 1905,
    "Q2589" , "1930s", 1930, 1935,
    "Q3729" , "1950", 1950, 1950,
    "Q3125" , "1948-51", 1948, 1951,
    "Q3727" , "1920s/30s", 1920, 1935,
    "Q3334" , "1930s", 1930, 1935,
    "Q3343" , "1920s", 1920, 1925,
    "Q2026" , "1930s" , 1930, 1935,
    "Q3175" , "1929-34", 1929, 1934,
    "Q2516" , "1920s", 1920, 1925,
    "Q3726" , "1920s", 1920, 1925
    #"Q4386", "1911-12", 1911, 1912
  ) 

# separate queries for persons and excavations initially
# three lots of info
# a) excavation>excavation 
# b) excavation>participants  - "participants" = directors and members only
# c) person>excavation participation


## gender query dropped


## excavation ####

bn_excavations_main_sparql <-
  'SELECT ?excavation ?excavationLabel ?propLabel ?valueLabel ?value  ?prop  ?s 

WHERE {  
   # instance of excavation  (128)
   ?excavation bnwdt:P12 bnwd:Q38 .
  
    ?excavation ?p ?s .
  
      ?prop wikibase:claim ?p .
      ?prop wikibase:statementProperty ?ps .
  
   optional { ?s ?ps ?value . } # need optional to keep a <uv> member.

  
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}'

bn_excavations_main_query <-
  bn_std_query(bn_excavations_main_sparql) |>
  make_bn_ids(c(excavation, prop, value, s)) |>
  mutate(across(c(valueLabel, value), ~na_if(., ""))) |>
  arrange(excavationLabel, propLabel) |>
  # filter out 1960 excavation
  filter(excavation !="Q3372")



## excavation>participants  ####

## all directors and members in excavation pages; drop a few duplicate rows 
## this should now be complete except for omitting a few people in marginal "excavations" and some "members" who are also directors.

bn_excavations_participants <-
  bn_excavations_main_query |>
  filter(prop %in% c("P36", "P37"))  |>
  # a few <uv> which seem to be unnamed groups; turn into NA
  mutate(across(c(value, valueLabel) , ~if_else(str_detect(., "^(_:)?t\\d+$"), NA, . ) )) |>
  ## give unnamed people unique IDs
  mutate(person_rn = if_else(value=="Q576", paste(value, row_number(), sep="_"), value)) |>
  ## CHANGE. there is only one named person with unknown gender. just drop them all
  ## do i need gender again before the nodes list? could just use semi join if not.
  semi_join(bn_gender |> select(person, gender), by=c("value"= "person")) |>
  select(excavation, excavationLabel, person=value, personLabel=valueLabel, roleLabel= propLabel, role= prop, person_rn, s) |>
  # drop a couple of dups
  group_by(person_rn, role, excavation) |>
  top_n(1, row_number()) |>
  ungroup() 




bn_excavations_qual_sparql <-
  'SELECT ?excavation ?excavationLabel ?prop ?propLabel  ?qual_propLabel ?qual_valueLabel  ?qual_value ?qual_prop ?s
  WHERE {  
   ?excavation bnwdt:P12 bnwd:Q38 .
   ?excavation ?p ?s .
        ?prop wikibase:claim ?p .
    ?s ?qual_p ?qual_value .
        ?qual_prop wikibase:qualifier ?qual_p
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}'

bn_excavations_qual_query <-
  bn_std_query(bn_excavations_qual_sparql) |>
  make_bn_ids(c(excavation, prop, qual_prop, s))|>
  # filter out 1960 excavation
  filter(excavation !="Q3372")


## excavation>excavation dates in instance of ####

bn_excavations_excavation_dates <-
  bind_rows(
    # qualifier dates
    bn_excavations_qual_query |>
      # keep qual dates that *aren't* directors/members (participants) - funders, organised by etc
      filter(qual_prop %in% c("P1", "P27", "P28") & !prop %in% c("P36", "P37") ) |> 
      # only keep qual dates that are i/o dates
      #filter(qual_prop %in% c("P1", "P27", "P28") & prop=="P12") |> # i/o qual dates
      mutate(date = parse_date_time(qual_value, "ymdHMS")) |>
      mutate(year = year(date)) |>
      select(excavation, excavationLabel, propLabel, prop, year, date_type= qual_propLabel, s) ,
    
    # main dates
    bn_excavations_main_query |>
      filter(prop %in% c("P1", "P27", "P28")) |> # dont bother with earliest/latest
      mutate(date = parse_date_time(value, "ymdHMS")) |>
      mutate(year = year(date))   |>
      mutate(date_type = propLabel) |>
      select(excavation, excavationLabel, propLabel, prop, year, date_type, s) 
  ) |>
  arrange(excavation, year, date_type) 

# excavation>participants dates in qualifiers. 

bn_excavations_participants_qual_dates <-
  bn_excavations_qual_query |>
  # keep only qual dates for dir/mem.
  filter(qual_prop %in% c("P1", "P27", "P28") & prop %in% c("P36", "P37") ) |> 
  #filter(qual_prop %in% c("P1", "P27", "P28") & prop!="P12") |> # exclude i/o dates
  mutate(date = parse_date_time(qual_value, "ymdHMS")) |>
  mutate(year = year(date))  |>
  # add person IDs (and remove the dups as well)
  inner_join(bn_excavations_participants |> select(s, person), by="s")  |>
  select(excavation, excavationLabel, person, propLabel, prop, year, date_type= qual_propLabel, s) |>
  arrange(excavationLabel, year) 





## person>excavation participation ####

# simplify, don't need details. but still want dates because some are going missing in dates_all
bn_people_excavations_sparql <-
  'SELECT distinct ?person ?personLabel ?excavation ?role ?date ?date_propLabel ?s 

WHERE {  
   # people only. 
   ?person bnwdt:P12 bnwd:Q2137 .
     ?person (bnp:P36 | bnp:P37) ?s .
       ?s (bnps:P36|bnps:P37) ?excavation .
       ?s ?role ?excavation . # only two roles so dont bother with labels
  ?excavation bnwdt:P12 bnwd:Q38. # just get i/o excavation
     optional {
       ?s (bnpq:P1 | bnpq:P27 | bnpq:P28 ) ?date.
       ?s ?pq ?date .
         ?date_prop wikibase:qualifier ?pq .
       }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}'

bn_people_excavations_query <-
  bn_std_query(bn_people_excavations_sparql) |>
  make_bn_ids(c(person, excavation, role, s))|>
  # filter out 1960 excavation
  filter(excavation !="Q3372") |>
  mutate(roleLabel = if_else(role=="P36", "director of archaeological fieldwork", "member of excavation during archaeological fieldwork")) |>
  mutate(across(c(date_propLabel, date), ~na_if(., ""))) |>
  # add gender CHANGED to smi join.
  semi_join(bn_gender |> select(person, gender), by="person") |>
  #relocate(person, .after = last_col()) |>
  arrange(person, excavation)


bn_people_excavations_dates <-
  bn_people_excavations_query |>
  make_date_year() |>
  select(person, date, year, date_type=date_propLabel, excavation, role, s)



## excavation covering dates summaries ####

# separate out people/participants' dates from other dates; make lists of all dates as well as earliest/latest years

# update: include temporary circa dates . 
bn_excavations_excavations_with_circa_dates <-
  bn_excavations_excavation_dates |>
  bind_rows(
    # circa dates need pivot
    bn_excavations_circa_dates |>
      rename(excavation=id) |>
      pivot_longer(circa_year1:circa_year2, names_to = "date_type", values_to = "year")
  ) 

# summarised version; probably won't need this
bn_excavations_excavations_covering_dates <-
  bn_excavations_excavations_with_circa_dates |>
  group_by(excavation) |>
  arrange(year, .by_group = T) |>
  summarise(years = paste(unique(year), collapse = " "), year1 = min(year), year2 = max(year)) |>
  ungroup()


# participants is p36/p37 only so you'll need to get the other qual dates as well
# not keeping role; would need a tweak if you change current one person per excavation approach 
# is this dates before reducing roles? think so. that's ok isn't it?
bn_excavations_participants_covering_dates <-
  bn_excavations_participants_qual_dates|>
  group_by(person, excavation)  |>
  arrange(year, .by_group = T) |>
  summarise(years = paste(unique(year), collapse = " "), year1 = min(year), year2 = max(year), .groups = "drop_last") |>
  ungroup()


# again not including role. before reduction of roles; would need a tweak if you change that
bn_people_excavations_covering_dates <-
  bn_people_excavations_dates |>
  group_by(person, excavation) |>
  summarise(years = paste(unique(year), collapse = " "), year1 = min(year), year2 = max(year) , .groups = "drop_last") |>
  ungroup()


# merged covering dates for people and participants; should represent every date associated with a member/director on an excavation. 
# focusing on excavation dates overall, probably don't need this
bn_excavations_people_participants_covering_dates <-
  bind_rows(
    bn_excavations_participants_qual_dates,
    bn_people_excavations_dates
  ) |>
  filter(!is.na(year)) |>
  group_by(person, excavation) |>
  summarise(p_years = paste(unique(year), collapse = " "), p_year1 = min(year), p_year2 = max(year) , .groups = "drop_last") |>
  ungroup()


# merge ALL dates from all sources into covering dates which represent every date associated with an excavation
# use excavations with circa dates 
bn_excavations_all_covering_dates <-
  bind_rows(bn_excavations_participants_qual_dates, 
            bn_excavations_excavations_with_circa_dates,
            bn_people_excavations_dates
  ) |>
  filter(!is.na(year)) |> # in case.
  group_by(excavation) |>
  arrange(year, .by_group = T) |>
  summarise(e_years = paste(unique(year), collapse = " "), year1 = min(year), year2 = max(year)) |>
  ungroup()



# a base for excavations with dates?
# one row per excavation
# but omits a number of "excavations" on person pages. i think they're some scrappy things. so probably need to avoid this for people-y analysis or as a starting point for anything
# bn_excavations <-
# bn_excavations_main_query |>
#   distinct(excavation, excavationLabel) |>
#   left_join(bn_excavations_all_covering_dates, by="excavation")




## (was bring all participants together from excavation and person src)
bn_excavations_people_participants_all <-
#  bind_rows(
    bn_excavations_participants |> 
      # exclude NA person
      filter(!is.na(person)) |> 
#      mutate(ex_io="Q38", ex_ioLabel="excavation", src="ex"),
#    bn_people_excavations |> 
#      mutate(person_rn=person, src="ppl") 
#  )  |>
  arrange(person, role, excavation) |> 
  mutate(role_short = word(roleLabel)) |>
  # just use e dates
  #left_join(bn_excavations_people_participants_covering_dates, by=c("person", "excavation")) |>
  left_join(bn_excavations_all_covering_dates, by="excavation")  

## dedup and reduce: **if someone has both director and member role on the same excavation, keep dir only.**
# you need individual dates as well as excavation dates
bn_excavations_people_participants <-
  bn_excavations_people_participants_all |>
  # hmm, some have both roles but not in the same src. seems tricky to do in one step.....
  group_by(person, excavation) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  # drop use of person_rn, since you already got rid of those. drop gender
  #  distinct(person, personLabel, excavation, excavationLabel, gender, person_rn, role, role_short, p_year1, p_year2, p_years, e_year1, e_year2, e_years) |> original with p years
  distinct(person, personLabel, excavation, excavationLabel, role, role_short, year1, year2, e_years) |>  
  # finish off in 2nd step. can probably do better... 
  group_by(person, excavation) |>
  top_n(-1, row_number()) |>
  ungroup() |>
  arrange(person, excavation)

# count of named people per excavation
bn_excavations_named_person_n <-
  bn_excavations_people_participants |>
  # shouldn't need these filters now shurely?
  filter(person != "Q576") |>
#  filter(person != "Q576" & !is.na(gender))|>
  # any specific individuals to remove. Q3388 = Grace Simpson, 1960s.
  filter(!person %in% c("Q3388"))  |>
  count(excavation, name="excavation_n")


# covering dates *per person* for nodes list
bn_excavations_people_participants_dates_summary <-
  bn_excavations_people_participants |>
  #select(person, p_year1, p_year2, e_year1, e_year2) |>
  select(person, year1, year2) |>
  # drop unnamed
  filter(person !="Q576") |>
  # pivot longer for excavation years then get min/max overall
  #pivot_longer(p_year1:circa_year2) |>
  pivot_longer(-person) |>
  filter(!is.na(value)) |>
  group_by(person) |>
  arrange(value, .by_group = TRUE) |>
  #summarise(year1=min(value), year2=max(value), years=paste(unique(value), collapse = " ")) |>
  summarise(year1=min(value), year2=max(value) )|>
  ungroup()

# 8 rows less than original. not enough to worry about!
# named and gendered individuals only, mainly for network analysis
# also drop Q3388 Grace Simpson as out of scope
bn_excavations_people_participants_named <-
  bn_excavations_people_participants |>
  select(-role) |>
  #  select(person, personLabel, excavation, excavationLabel, gender, role_short, year1, year2, years) |>
  # unnamed
  filter(person !="Q576") |>
  # any specific individuals to remove
  filter(!person %in% c("Q3388")) |>
  # don't need this?
  # all but one named individual have gender, so drop that person from named as well 
  # filter(!is.na(gender)) |>
  # add count of named people for the excavation
  left_join(bn_excavations_named_person_n, by="excavation")  |>
  # add person's number of excavations
  add_count(person, name="p_n_excavations") |>
  # for now use e start year [including circa].
  # year1 and year2 should be for specific excavation, need to be renamed
  rename(e_year1=year1, e_year2=year2) |>
  # add per person covering years.
  left_join(bn_excavations_people_participants_dates_summary, by="person") |>
  # period based on covering dates for excavations
  mutate(p = case_when(
    e_year1 < 1918 ~ "1900",
    e_year1 < 1930 ~ "1920",
    e_year1 <=1940 ~ "1930",
    e_year1 > 1940 ~ "1950"
  )) 
#only 15 rows without any date.


# do you still need all the queries?
# a handful of people in persons but not excavations but it's because their "excavations" aren't i/o excavation. they're completely isolated.
# the only non-joins participants>persons are NAs.
# diffs in role? afaics would only lose some member roles and keep the directors, and it's only 3 or 4 people. 
# BUT there still gaps in dates. so do a simplified people query to get those.
# some dates seem to go missing from dates_all, idk why.
# but have changed gender joins to inner to keep only named and gendered individuals from the start.



#make this the simplest thing, no roles, no years.

bn_excavations_pairs <-
bn_excavations_people_participants_named   |>
  distinct(from=person, from_name=personLabel, excavation, e_year1, e_year2) |>
  inner_join(bn_excavations_people_participants_named |>
               distinct(to=person, to_name=personLabel, excavation), by="excavation", relationship = "many-to-many") |>
  filter(from!=to) |>
  relocate(to, to_name, .after = from_name)  |>
  arrange(from_name, to_name) |>
  make_edge_ids()  



bn_excavations_edges <-
bn_excavations_pairs |>
  distinct(edge_id, edge1, edge2, excavation, e_year1, e_year2) |> # 
  group_by(edge1, edge2) |>
  summarise(weight=n(), edge_start_year=min(e_year1), edge_end_year=max(e_year2), .groups = "drop_last") |>
  ungroup() |>
  mutate(from=edge1, to=edge2) |>
  relocate(from, to)

bn_excavations_nodes <-
bn_excavations_edges  |>
  pivot_longer(from:to, values_to = "person") |>
  distinct(person) |>
  inner_join(bn_person_list, by="person")


bn_excavations_network <-
  bn_tbl_graph(bn_excavations_nodes, bn_excavations_edges) |>
  #filter(!node_is_isolated()) |> not needed if using bn_centrality
  bn_centrality() |>
  bn_clusters()





# version uisng names instead of numerical ids, like the miserables example 

bn_excavations_nodes_d3 <-
bn_excavations_network |>
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


bn_excavations_edges_d3 <-
bn_excavations_network |>
  activate(edges) |>
  as_tibble() |>
  select(from=edge1, to=edge2, weight, edge_start_year, edge_end_year) |>
  left_join(bn_excavations_nodes_d3 |> distinct(source=id, from=person), by="from") |>
  left_join(bn_excavations_nodes_d3 |> distinct(target=id, to=person), by="to") |>
  relocate(source, target, from, to)
  
  
# put in named list ready to write_json  
bn_excavations_json <-
list(
     nodes= bn_excavations_nodes_d3,
     links= bn_excavations_edges_d3
     )    

