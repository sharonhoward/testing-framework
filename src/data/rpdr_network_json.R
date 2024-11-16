library(tidyverse)
library(jsonlite)

f<-read.csv("franchises.csv")
sc<-read.csv("season_contestants.csv")
s<-read.csv("seasons.csv")|>
  inner_join(f, by=c("franchise_id"))|>
  mutate(season_name = paste0(franchise_name, " S", season))
sc<-sc|>
  left_join(s|>select(season_id, season_name), by=c("season_id"="season_id"))

c<-sc|>filter(appearence_number==1)

sc<-sc|>
  group_by(final_url)|>
  mutate(queen_name = contestant[appearence_number == 1])|>
  ungroup()

df_node1<-f|>select(franchise_name)|>rename(id=franchise_name)|>mutate(group="FRAN")
df_node2<-s|>select(season_name, season_id)|>rename(id = season_name, group=season_id)
df_node3<-c|>select(name = contestant, season_id)|>rename(id = name, group = season_id)

df_node<-rbind(df_node1, df_node2, df_node3)

df_link1<-sc|>select(season_name, queen_name)|>
  rename(source=season_name, target = queen_name)|>mutate(value=1)|>select(target,source,value)

df_link2<-s|>select(season_name, franchise_name)|>rename(source=franchise_name, target= season_name)|>mutate(value=1)

df_link<-rbind(df_link1, df_link2)

nodes <- toJSON(data.frame(id = df_node$id, group = df_node$group))
links <- toJSON(data.frame(source = df_link$source, target = df_link$target, value = df_link$value))

json <- toJSON(list(nodes = fromJSON(nodes), links = fromJSON(links)))

write(json, file = "rpdr.json")


ref_queen_image = sc|>select(id = queen_id, name = queen_name, link_image = image_url)|>mutate(original_season = substr(id,1,5))
ref_queen_image$link_image <- gsub("/revision.*$", "", ref_queen_image$link_image)
write.csv(ref_queen_image,"ref_queen_image.csv", row.names=F)

