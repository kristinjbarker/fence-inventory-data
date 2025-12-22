## packages (list needed; install missing; load all)
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


## spatial data definitions
crs_fences <- 26912

dist_unit <- "miles"

point_types <- c("gate", "brace", "wildlife_sign")

## collectors and groups