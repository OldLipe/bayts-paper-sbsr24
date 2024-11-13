library(sits)

#
# Reading BDC tile
#
bdc_grid <- sf::st_read("./data/raw/bdc/BDC_TILE_LG_V2_003003.gpkg")

#
# Creating CBERS cube
#
cbers_cube <- sits::sits_cube(
  source = "BDC",
  collection = "CBERS-WFI-8D",
  start_date = "2023-01-01",
  end_date = "2023-12-31",
  bands = c("EVI", "CLOUD"),
  tiles = "003003"
)

#
# Downloading CBERS cube images
#
cbers_cube <- sits::sits_cube_copy(
  cbers_cube, 
  multicores = 12,
  output_dir = "./data/raw/bdc/cbers-4a/"
)

#
# Creating Sentinel-1 cube
#
s1_cube <- sits::sits_cube(
  source = "MPC",
  collection = "SENTINEL-1-RTC",
  start_date = "2024-01-01",
  end_date = "2024-01-31",
  roi = bdc_grid,
  orbit = "descending"
)

#
# Regularize Sentinel-1 cube using BDC grid
#
s1_reg <- sits::sits_regularize(
  cube = s1_cube,
  period = "P30D",
  res = 64,
  tiles = "003003",
  tile_system = "BDC_LG_V2",
  output_dir = "./data/raw/bdc/sentinel-1"
)