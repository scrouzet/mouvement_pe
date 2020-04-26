# Parser spécifique pour le pdf fourni par l'Education Nationale avec la liste des postes
# disponibles pour le mouvement dans les écoles primaires de Haute-Garonne.

library(pdftools)
library(stringr)
library(dplyr)

cleanMyString <- function(string){
  string = str_sub(string, start=2, end=-2) # removes the "I" located 1st and last
  string = str_replace(string, " I ", "") # removes the middle "I"
  string = str_trim(string, side = "both")
  return(string)
}

# PARAMETRES
region    = "Midi-Pyrenees France"  # to be added to the address
startpage = 3                        # exlusion des 1eres pages car pas compris
filename  = "./data/liste-PV-et-PSV-1278120.pdf"
list_interet = c("ENS.CL.MA_ECMA_SANS_SPEC", "ENS.CL.ELE_ECEL_SANS_SPEC") # type de poste a extraire

# Extract all the content of the pdf as txt
txt <- pdf_text(filename)

# initialize ecole as a list (to be later converted to a data.frame)
ecole = list(commune=c(), id=c(), nom=c(), adresse=c(), ien=c(), niveau=c(), descriptif=c(), page=c(), 
             ENS.CL.MA_ECMA_SANS_SPEC_nbV = c(),
             ENS.CL.MA_ECMA_SANS_SPEC_nbSV = c(),
             ENS.CL.ELE_ECEL_SANS_SPEC_nbV = c(),
             ENS.CL.ELE_ECEL_SANS_SPEC_nbSV = c())
# loop over pages
ec=1
for ( npage in c(startpage:length(txt)) ) {
  mypage = strsplit(txt[npage], split="\n")
  mypage = mypage[[1]]
  
  # Extract the cell locations in this page
  mysplit = "I-----------------------------------I"
  list_ligne = c()
  for ( ligne in c(1:length(mypage)) ) {
    cellbegin = gregexpr(mysplit,mypage[ligne])
    if ( cellbegin[[1]][1] > 0 ) {
      list_ligne = c(list_ligne,ligne) 
    }
  }
  list_ligne = list_ligne+1
  
  # Extract the content of each cell and put it in a data.frame
  if (length(list_ligne)>0){
    for ( cell in c(1:length(list_ligne)) ) {
      
      school_id = cleanMyString(mypage[list_ligne[cell]+1])
      valid_school_id = str_sub(school_id,1,1)=="*";          # check if valid ID
      school_id = substring(school_id, 2, nchar(school_id)-1) # remove the stars
      
      # if the cell appears valid
      if (!is.na(valid_school_id) & length(valid_school_id)>0 & valid_school_id==T) {
        
        ecole$commune[ec] = cleanMyString(mypage[list_ligne[cell]])
        ecole$id[ec]      = school_id
        ecole$nom[ec]     = cleanMyString(mypage[list_ligne[cell]+2]) # E.M.PU mater et E.E.PU elementaire + nom ecole
        ecole$adresse[ec] = paste(cleanMyString(mypage[list_ligne[cell]+3]), ecole$commune[ec], region) # adresse
        ecole$ien[ec]     = cleanMyString(mypage[list_ligne[cell]+4]) # surement la circonscription
        ecole$niveau[ec]  = str_trim( str_sub(ecole$nom[ec],1,6) )
        
        # process the descriptif
        numid = 0
        li = list_ligne[cell]+5
        mydescriptif = ""
        while (!is.na(numid)) {
          myline = mypage[li]
          numid = as.numeric(str_sub(myline,8,11))
          if (is.na(numid)){
            break
          } else
            mydescriptif = paste(mydescriptif,cleanMyString(myline),sep=";") # store le paquet de texte au cas ou
          
          mystart = str_locate(myline,"ENS.CL.")[1]
          myend = str_locate(myline,"SANS SPEC")[2]
          jobstr = str_trim(str_sub(myline,mystart,myend))
          jobstr = str_replace_all(string=jobstr, pattern=" ", repl="_")
          if (!is.na(match(jobstr,list_interet))) {
            sep_loc = str_locate_all(myline,'I')
            values = str_sub(myline,sep_loc[[1]][2,2]+1,nchar(myline)-1)
            # Extract number of positions available or supposedly available
            ecole[[paste0(jobstr,"_nbV")]][ec]  = as.numeric( str_sub(values,4,8) ) # nb.V
            ecole[[paste0(jobstr,"_nbSV")]][ec] = as.numeric( str_sub(values,12,16) ) # nb.SV
          }
          #if (!is.na(match(jobstr,list_interet))) {
#            if (school_id=='0311743B'){
#            browser()
            # }
            # Extract number of positions available or supposedly available
#            ecole[[paste0(jobstr,"_nbV")]][ec]  = as.numeric( str_sub(myline,49,53) ) # nb.V
#            ecole[[paste0(jobstr,"_nbSV")]][ec] = as.numeric( str_sub(myline,57,61) ) # nb.SV
#          }
          
          li=li+1
        }
        ecole$descriptif[ec] = mydescriptif
        ecole$page[ec] = npage
        ec=ec+1
      }
    }
  }
}

# Convert to a proper data.frame
data.ecole         <- data.frame( do.call("cbind", ecole) )
data.ecole$id      <- as.character(data.ecole$id)
data.ecole$nom     <- as.character(data.ecole$nom)
data.ecole$adresse <- as.character(data.ecole$adresse)


# Load les adresses officielles depuis le site data.education.gouv
# https://data.education.gouv.fr/explore/dataset/fr-en-adresse-et-geolocalisation-etablissements-premier-et-second-degre/table/?disjunctive.nature_uai&disjunctive.nature_uai_libe&disjunctive.code_departement&disjunctive.code_region&disjunctive.code_academie
liste_adresse = read.csv2('./data/fr-en-adresse-et-geolocalisation-etablissements-premier-et-second-degre.csv')
#liste_adresse = read.csv2('./data/DEPP-etab-1D2D.csv',encoding="latin1")
#liste_adresse2 = read.csv2('./data/depp-etablissements-premier-et-second-degres-structures-administratives-education-avril-2014.csv',encoding="latin1")

liste_adresse$Longitude <- as.numeric(levels(liste_adresse$Longitude))[liste_adresse$Longitude]
liste_adresse$Latitude <- as.numeric(levels(liste_adresse$Latitude))[liste_adresse$Latitude]

# join data du fichier de mouvement et de la base open avec toutes les coordonnees des ecoles
data.ecole.join = left_join(data.ecole, liste_adresse, by = c("id" = "Code.établissement"))

data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbV  <- as.numeric(levels(data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbV))[data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbV]
data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV  <- as.numeric(levels(data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV))[data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV]

data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbV  <- as.numeric(levels(data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbV))[data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbV]
data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbSV  <- as.numeric(levels(data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbSV))[data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbSV]

# Replace all NA with 0
data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbV[is.na(data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbV)] = 0
data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV[is.na(data.ecole.join$ENS.CL.MA_ECMA_SANS_SPEC_nbSV)] = 0

data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbV[is.na(data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbV)] = 0
data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbSV[is.na(data.ecole.join$ENS.CL.ELE_ECEL_SANS_SPEC_nbSV)] = 0

# On ne garde que les écoles pour lesquelles on a les données de géolocalisation
data.ecole.join <- data.ecole.join[!is.na(data.ecole.join$Longitude) & !is.na(data.ecole.join$Latitude),]

# SAVE
#write.table(data.ecole.join,file="./data/dataecole.csv", quote = F, sep = ",", row.names = F)
saveRDS(data.ecole.join,file="./data/dataecole.rds")