source("code/00_config.R")

# from 03_clean-fencelines.R

# processed spatial data
spatFences <- st_read("data/processed/fenceInventory.gpkg", layer = "fencelines")
spatFeatures  <- st_read("data/processed/fenceInventory.gpkg", layer = "fenceFeatures")
spatRange <- st_read("data/processed/fenceInventory.gpkg", layer = "rangeImprovements")
spatWildlife   <- st_read("data/processed/fenceInventory.gpkg", layer = "wildlifeSign")
rm <- st_read("data/processed/fencelinesRemoved2025.shp")

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
    OwnerClass,
    Problem) %>%
  summarize(Meters = sum(length_m, na.rm = TRUE),
    .groups = "drop") %>%
  # convert m to mi
  mutate(km = Meters/1000,
         mi = km2mi(km))

sumYr <- sumFences %>%
  group_by(Year) %>%
  summarize(
    km = sum(km, na.rm = TRUE),
    mi = sum(mi, na.rm = TRUE))

# quick calcs for RMEF report so i can stop fucking doing this

    # miles removed 2025 (manual arcpro - compared usfs allotment boundaries with existing fencelines.
    # converted the polygons to lines, copy-pasted the ones that weren't in existing database,
    # dissolved them to not double-count the boundaries, and exported as "fencelinesRemoved2025.shp")
    rmM <- st_length(rm)
    rmMi <- km2mi(rmM/1000)
    
    # 2025 needs to excl total 2024 (156.7) because some were double counted
    mi2024 <- sumYr$mi[sumYr$Year == 2024]
    miTotal <- sum(sumYr$mi)
    mi2025 <- miTotal - 156.7
      
    # miles by landowner 2024
    # will need to adjust BLM by removing the double-counted 2024 fenceline length
    byOwner <- spatFences %>%
      # for 2025
      filter(Year == 2025,
             Status == "Inventoried") %>%
      # calculate length of each fence segment
      mutate(length_m = as.numeric(st_length(geom))) %>%
      # group by landowner
      st_drop_geometry() %>%
      group_by(Landowner) %>%
      summarize(Meters = sum(length_m, na.rm = TRUE),
                .groups = "drop") %>%
      # convert m to mi
      mutate(km = Meters/1000,
             mi = km2mi(km))




# DO NOT SOURCE OTHER CODE just read in their outputs. can use ifelse to check.

summary_2025 <- formattedTibble
summary_overall <- anotherFormattedTibble

## you'll pull numbers from these, eg total_miles <- summary_overall$total_miles

# number braces
# number gates
# number mortalities
# number fence crossings


