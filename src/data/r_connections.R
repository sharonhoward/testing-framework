# general functions for network analysis ####

library(tidygraph)



bn_connections_sparql <-
'select distinct ?personLabel ?propLabel ?qual_propLabel ?connectionLabel ?valueLabel ?qual_date ?person ?connection ?prop ?qual_prop ?value
?s
where
{
  ?person bnwdt:P3 bnwd:Q3 .
  FILTER NOT EXISTS {?person bnwdt:P4 bnwd:Q12 .}  
  
  ?person ?p ?s .
     ?prop wikibase:claim ?p .
  ?prop wikibase:statementProperty ?ps.
  
  {
      ?s ?ps ?connection.
      ?connection bnwdt:P12 bnwd:Q2137.
      
    }
  
    union
  
    {
     ?s ?ps ?value .
     ?s ?qual_p ?connection .   
     ?qual_prop wikibase:qualifier ?qual_p. 
        ?connection bnwdt:P12 bnwd:Q2137 .
        FILTER NOT EXISTS {?connection bnwdt:P4 bnwd:Q12 .} 
    }
  
    optional {
      ?s ( bnpq:P1 | bnpq:P27 ) ?qual_date
      }
  
  SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en,en-gb". }
}
ORDER BY ?personLabel'

bn_connections_query <-
  bn_std_query(bn_connections_sparql) |>
  make_bn_item_id(person) |>
  make_bn_ids(c(connection, prop, qual_prop, value, s)) |>
  mutate(across(c(qual_date, qual_propLabel, qual_prop, value, valueLabel), ~na_if(., ""))) |>
  select(-person)

# drop stuff you don't want and spouses.
bn_connections_filtered <-
  bn_connections_query |>
  filter(!qual_prop %in% c("P91", "P20") | is.na(qual_prop)) |>
  filter(!prop %in% c("P152", "P151")) |>
  # not named people
  filter(!connection %in% c("Q2753", "Q17", "Q1587", "Q47")) |>
  # and drop all the spouses
  filter(!str_detect(propLabel, "married|spouse"))

# dedup to one row per spouse per person
bn_spouses_deduped <-
bn_connections_query |>
  filter(!qual_prop %in% c("P91", "P20") | is.na(qual_prop)) |>
  filter(str_detect(propLabel, "married|spouse"))|>
  # not in database
  filter(!connection %in% c("Q2753")) |>
  group_by(bn_id, connection) |>
  arrange(propLabel, .by_group = T) |>
  top_n(1, row_number()) |>
  ungroup()

# put the two sets back together
bn_connections <-
bind_rows(
  bn_connections_filtered,
  bn_spouses_deduped) |>
  arrange(personLabel)  |>
  mutate(connection_type = case_when(
    !is.na(qual_propLabel) ~ qual_propLabel,
    .default = propLabel
  )) |>
  mutate(date = case_when(
    str_detect(value, "T00:00:00Z") ~ value,
    .default = qual_date
  )) |>
  make_date_year() |>
  # remove four men (8 rows) who have two IDs for same name
  filter(!connection %in% c("Q1593", "Q1924", "Q1698", "Q1770", "Q304",  "Q3947", "Q1547", "Q1683")) |>
  relocate(connectionLabel, connection, connection_type, date, year, .after = personLabel)



bn_connections_edges <-
bn_connections |>
  count(personLabel, connectionLabel, bn_id, connection, name="weight") |>
  rename(from=bn_id, to=connection)

# this needs to include the connections as well as persons doesn't it?
bn_connections_nodes <-
bn_connections |>
  select(person_id=bn_id, personLabel) |>
  bind_rows(
    bn_connections |>
      select(person_id=connection, personLabel=connectionLabel)
  ) |>
  count(person_id, personLabel, name="n_connections")
  


bn_connections_tidygraph <-
tbl_graph(
  bn_connections_nodes,
  bn_connections_edges,
  node_key = "person_id",
  directed = TRUE
) |>
  mutate(degree = centrality_degree(weights=weight) ) |>
  mutate(grp1 = as.factor(group_edge_betweenness(directed=TRUE))) |> # this takes a little while...
  mutate(grp2 = as.factor(group_infomap())) |>
  mutate(grp3 = as.factor(group_leading_eigen())) 
  
  

# add numerical IDs counting from 0 for JS. 
bn_connections_nodes_js <-
bn_connections_tidygraph  |>
  #filter(!node_is_isolated()) |> # shouldn't be any in this case
  as_tibble() |>
  # make the node ids; subtract 1 for D3 compatibility.
  rowid_to_column("id") |>
  mutate(id=id-1) |>
  select(id, label=personLabel, person_id, degree, grp1:grp3)


bn_connections_edges_js <-
bn_connections_tidygraph |>
  activate(edges) |>
  as_tibble() |>
  # seems this is all you need to do.
  mutate(from=from-1, to=to-1)
  


# version uisng names instead of numerical ids, like the miserables example

bn_connections_nodes_d3 <-
bn_connections_tidygraph  |>
  as_tibble() |>
  select(id=personLabel, person_id, n_connections, degree, starts_with("grp")) |>
  mutate(name_label = if_else(n_connections>19, id, ""))


bn_connections_edges_d3 <-
bn_connections_tidygraph  |>
  activate(edges) |>
  as_tibble() |>
  rename(source= personLabel, target=connectionLabel, value=weight) |>
  relocate(value, from, to, .after = last_col())
  
  
  
  
# put in named list ready to write_json  
bn_connections_json <-
list(links= bn_connections_edges_d3,
     nodes= bn_connections_nodes_d3
     )     
