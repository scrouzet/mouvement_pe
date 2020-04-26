library(shiny)
library(leaflet)
library(dplyr)

data.ecole.join <- readRDS(file="./data/dataecole.rds")

#data.ecole.join <- data.ecole.join[!is.na(data.ecole.join$ENS.CL.MA_nbV),]

ui <- bootstrapPage( #fluidPage #bootstrapPage
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("mouvementPE", width = "100%", height = "100%"),
  absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                draggable = TRUE, top = "100", left = "auto", right = 30, bottom = "auto",
                width = 400, height = "auto", style = "opacity: 0.82",
                
                #h2("Filtres"),
                
                # ENS.CL.MA_nbV ENS.CL.ELE_nbV T.R.S._nbV 
                sliderInput("range", "Nombre de poste MA susc_vacant :", 0, max(data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV, na.rm=T),
                            value = c(0,max(data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV, na.rm=T)), step = 1, ticks=F
                            )
                
                # selectInput("geolocalisation", "Géolocalisation :",
                #              choice = list("Tous" = "tous",
                #                            "OnMouv" = "OnMouv",
                #                            "StartMouv" = "StartMouv",
                #                            "EndMouv" = "EndMouv",
                #                            "Life" = "Life",
                #                            "Perte ou Vol" = "alerte"),
                #              #multiple=TRUE,
                #              selectize=FALSE)
                
                # actionButton("appairage","Decrochage non autorisé",icon=icon("truck"),
                #              style = "color: white;
                #              background-color: #B40404",
                #              width = 250),
                )
)

server <- function(input, output, session) {
  
  filteredData <- reactive({
    data.ecole.join[data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV >= input$range[1] & data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV <= input$range[2],]
  })

  output$mouvementPE <- renderLeaflet({
    leaflet(data = filteredData()) %>%
      addTiles() %>%
      addMarkers(~Longitude, ~Latitude,
                 label = ~paste("Nom : ",nom,"::: Niveau : ",niveau),
                 #popup= ~paste("blabla")
                 popup= ~paste("<h4><font color='#2B547E'><b>Nom : </font></b>",nom,
                                "</h4><h4><font color='#2B547E'>Niveau : </font>",niveau,
                                "</h4><h4><font color='#2B547E'>MAT nb vacant : </font>",ENS.CL.MA_ECMA_SANS_SPEC_nbV,
                                "</h4><h4><font color='#2B547E'>MAT nb susc_vacant : </font>",ENS.CL.MA_ECMA_SANS_SPEC_nbSV,
                                "</h4><h4><font color='#2B547E'>ELE nb vacant : </font>",ENS.CL.ELE_ECEL_SANS_SPEC_nbV,
                                "</h4><h4><font color='#2B547E'>ELE nb susc_vacant : </font>",ENS.CL.ELE_ECEL_SANS_SPEC_nbSV,
                                "</h4><h4><font color='#2B547E'>descriptif : </font>",descriptif,"</h4>")                 
      )
  })
}

shinyApp(ui, server)