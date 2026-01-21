source("code/00_config.R")

# from 03_clean-fencelines.R

# processed spatial data
spatFences <- st_read("data/processed/fenceInventory.gpkg", layer = "fencelines")
spatFeatures  <- st_read("data/processed/fenceInventory.gpkg", layer = "fenceFeatures")
spatRange <- st_read("data/processed/fenceInventory.gpkg", layer = "rangeImprovements")
spatWildlife   <- st_read("data/processed/fenceInventory.gpkg", layer = "wildlifeSign")

# spatial data from project planning
priority_areas <- read_sf("data/project-specific/Priority_Inventory_areas.shp")
pronghorn_range <- read_sf("data/project-specific/projectarea2025.shp")


# fenceline summary table
sumFences <- spatFences %>%
  # for fences that have been mapped,
  filter(Status == "Inventoried") %>%
  # calculate length of each fence segment
  mutate(length_m = as.numeric(st_length(geom))) %>%
  # sum length of fence per thing of interest
  st_drop_geometry() %>%
  group_by(
    Year,
    Group,
    Condition,
    Problem) %>%
  summarize(Meters = sum(length_m, na.rm = TRUE),
    .groups = "drop") %>%
  # convert m to mi
  mutate(Miles = 0.0006213712 * Meters)

sumYr <- sumFences %>%
  group_by(Year) %>%
  summarize(Miles = sum(Miles, na.rm = TRUE))




# DO NOT SOURCE OTHER CODE just read in their outputs. can use ifelse to check.

summary_2025 <- formattedTibble
summary_overall <- anotherFormattedTibble

## you'll pull numbers from these, eg total_miles <- summary_overall$total_miles

# number braces
# number gates
# number mortalities
# number fence crossings


