
source("./src/data/shared.R") 

source("./src/data/r_women_children.R")



## make a zip even though you only have one file to start with, so you have the method...
## not sure from docs if .zip. naming of this file matters but makes sense for clarity anyway.

# Add to zip archive, write to stdout
setwd(tempdir())
write_csv(bn_had_children_ages, "had-children-ages.csv", na="")
write_csv(bn_work_years_children, "work-years-with-children.csv", na="")
write_csv(bn_served_years_children, "served-years-with-children.csv", na="")
write_csv(bn_last_ages, "consolidated-last-ages.csv", na="")
write_csv(bn_last_ages_all, "last-ages-all.csv", na="")
write_csv(bn_work_served_years_children, "work-served-years-with-children.csv", na="")
write_csv(bn_spoke_ages_years_children, "spoke-years-with-children.csv")
write_csv(bn_work_served_spoke_years_children, "work-served-years-with-children.csv", na="")
system("zip - -r .")  



#cat(format_csv(bn_had_children_ages_sorted_by_start_age, na=""))
   

# code for age at birth barcode chart, sorted by birth date

# bn_had_children_ages_barcode |> 
#   mutate(start_age = min(age)-1) |>
#   mutate(last = max(age), .by = bn_id) |>
#   mutate(personLabel = fct_rev(fct_reorder(personLabel, bn_dob))) |>
# 
#   ggplot(aes(y=personLabel, x=age)) +
#   geom_segment( aes(x=start_age, xend=last, yend=personLabel), linewidth=0.2, colour="lightgrey") +
# 
#   geom_point(shape = 124, size = 2.2, colour="black") +
#   scale_x_continuous(expand = expansion(mult = c(0, .01))) + # remove/reduce gap.
#   theme(axis.ticks.y=element_blank() ) +
#   #scale_color_colorblind() +
#   #theme(legend.position = "bottom") +
#   labs(y=NULL, x=NULL)
