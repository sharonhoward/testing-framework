# shared libraries, functions etc ####


source("./src/data/shared.R") 

source("./src/data/r_connections.R")
  
## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
write_csv(bn_connections_nodes_d3, "bn-connections-nodes.csv")
write_csv(bn_connections_edges_d3, "bn-connections-edges.csv")
write_json(bn_connections_json, "bn-connections.json")
system("zip - -r .")
