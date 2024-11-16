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








# organised by (P109): union query for linked event pages or in quals, excluding human organisers. atm all are items.
# slightly trimmed version to speed up query as you don't need claim . don't even really need ?person.

bn_organised_by_sparql <-
'SELECT distinct 
?s ?organised_by ?organised_byLabel 
#?person ?prop ?ev 

WHERE {  
  ?person bnwdt:P3 bnwd:Q3 .
  ?person ( bnp:P71 | bnp:P24 | bnp:P72 | bnp:P23 | bnp:P13 | bnp:P120 | bnp:P113 ) ?s .
    ?s ( bnps:P71 | bnps:P24 | bnps:P72 | bnps:P23 | bnps:P13 | bnps:P120 | bnps:P113 ) ?ev .  
   
  # ?person ?p ?s .
  #     ?prop wikibase:claim ?p;      
  #        wikibase:statementProperty ?ps.  

  # organised by  
  {
    # in linked event page
   ?ev bnwdt:P109 ?organised_by .  
  }
  union
  {
    # in qualifier
     ?s bnpq:P109 ?organised_by . 
    }
  
  # exclude human organisers... P12 Q2137
       filter not exists { ?organised_by bnwdt:P12 bnwd:Q2137 . }
        
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}'


bn_organised_by_query <-
  bn_std_query(bn_organised_by_sparql) |>
  #make_bn_item_id(person) |>
  make_bn_ids(c(organised_by, s)) 


bn_women_events_sparql <-
  'SELECT distinct ?person ?personLabel ?propLabel ?ppaLabel  ?qual_propLabel ?qual_valueLabel ?qual_value ?prop ?ppa ?qual_prop
?s

WHERE {  
  ?person bnwdt:P3 bnwd:Q3 .
  ?person ( bnp:P71 | bnp:P24 | bnp:P72 | bnp:P23 | bnp:P13 | bnp:P120 | bnp:P113 ) ?s .
    ?s ( bnps:P71 | bnps:P24 | bnps:P72 | bnps:P23 | bnps:P13 | bnps:P120 | bnps:P113 ) ?ppa .  
   
  ?person ?p ?s .
      ?prop wikibase:claim ?p.      
          
  # qualifiers
   optional { 
     ?s ( bnpq:P78|bnpq:P66 | bnpq:P2	 ) ?qual_value . # limit to the qualifiers youre actually using
     ?s ?qual_p ?qual_value .   
     ?qual_prop wikibase:qualifier ?qual_p . 
    }
        
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}

order by ?personLabel '


bn_events_fetched <-
  bn_std_query(bn_women_events_sparql)
  

# process the data a bit
bn_women_events_query <-
  bn_events_fetched |>
  make_bn_item_id(person) |>
  make_bn_ids(c(ppa, s, qual_value, prop, qual_prop)) |>
  mutate(across(c(qual_value, qual_valueLabel, qual_prop, qual_propLabel), ~na_if(., ""))) |>
  relocate(person, .after = last_col()) |>
  arrange(bn_id, s)



#  main only
# bn_women_ppa_events <-
bn_women_events <-
bn_women_events_query |>
  distinct(bn_id, personLabel, propLabel, ppaLabel, prop, ppa, s) |>
  left_join(bn_women_dob_dod |> select(bn_id, yob=bn_dob_yr, dob=bn_dob), by="bn_id") |>
  left_join(bn_organised_by_query |> 
              # just in case you get another with multiple organisers
              group_by(s) |>
              top_n(1, row_number()) |>
              ungroup() |>
              select(s, organised_by, organised_byLabel), by="s") |>
  #renaming to match original
  rename(event=ppaLabel, event_id=ppa) |>
  rename(ppa=prop, ppa_label=propLabel) |>
  relocate(ppa, .after = ppa_label) |>
  relocate(s, .after = last_col())


# bn_women_ppa_events_qualifiers <-
bn_women_events_qualifiers <-
bn_women_events_query |>
  #renaming to match original
  rename(event=ppaLabel, event_id=ppa) |>
  rename(ppa=prop, ppa_label=propLabel) |>
  rename(qual_label = qual_propLabel, qual_p=qual_prop) |>
  relocate(ppa, .after = ppa_label) |>
  relocate(event_id, .after = event)


# get instance of for qualifiers
# i think it's better to get them separately esp as there are multis etc
# problems adapting the query for events only... just get all for ppa for now and get moving
# it's not that slow; maybe come back to it
# but i think you may need to work it out so you can narrow down? for now do a semi join afterwards

bn_women_ppa_qual_inst_sparql <-
  'SELECT distinct ?person ?ppa ?qual ?qual_instance ?qual_instanceLabel  ?s
WHERE {  
  ?person bnwdt:P3 bnwd:Q3 .
  ?person ?p ?s .  
 
      ?ppa wikibase:claim ?p;      
         wikibase:statementProperty ?ps.       
      ?ppa bnwdt:P12 bnwd:Q151 . # i/o ppa      
 
      # get stuff about ?s 
      ?s ?ps ?qual.
  
      # get instance of for qual
        ?qual bnwdt:P12 ?qual_instance .

  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}
order by ?s'

bn_women_ppa_qual_inst_query <-
  bn_std_query(bn_women_ppa_qual_inst_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(ppa, qual, qual_instance, s)) |>
  select(-person) |>
  semi_join(bn_women_events, by="s")


# why precision?
# this is quite similar to qualifiers query in dates.r (though that's more general) - see if you can consolidate them later.
# fetching date_prop makes the query a *lot* slower, so get R to turn the prop IDs into labels instead.

bn_women_events_time_precision_sparql <-
'SELECT distinct ?person ?date ?date_precision ?pq ?pqv  ?s  ?ppa  
#?prop ?date_prop ?date_propLabel 

WHERE {  
  ?person bnwdt:P3 bnwd:Q3 .
  ?person ( bnp:P71 | bnp:P24 | bnp:P72 | bnp:P23 | bnp:P13 | bnp:P120 | bnp:P113 ) ?s .
    ?s ( bnps:P71 | bnps:P24 | bnps:P72 | bnps:P23 | bnps:P13 | bnps:P120 | bnps:P113 ) ?ppa .  
   
  # dont need any of this
  # ?person ?p ?s .
  #     ?prop wikibase:claim ?p;
  #        wikibase:statementProperty ?ps.      

  # qualifier timevalue and precision.
      ?s (bnpqv:P1 | bnpqv:P27 | bnpqv:P28 ) ?pqv.
      ?s ?pq ?pqv .
          ?pqv wikibase:timeValue ?date .  
          ?pqv wikibase:timePrecision ?date_precision .
     
  # this really slows down the query, just for the sake of the property labels. ?
  #      ?s ?pq ?date .   
  #        ?date_prop wikibase:qualifier ?pq .
  #        ?date_prop wikibase:propertyType wikibase:Time.  
  
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". } 
}
'



bn_events_time_precision_fetched <-
  bn_std_query(bn_women_events_time_precision_sparql)


bn_women_events_time_precision_query <-
  bn_events_time_precision_fetched |>
  make_bn_item_id(person) |>
  make_bn_ids(c(ppa, pq, pqv, s)) |>
  #make_bn_ids(c(prop, ppa, date_prop, pqv, s)) |>
  make_date_year() |>
  mutate(date_propLabel = case_when(
    pq=="P1" ~ "point in time",
    pq=="P27" ~ "start time",
    pq=="P28" ~ "end time"
  )) |>
  rename(date_prop=pq) |>
  select(-person)


bn_women_events_dates <-
  bn_women_events_time_precision_query |>
  # you need to keep the date as well as the precision when you pivot, to join. c() in values_from
  # start/end pivot to a single row
  filter(date_prop %in% c("P27", "P28")) |>
  pivot_wider(names_from = date_propLabel, values_from = c(date_precision, date), id_cols = s) |>
  clean_names("snake") |>
  rename(start_precision=date_precision_start_time, end_precision = date_precision_end_time) |>
  # then add p.i.t.
  bind_rows(
    bn_women_events_time_precision_query |>
      filter(date_prop %in% c("P1")) |>
      select(s, pit_precision=date_precision, date)
  ) |> 
  mutate(date = case_when(
    !is.na(date) ~ date,
    !is.na(date_start_time) ~ date_start_time
  )) |>
  mutate(date_precision = case_when(
    !is.na(pit_precision) ~ pit_precision,
    !is.na(start_precision) ~ start_precision
  )) |>
  mutate(year = year(date)) |>
  # drop extra stuff; you can always get it back if you need it right.
  select(s, date, date_precision, year)


# add a new step before of_dates for doing of_org combination
bn_women_events_of <-
bn_women_events |> 
  left_join(bn_women_events_qualifiers |>
              # of (item/free text)
              filter(qual_p %in% c("P78", "P66")) |>
              anti_join(bn_women_events |> filter(event_id=="Q3644"), by="s") |> # exclude CAS AGM of 
              distinct(s, qual_p, qual_label, qual_value, qual_valueLabel) |> # do i need distinct? possibly not.
              # ensure you have only 1 per stmt. these are all spoke_at; are they the ones with multiple papers?
              group_by(s) |>
              top_n(1, row_number()) |>
              ungroup() |>
              rename(of_label=qual_label, of=qual_p, of_id=qual_value, of_value=qual_valueLabel) 
              , by="s") |>
  # prefer of if you have both
  # i think organised_by is Items only, but use the id here just in case
  mutate(of_org = case_when(
    !is.na(of_value) ~ of_value,
    !is.na(organised_by) ~ organised_byLabel
  )) |>
  mutate(of_org_id = case_when(
    !is.na(of_id) ~ of_id,
    !is.na(organised_by) ~ organised_by
  )) 


# had manytomany warning. caused by multiple orgs in of. top_n as a quick hack to get rid. there are only a handful.
bn_women_events_of_dates <-
  bn_women_events_of |>
  left_join(bn_women_events_dates, by="s")  |>
  relocate(s, .after = last_col())



# before adding organised_by
# # watch out for manytomany warning. caused by multiple orgs in of. top_n as a quick hack to get rid. there are only a handful.
# bn_women_events_of_dates <-


bn_women_events_of_dates_types_all <-
bn_women_events_of_dates |>
  # add i/o that are generic event types meeting/conference/exhibition - shouldn't dup... if it does will need to turn this into a separate step
  left_join(
    bn_women_ppa_qual_inst_query |>
      filter(qual_instanceLabel %in% c("meeting", "conference", "exhibition")) |>
      distinct(qual, qual_instance, qual_instanceLabel) |>
      rename(instance_id=qual_instance, instance=qual_instanceLabel), by=c("event_id"="qual")
  ) |>
  # # add other i/o - started to dup. see how you get on without it.  mostly will be orgs....
  # left_join(
  #   bn_women_ppa_qual_inst_query |>
  #     filter(!qual_instanceLabel %in% c("meeting", "conference", "exhibition", "event", "bucket", "locality", "venue")) |>
  #     distinct(qual, qual_instance, qual_instanceLabel) |>
  #     rename(instance2_id=qual_instance, instance2=qual_instanceLabel), by=c("event_id"="qual")
  # )  |>
  # add directly available locations
  left_join(
    bn_women_events_qualifiers |>
      filter(qual_label=="location") |>
      group_by(s) |>
      top_n(1, row_number()) |>
      ungroup() |>
      select(s, qual_location=qual_valueLabel, qual_location_value=qual_value)
  , by="s") |>
  
  # consolidate ppa_label item/text. currently only for delegate
  mutate(ppa_type = case_when(
    str_detect(ppa_label, "was delegate") ~ "was delegate at",
    .default = ppa_label
  )) |>
  relocate(ppa_type, .after = ppa)  |>
  
  # make event type. adjusted to do more as you dropped second i/o join. tweak for F.S.
  mutate(event_type = case_when(
    event %in% c("meeting", "exhibition", "conference") ~ event,
    event_id=="Q292" & is.na(of_org) ~ "meeting",  # folklore society not specified as meetings, but they almost certainly are
    #event_id=="Q682" ~ "conference", # Annual Meeting as conference? - to work this has to go before instance
    instance %in% c("meeting", "exhibition", "conference") ~ instance,
    event %in% c("committee", "museum") ~ "other",
    str_detect(event, "Meeting|Congress of the Congress of Archaeological Societies") ~ "meeting",
    str_detect(event, "Conference|Congress") | str_detect(of_org, "Conference|Congress") ~ "conference",
    #str_detect(instance2, "society|organisation|museum|institution|library") ~ "other",
    str_detect(of_org, "Society|Museum|Library|Institut|Association|School|College|Academy|University|Club|Gallery|Committee") | str_detect(event, "Society|Museum|Museo|Library|Institut|Association|School|College|Academy|University|Club|Gallery|Committee") ~ "other",
    .default = "misc"
  )) |>
  
    mutate(event_org = case_when(
    !is.na(of_org) ~ of_org,
    event_id=="Q292" & is.na(of_org) ~ event,
    event_type=="other" ~ event,
    str_detect(event, "Royal Archaeological Institute|\\bRAI\\b") ~ "Royal Archaeological Institute", 
    str_detect(event, "Society of Antiquaries of London|\\bSAL\\b") ~ "Society of Antiquaries of London",
    str_detect(event, "Congress of Archaeological Societies|\\bCAS\\b") ~ "Congress of Archaeological Societies",
    str_detect(event, "Royal Academy") ~ "Royal Academy",
    str_detect(event, "Society of Lady Artists") ~ "Society of Women Artists", 
    str_detect(event, "Folklore Society") ~ "The Folklore Society",
    # i think use event name for conferences/exhibitions without an of. but not generic
    event_type %in% c("conference", "exhibition", "misc")  & !event %in% c("meeting", "exhibition", "event", "petition", "conference")  ~ event
  )) |>

  # need an org id as well as org name. not quite the same as of_org_id... probably
  mutate(org_id = case_when(
    !is.na(of_org_id) ~ of_org_id,
    event_id=="Q292" & is.na(of_org) ~ event_id,
    # need these IDs 
    str_detect(event, "Royal Archaeological Institute|\\bRAI\\b") ~ "Q35", 
    str_detect(event, "Society of Antiquaries of London|\\bSAL\\b") ~ "Q8",
    str_detect(event, "Congress of Archaeological Societies|\\bCAS\\b") ~ "Q186", 
    str_detect(event, "Royal Academy") ~ "Royal_Academy",
    str_detect(event, "Society of Lady Artists") ~ "Q1891", # probably don't need this now ?
    str_detect(event, "Folklore Society") ~ "Q292",
    !is.na(event_org) ~ event_id,
    # conferences etc without an of - use event_id. but not if generic
    event_type %in% c("conference", "exhibition", "misc") & !event %in% c("meeting", "exhibition", "event", "petition", "conference") ~ event_id
  )) |>
  
  # event title. still probably wip. this is now not going to exactly match grouping of instance id, i think.
  # adding organised by -> needs some sort of tweak
  mutate(event_title = case_when(
    # for FS. not sure if still needed...
    event_id=="Q292" & is.na(of_org) ~ paste("meeting,", event),
    #  use year if other info is lacking. either should match instance id without a problem 
    event %in% c("exhibition", "meeting", "event", "conference") & is.na(of_org) & !is.na(year) ~ paste0(event, " (", year, ")"),
    event_id %in% c("Q1918") ~ event,  # society of ladies exhibition- don't want organised by in title here.
    !event %in% c("meeting", "event", "conference") & !is.na(organised_by) ~ event,
    is.na(of_org) ~ event,
    event=="event" ~ of_org,
    .default = paste(event, of_org, sep=", ")
  )) |>
  # some abbreviations
  mutate(event_title = str_replace_all(event_title, sal_rai_cas_abbr))  |>

  # grouping date for distinct events according to type of event
  # do i need to check this again after adjusting event_type? 
  mutate(event_instance_date = case_when(
    is.na(date) ~ NA,
    event_id=="Q682" ~ paste0(year, "-01-01"),
    event_type %in% c("misc", "meeting", "other") ~ as.character(date), # should i make this month?
    event_type %in% c("conference", "exhibition") ~ paste0(year, "-01-01")
  ))  |>
  
# NB: there is no event_of_id now; event_org_id instead.
  # id columns for convenience
  # mutate(event_instance_id = paste(event_instance_date, event_id, of_id, sep="_"))  |>
  # mutate(event_of_id = paste(event_id, of_id, sep="_")) |>
  mutate(event_instance_id = paste(event_instance_date, org_id, event_type, sep="_"))  |>
  
  # hmm, this may not quite work. and might need a bit of extra work for CAS etc. 
  mutate(event_org_id = case_when(
    # if generic and no other info except date, add year to the id [as in event_title].
    event %in% c("exhibition", "meeting", "event", "conference", "Annual Meeting", "petition") & is.na(of_org) & !is.na(year) ~ paste(org_id, event_type, year, sep="_"),
    # otherwise exclude date info
    .default =  paste(org_id, event_type, sep="_"))
         
         ) |>
  relocate(event_title, event_type, year, event_instance_date, event_org, org_id, event_instance_id, event_org_id, of_org, of_org_id, .after = ppa_type) 
  
bn_women_events_of_dates_types <-
bn_women_events_of_dates_types_all |>
  # losing ppa_label, but keep ppa in case you need any joins. just bear in mind slight difference.
  # also dropping separate organised by and of cols.
  distinct(bn_id, personLabel, ppa_type, ppa, event_title, event_type, year, event_instance_date, event_org, org_id, event_instance_id, event_org_id, dob, yob)


# unique event instances based on the workings
# but this is probably not quite right because it includes too much stuff incl title in group by
bn_women_event_instances <-
bn_women_events_of_dates_types_all |>
  group_by(event_instance_id, event_org_id, event_title, event_type, event_org, event, of_org, event_id, of_org_id, event_instance_date, year) |>
  # get all unique dates listed for the event instance, in chronological order
  arrange(date, .by_group = T) |>
  summarise(dates_in_db = paste(unique(date), collapse = " | "), .groups = "drop_last") |>
  ungroup()



bn_events_dated_for_pairs <-
bn_women_events_of_dates_types_all |>
  filter(!is.na(org_id) & !str_detect(org_id, "_:t") & !is.na(year)) |>
  mutate(org_year = paste(org_id, year))  |>
  distinct(from=bn_id, from_name=personLabel, org_year, event_instance_id, ppa_type, year )

bn_events_dated_pairs <-
bn_events_dated_for_pairs  |>
  inner_join(bn_events_dated_for_pairs |>
               select(to=from, to_name=from_name, event_instance_id), by="event_instance_id", relationship = "many-to-many") |>
  filter(from!=to) |>
  relocate(to, to_name, .after = from_name) |>
  arrange(from_name, to_name) |>
  make_edge_ids()  


# what diff does ppa make? quite a bit. leave it out for now
#  distinct(edge_id, edge1, edge2, event_instance_id, ppa_type, year) # 646

bn_women_events_edges <-
bn_events_dated_pairs |>
  distinct(edge_id, edge1, edge2, event_instance_id, year) |> # 588
  group_by(edge1, edge2) |>
  summarise(weight=n(), edge_start_year=min(year), edge_end_year=max(year), .groups = "drop_last") |>
  ungroup() |>
  mutate(from=edge1, to=edge2) |>
  relocate(from, to)


# use edges list to make nodes list, it's safer that way.
bn_women_events_nodes <-
bn_women_events_edges |>
  pivot_longer(from:to, values_to = "person") |>
  distinct(person) |>
  inner_join(bn_person_list, by="person")

bn_women_events_network <-
bn_tbl_graph(
  bn_women_events_nodes,
  bn_women_events_edges
)   |>
  #filter(!node_is_isolated()) |> don't need this if you use bn_centrality.
  bn_centrality() |>
  bn_clusters()








# version uisng names instead of numerical ids, like the miserables example

bn_events_nodes_d3 <-
bn_women_events_network |>
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


bn_events_edges_d3 <-
bn_women_events_edges |>
  left_join(bn_events_nodes_d3 |> distinct(source=id, from=person), by="from") |>
  left_join(bn_events_nodes_d3 |> distinct(target=id, to=person), by="to") |>
  select(source, target, from, to, weight, edge_start_year, edge_end_year)
  
 
  
# put in named list ready to write_json  
bn_events_json <-
list(
     nodes= bn_events_nodes_d3,
     links= bn_events_edges_d3
     )   

