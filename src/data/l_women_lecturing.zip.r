

# shared libraries, functions etc ####

source("./src/data/shared.R") 

source("./src/data/r_women_lecturing.R")

 
# Add to zip archive, write to stdout
setwd(tempdir())
write_csv(bn_lecturers_dates, "lecturers-dates.csv", na="")
#write_csv(var_loadings_scaled, "var-loadings.csv") etc etc
system("zip - -r .")

