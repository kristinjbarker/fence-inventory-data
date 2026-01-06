source("00_config.R")

# from 03_clean-fencelines.R
spatFences <- st_read("data/processed/fencelines.shp")
spatFeatures <- st_read("data/processed/fenceFeatures.shp")
spatRange <- st_read("data/processed/rangeImprovements.shp")
spatWildlife <- st_read("data/processed/wildlifeSign.shp")

# from project planning
priority_areas <- read_sf("data/project-specific/Priority_Inventory_areas.shp")
pronghorn_range <- read_sf("data/project-specific/projectarea2025.shp")


## FILTER TO CODY REGION


# DO NOT SOURCE OTHER CODE just read in their outputs. can use ifelse to check.

summary_2025 <- formattedTibble
summary_overall <- anotherFormattedTibble

## you'll pull numbers from these, eg total_miles <- summary_overall$total_miles

# summarize (a) for 2025 and (b) overall
# number of weeks?
# miles fence mapped
#   miles mapped by BYLL/mapped by others
#   miles fence in need of assessment for removal/repair
#   miles poor condition fences
# separate est for fences in poor condition or urgent within highest use areas?
# number braces
# number gates
# number mortalities
# number fence crossings
# 
# number individuals who collected data
# number groups who helped collect data
# 2025 only - area of pronghorn range? area of priority areas? only BLM area within?

