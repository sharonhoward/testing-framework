# shared libraries, functions etc ####


source("./src/data/shared.R") 

source("./src/data/r_networks_excavations.R")
  
## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
write_json(bn_excavations_json, "bn-excavations.json")
system("zip - -r .")
