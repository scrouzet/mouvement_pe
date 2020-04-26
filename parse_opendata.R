library(leaflet)

data.ecole.join <- readRDS(file="./data/dataecole.rds")

m <- leaflet(data.ecole.join) %>%
  addTiles() %>%
  addMarkers(lng=data.ecole.join$Longitude, lat=data.ecole.join$Latitude) # , popup="Mouvement 2017"
#  addCircleMarkers()
  #addCircleMarkers(radius = ~nb_jeux)
m

m <- leaflet(data.ecole.join) %>% 
  addTiles() %>%
  fitBounds(~min(data.ecole.join$Longitude,na.rm=T), ~min(data.ecole.join$Latitude,na.rm=T), ~max(data.ecole.join$Longitude,na.rm=T), ~max(data.ecole.join$Latitude,na.rm=T)
  )
m