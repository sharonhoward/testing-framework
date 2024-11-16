# shared libraries, functions etc ####


source("./src/data/shared.R") 

source("./src/data/r_networks.R")
  
## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
#write_csv(bn_events_nodes_js, "bn-events-nodes.csv")
#write_csv(bn_events_edges_js, "bn-events-edges.csv")
write_json(bn_events_json, "bn-events.json")
system("zip - -r .")

