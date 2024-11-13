#
# Importing packages
#
library(sf)
library(dplyr)

#
# Reading bayts results
#
bayts <- sf::st_read("./data/derived/CBERS-4-4A_WFI_003003_2023-01-01_2023-12-27_detection_evi-vh-chi09-aggregate-false-area-002.gpkg")

#
# Reading DETER polygons for Rondonia
#
deter <- sf::st_read("./data/raw/RO_DETER.gpkg")

#
# Reading region of interest area 
#
ext_area <- sf::st_read("./data/raw/roi_ext.gpkg")

#
# Transforming roi polygon to the projection of bayts
#
ext_area <- sf::st_transform(ext_area, crs = sf::st_crs(bayts))

#
# Transforming deter polygons to the projection of bayts
#
deter <- sf::st_transform(deter, crs = sf::st_crs(bayts))

#
# Filtering only polygons that intersects with roi area
#
deter_filt <- sf::st_intersects(deter, ext_area, sparse = FALSE)
deter_filt <- deter[apply(deter_filt, 1, any),]

#
# Calculating deter area polygons in m2
#
deter_filt[["aream2_deter"]] <- sf::st_area(deter_filt)

#
# Filtering bayts points that intersects with deter polygons
#
bayts_pts <- sf::st_intersects(bayts, deter_filt, sparse = FALSE)
bayts_pts <- bayts[apply(bayts_pts, 1, any),]

#
# Calculating bayts area in m2
#
bayts_pts$aream2_res <- sf::st_area(bayts_pts)

#
# Creating new geometry column in bayts points
#
bayts_pts$geometry_pts <- bayts_pts$geom

#
# Grouping and join bayts points into same table
#
deter_res <- dplyr::group_by(
  deter_filt, .data[["CLASSNAME"]]
) |>
  sf::st_join(
    y = bayts_pts, join = sf::st_intersects, left = FALSE
  )

#
# Transforming to date object
#
deter_res$date <- as.Date(deter_res$date)

#
# Mean detection time differences between DETER and BayTS
#
deter_res[, c("FID", "CLASSNAME", "VIEW_DATE", "date")] |>
    dplyr::group_by(.data[["FID"]], .data[["CLASSNAME"]], .data[["VIEW_DATE"]], .add = TRUE) |>
    dplyr::summarise(mean_date = mean(.data[["date"]], na.rm = TRUE)) |>
    dplyr::mutate(diff = as.integer(difftime(mean_date, VIEW_DATE)))  |>
    dplyr::group_by(CLASSNAME) |>
    dplyr::summarise(diff_mean = mean(diff))

#
# Comparison between areas measured by DETER and BayTS for each disturbance class
#
deter_res[, c("FID", "CLASSNAME", "aream2_deter", "aream2_res")] |>
    dplyr::group_by(.data[["FID"]], .data[["CLASSNAME"]], .data[["aream2_deter"]], .add = TRUE) |>
    dplyr::summarise(sum_area_res = sum(.data[["aream2_res"]], na.rm = TRUE)) |>
    dplyr::group_by(.data[["CLASSNAME"]]) |>
    dplyr::summarise(sum_area_res = sum(.data[["sum_area_res"]]), sum_deter_area = sum(.data[["aream2_deter"]]))
