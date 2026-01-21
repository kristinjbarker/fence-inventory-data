source("code/00_config.R")
source("code/01_load-fence-data.R")
source("code/02_wrangling-functions.R")


# fencelines
spatFences <- rawFences %>%
  # only consider fences in our region
  filter(WGFD_Regio == "Cody") %>%
  # remove incorrect data collected on training day
  filter(!(!is.na(Date_of_Co) & Date_of_Co == trainingday)) %>%
  filter(!(!is.na(Comments) & Comments == "Field apps testing")) %>%
  # update inventory status (edited vs newly mapped not always correct)
  mutate(Status = case_when(
    Inventory_ %in% "Edited fence" ~ "Inventoried",
    Inventory_ %in% "Newly mapped fence" ~ "Inventoried",
    Inventory_ %in% "Removed fence" ~ "Removed",
    is.na(Inventory_) ~ "Not inventoried",
    TRUE ~ Inventory_
  )) %>%
  # fix status of old AFI data that was definitely not collected in 1899
  mutate(Status = ifelse(!is.na(Date_of_Co) & Date_of_Co == "1899-12-30", 
                           "Not inventoried", Status)) %>%
  # note correct date when data collected
  mutate(Date = as.Date(ifelse(Status == "Inventoried" | Status == "Removed",
                               Date_of_Co, NA))) %>%
  # note data source (when known) of original fence shapefile
  rename(sauce = Source) %>%
  mutate(Source = ifelse(!is.na(sauce), sauce, Creator)) %>%
  mutate(Source = case_when(
    str_detect(Creator, regex("wgfd", ignore_case = TRUE)) ~ "WGFD",
    str_detect(Source, regex("NF")) ~ "USFS",
    TRUE ~ Source
  )) %>%
  # make collectors' names characters and make all lowercase for easier string matching
  mutate(Collector_ = ifelse(is.na(Collector_), "NA", tolower(Collector_))) %>%
  # clean and standardize names of collectors
  mutate(Collector = as.character(sapply(Collector_, clean_collector))) %>%
  # only need collector name if data were collected...
  mutate(Collector = ifelse(Status == "Not inventoried", NA,
                            Collector)) %>%
  # add organization name based on collector name
  mutate(Group = as.character(sapply(Collector, clean_org))) %>%
  # fix names and groups where possible when no name entered
  mutate(
    Group = case_when(
      Status == "Not inventoried" ~ NA,
      # assign group based on arcGIS account names
      Collector %in% c("Na") & str_detect(Editor, regex("cal", ignore_case = TRUE)) ~ "BYLL",
      Collector %in% c("Na") & str_detect(Editor, regex("TNC", ignore_case = TRUE)) ~ "AFI",
      Collector %in% c("Na") & str_detect(Editor, regex("wgfd", ignore_case = TRUE)) ~ "WGFD",
      Collector == "Other" & str_detect(Editor, regex("brittparker", ignore_case = TRUE)) ~ "BHA",
      Group == "UnkOther" & !is.na(Agency_Org) ~ Agency_Org,
      TRUE ~ Group  # keep existing value if none of the above match
    )
  ) %>%
  mutate(Group = ifelse(str_detect(Group, " "), as.character(sapply(Group, abbrev_org)), Group)) %>%
  # quick fix for few issues found post hoc (folks who helped our techs are BYLL; britt effed up)
  mutate(Group = ifelse(Group == "USFS" & str_detect(Editor, regex("cal")), "BYLL", Group),
         Group = ifelse(Group == "Other" & str_detect(Editor, regex("cal")), "BYLL", Group),
         Group = ifelse(Group == "Other" & str_detect(Editor, regex("britt")), "BYLL", Group)) %>%
  # combine standard and nonstandard wire heights
  mutate(WireHeights = ifelse(Fence_Wire == "Other", Fence_Wi_1, Fence_Wire)) %>%
  # add length
  mutate(lgthMeters = as.numeric(st_length(.))) %>%
  # update column names
  rename(FenceID = AFI_FenceI,
         Type = Fence_Mate,
         Material = Material_T,
         Landowner = Land_Agenc,
         Comments = "Comments",
         arcAccount = "Editor",
         Accessibility = "Project_Ac",
         Urgency = "Project_Ur",
         WireCount = "Num_WireOr",
         Stays = "Wire_Stays",
         arcID = GlobalID_1) %>%
    # add generic landownership (usf/blm/other)
    mutate(OwnerClass = ifelse(grepl(Landowner, pattern = "Game"), "Forest Service", # WGFD is in SNF
                              # state borders BLM
                              ifelse(grepl(Landowner, pattern = "State"), "State",
                                     ifelse(Landowner != "Bureau of Land Management" &
                                              Landowner != "Forest Service", "Other",
                                            Landowner)))) %>%
  # add some generic indicators (for arcpro viz mostly)
  mutate(Problem = case_when(
    is.na(Urgency) ~ NA,
    Urgency == "Other" ~ "Other",
    Urgency == "Not time sensitive—not as above" ~ "No",
    grepl("Time sensitive \\(", Urgency) ~ "Yes")) %>%
  mutate(Access = case_when(
    Accessibility == "Easily accessible by vehicle (roadside)" ~ "Drive",
    Accessibility == "Easily accessibly by short (0.25 mile) hike" ~ "Walk",
    Accessibility == "Not accessible as above" ~ "Challenging",
    Accessibility == "Other" ~ "Other",
    is.na(Accessibility) ~ NA)) %>%
  mutate(Condition = condition_cleanup(Fence_Cond)) %>%
  # add some year/field season indicators 
  mutate(Year = year(Date)) %>%
  # remove some extraneous columns
  dplyr::select(c(FenceID, Date, Status, Condition, Problem, Access, 
                 Type, Material, WireCount, WireHeights, Railtop, Stays,
                 Access, OwnerClass, Landowner, 
                 Collector, Group, Year,
                 Source, lgthMeters, 
                 Accessibility, Urgency, Fence_Cond,
                 arcAccount, Comments, arcID))


# also store in nonspatial dataframe
datFences <- st_drop_geometry(spatFences)

# fence features
spatFeatures <- rawFeatures %>%
  # remove incorrect data collected on training day
  filter(!(!is.na(Date_of_Co) & Date_of_Co == trainingday)) %>%
  filter(!(!is.na(Comments) & Comments == "Field apps testing")) %>%
  # make names characters and make all lowercase for easier string matching
  mutate(Collector_ = ifelse(is.na(Collector_), "NA", tolower(Collector_))) %>%
  # clean and standardize names of collectors
  mutate(Collector = as.character(sapply(Collector_, clean_collector))) %>%
  # add organization name based on collector name
  mutate(Group = as.character(sapply(Collector, clean_org))) %>%
  # fix names and groups where possible when no name entered
  mutate(
    Group = case_when(
      # assign group based on arcGIS account names
      Collector %in% c("Na") & str_detect(Editor, regex("cal", ignore_case = TRUE)) ~ "BYLL",
      Collector %in% c("Na") & str_detect(Editor, regex("TNC", ignore_case = TRUE)) ~ "AFI",
      Collector %in% c("Na") & str_detect(Editor, regex("wgfd", ignore_case = TRUE)) ~ "WGFD",
      Collector == "Other" & str_detect(Editor, regex("brittparker", ignore_case = TRUE)) ~ "BHA",
      Group == "UnkOther" & !is.na(Agency_Org) ~ Agency_Org,
      TRUE ~ Group  # keep existing value if none of the above match
    )
  ) %>%
  mutate(Group = ifelse(str_detect(Group, " "), as.character(sapply(Group, abbrev_org)), Group))
  
# also store in nonspatial dataframe
datFeatures <- st_drop_geometry(spatFeatures)

# rangeland improvements
spatRange <- rawRange %>%
  # remove incorrect data collected on training day
  filter(!(!is.na(Date_of_Co) & Date_of_Co == trainingday)) %>%
  # make names characters and make all lowercase for easier string matching
  mutate(Collector_ = ifelse(is.na(Collector_), "NA", tolower(Collector_))) %>%
  # clean and standardize names of collectors
  mutate(Collector = as.character(sapply(Collector_, clean_collector))) %>%
  # add organization name based on collector name
  mutate(Group = as.character(sapply(Collector, clean_org))) %>%
  # fix names and groups where possible when no name entered
  mutate(
    Group = case_when(
      # assign group based on arcGIS account names
      Collector %in% c("Na") & str_detect(Editor, regex("cal", ignore_case = TRUE)) ~ "BYLL",
      Collector %in% c("Na") & str_detect(Editor, regex("TNC", ignore_case = TRUE)) ~ "AFI",
      Collector %in% c("Na") & str_detect(Editor, regex("wgfd", ignore_case = TRUE)) ~ "WGFD",
      Collector == "Other" & str_detect(Editor, regex("brittparker", ignore_case = TRUE)) ~ "BHA",
      Group == "UnkOther" & !is.na(Agency_Org) ~ Agency_Org,
      TRUE ~ Group  # keep existing value if none of the above match
    )
  ) %>%
  mutate(Group = ifelse(str_detect(Group, " "), as.character(sapply(Group, abbrev_org)), Group))

# also store in nonspatial dataframe
datRange <- st_drop_geometry(spatRange)

# wildlife observations
spatWildlife <- rawWildlife %>%
  # remove incorrect data collected on training day
  filter(!(!is.na(Date_of_Co) & Date_of_Co == trainingday)) %>%
  filter(!(!is.na(Comments) & Comments == "Field apps testing")) %>%
  # make names characters and make all lowercase for easier string matching
  mutate(Collector_ = ifelse(is.na(Collector_), "NA", tolower(Collector_))) %>%
  # clean and standardize names of collectors
  mutate(Collector = as.character(sapply(Collector_, clean_collector))) %>%
  # add organization name based on collector name
  mutate(Group = as.character(sapply(Collector, clean_org))) %>%
  # fix names and groups where possible when no name entered
  mutate(
    Group = case_when(
      # assign group based on arcGIS account names
      Collector %in% c("Na") & str_detect(Editor, regex("cal", ignore_case = TRUE)) ~ "BYLL",
      Collector %in% c("Na") & str_detect(Editor, regex("TNC", ignore_case = TRUE)) ~ "AFI",
      Collector %in% c("Na") & str_detect(Editor, regex("wgfd", ignore_case = TRUE)) ~ "WGFD",
      Collector == "Other" & str_detect(Editor, regex("brittparker", ignore_case = TRUE)) ~ "BHA",
      Group == "UnkOther" & !is.na(Agency_Org) ~ Agency_Org,
      TRUE ~ Group  # keep existing value if none of the above match
    )
  ) %>%
  mutate(Group = ifelse(str_detect(Group, " "), as.character(sapply(Group, abbrev_org)), Group))

# also store in nonspatial dataframe
datWildlife <- st_drop_geometry(spatWildlife)



#### EXPORT ####

  
# geopackage (spatial layers)
  
  st_write(spatFences, "data/processed/fenceInventory.gpkg", layer = "fencelines",  delete_layer = TRUE)
  st_write(spatFeatures, "data/processed/fenceInventory.gpkg", layer = "fencefeatures",   append = TRUE)
  st_write(spatRange, "data/processed/fenceInventory.gpkg", layer = "rangeimprovements",  append = TRUE)
  st_write(spatWildlife, "data/processed/fenceInventory.gpkg", layer = "wildlifesign", append = TRUE)

# nonspatial data files - rds
  
  saveRDS(datFences, "data/processed/fencelines.rds")
  saveRDS(datFeatures, "data/processed/fenceFeatures.rds")
  saveRDS(datRange, "data/processed/rangeImprovements.rds")
  saveRDS(datWildlife, "data/processed/wildlifeSign.rds")
  
# nonspatial data files - csv
  
  write.csv(datFences, "data/processed/fencelines.csv", row.names = F, append = FALSE)
  write.csv(datFeatures, "data/processed/fenceFeatures.csv", row.names = F, append = FALSE)
  write.csv(datRange, "data/processed/rangeImprovements.csv", row.names = F, append = FALSE)
  write.csv(datWildlife, "data/processed/wildlifeSign.csv", row.names = F, append = FALSE)

  