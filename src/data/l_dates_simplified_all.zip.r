source("./src/data/shared.R") 

source("./src/data/r_dates_all_simplified.R")


# Add to zip archive, write to stdout
setwd(tempdir())
write_csv(bn_dates_all, "dates-all-simplified.csv", na="")
write_csv(bn_dates_all_distinct, "dates-all-distinct.csv", na="")
write_csv(bn_dates_ages, "dates-ages-simplified.csv", na="")
write_csv(bn_dates_ages_distinct, "dates-ages-distinct", na="")
system("zip - -r .")  

