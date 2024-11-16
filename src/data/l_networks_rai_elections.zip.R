# shared libraries, functions etc ####


source("./src/data/shared.R") 

source("./src/data/r_networks_rai_elections.R")
  
## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
write_json(bn_rai_elections_json, "bn-rai-elections.json")
system("zip - -r .")

