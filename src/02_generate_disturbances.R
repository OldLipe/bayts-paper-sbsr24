library(sits)

#
# Define a region of interest
#
roi <- c(
  "lon_min" = -62.93487892,
  "lat_min" = -8.95064679,
  "lon_max" = -62.45746457,
  "lat_max" = -8.59219213
)

#
# Creating a local CBERS cube
#
cbers_cube <- sits::sits_cube(
  source = "BDC",
  collection = "CBERS-WFI-8D",
  data_dir = "./data/raw/bdc/cbers-4"
)

#
# Creating a local Sentinel-1 cube
#
s1_cube <- sits::sits_cube(
  source = "MPC",
  collection = "SENTINEL-1-RTC",
  data_dir = "./data/raw/bdc/sentinel-1"
)

#
# Merging CBERS and Sentinel-1 cubes
#
merged_cubes <- sits::sits_merge(cbers_cube, s1_cube)

#
# Defining mean and sd values for bayts method
#
em <- tibble::tribble(
  ~stats, ~label, ~VH, ~EVI,
  "mean", "forest", 0.08, 0.7,
  "mean", "non-forest", 0.02, 0.4,
  "sd", "forest",  0.001,  0.1,
  "sd", "non-forest", 0.00125, 0.0125
)

#
# Creating a bayts model
#
radd <- sits::sits_detect_change_method(
  samples = NULL, sits::sits_radd(
    stats = em,
    start_date = "2023-01-01",
    end_date = "2023-12-31",
    chi = 0.9
  )
)

#
# Detecting changes in the roi area using combined cubes
#
res <- sits::sits_detect_change(
  data = sits::sits_select(merged_cubes, bands = c("VH", "EVI", "CLOUD")),
  dc_method = radd,
  multicores = 10,
  roi = roi,
  memsize = 24,
  output_dir = "./data/derived",
  version = "evi-vh-chi09-aggregate-false-area-002"
)
