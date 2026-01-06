
# packages(list needed; install missing; load all)
packages <- c(
  "lubridate", # datetimes
  "cowplot", # muti-panel plotting
  "sf", # tidy spatdat
  "stringr", # cleaning names etc
  "tidyverse") # life
ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}    
ipak(packages) ; rm(ipak, packages)



## INVENTORY DATA ##

# exported via Feature Class to Feature Class tool in ArcPro from fence group
# (kristin's master copies in "../../Data/Fencemapping/")
rawFences <- read_sf("data/raw/rawFencelines.shp")
rawFeatures <- read_sf("data/raw/rawFenceFeatures.shp")
rawWildlife <- read_sf("data/raw/rawWildlifeObservations.shp")
rawRange <- read_sf("data/raw/rawRangeImprovements.shp")



## PROJECT-SPECIFIC DATA ##

priority_areas <- read_sf("data/project-specific/Priority_Inventory_areas.shp")
pronghorn_range <- read_sf("data/project-specific/projectarea2025.shp")

