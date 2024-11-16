# shared libraries, functions etc ####


source("./src/data/shared.R") 

source("./src/data/r_networks_sal_elections_v2.R")
  
## make a zip with several objects

# Add to zip archive, write to stdout.
setwd(tempdir())
write_json(bn_sal_elections_json, "bn-sal-elections_v2.json")
system("zip - -r .")

