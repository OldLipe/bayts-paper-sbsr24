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
bayts_filt <- sf::st_intersects(bayts, deter_filt, sparse = FALSE)
bayts_filt <- bayts[apply(bayts_filt, 1, any),]

#
# Calculating bayts area in m2
#
bayts_filt[["aream2_bayts"]] <- sf::st_area(bayts_filt)

#
# Creating new geometry column in bayts points
#
bayts_filt[["geometry_bayts"]] <- bayts_filt$geom

#
# Grouping and join bayts points into same table
#
deter_res <- dplyr::group_by(
  deter_filt, .data[["CLASSNAME"]]
) |>
  sf::st_join(
    y = bayts_filt, join = sf::st_intersects, left = FALSE
  )

#
# Transforming date character to date object
#
deter_res[["date"]] <- as.Date(deter_res[["date"]])

#
# Renaming columns name
#
deter_res <- dplyr::rename(
  deter_res, dplyr::all_of(c("date_bayts" = "date", "date_deter" = "VIEW_DATE"))
)

#
# Mean detection time differences between DETER and BayTS
#
deter_res[, c("FID", "CLASSNAME", "date_deter", "date_bayts")] |>
    dplyr::group_by(.data[["FID"]], .data[["CLASSNAME"]], .data[["date_deter"]], .add = TRUE) |>
    dplyr::summarise(mean_date_bayts = mean(.data[["date_bayts"]], na.rm = TRUE)) |>
    dplyr::mutate(diff = as.integer(difftime(mean_date_bayts, date_deter)))  |>
    dplyr::group_by(CLASSNAME) |>
    dplyr::summarise(diff_detectetion_date_mean = mean(diff))

#
# Comparison between areas measured by DETER and BayTS for each disturbance class
#
deter_res[, c("FID", "CLASSNAME", "aream2_deter", "aream2_bayts")] |>
    dplyr::group_by(.data[["FID"]], .data[["CLASSNAME"]], .data[["aream2_deter"]], .add = TRUE) |>
    dplyr::summarise(sum_area_bayts = sum(.data[["aream2_bayts"]], na.rm = TRUE)) |>
    dplyr::group_by(.data[["CLASSNAME"]]) |>
    dplyr::summarise(sum_deter_area = sum(.data[["aream2_deter"]]), sum_area_bayts = sum(.data[["sum_area_bayts"]]))
