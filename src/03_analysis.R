res <- sf::st_read("./data/derived/CBERS-4-4A_WFI_003003_2023-01-01_2023-12-27_detection_evi-vh-chi09-aggregate-false-area-002.gpkg")
deter <- sf::st_read("./data/raw/RO_DETER.gpkg")
ext_area <- sf::st_read("./data/raw/area2_ext.gpkg")

ext_area <- sf::st_transform(ext_area, crs = sf::st_crs(res))

deter <- sf::st_transform(deter, crs = sf::st_crs(res))
deter$aream2_deter <- sf::st_area(deter)
deter_filt <- sf::st_intersects(deter, ext_area, sparse = FALSE)
deter_filt <- deter[apply(deter_filt, 1, any),]
deter_filt$aream2_deter <- sf::st_area(deter_filt)


res_pts <- sf::st_intersects(res, deter_filt, sparse = FALSE)
res_pts <- res[apply(res_pts, 1, any),]
res_pts$aream2_res <- sf::st_area(res_pts)
res_pts$geometry_pts <- res_pts$geom


deter_res <- dplyr::group_by(deter_filt, .data[["CLASSNAME"]]) |>
    sf::st_join(y = res_pts, join = sf::st_intersects, left = FALSE)
deter_res$date <- as.Date(deter_res$date)
saveRDS(deter_res, "./deter_results.rds")

deter_res[, c("FID", "CLASSNAME", "VIEW_DATE", "date")] |>
    dplyr::group_by(.data[["FID"]], .data[["CLASSNAME"]], .data[["VIEW_DATE"]], .add = TRUE) |>
    dplyr::summarise(mean_date = mean(.data[["date"]], na.rm = TRUE)) |>
    dplyr::mutate(diff = as.integer(difftime(mean_date, VIEW_DATE)))  |>
    dplyr::group_by(CLASSNAME) |>
    dplyr::summarise(diff_mean = mean(diff))

deter_res[, c("FID", "CLASSNAME", "aream2_deter", "aream2_res")] |>
    dplyr::group_by(.data[["FID"]], .data[["CLASSNAME"]], .data[["aream2_deter"]], .add = TRUE) |>
    dplyr::summarise(sum_area_res = sum(.data[["aream2_res"]], na.rm = TRUE)) |>
    dplyr::group_by(.data[["CLASSNAME"]]) |>
    dplyr::summarise(sum_area_res = sum(.data[["sum_area_res"]]), sum_deter_area = sum(.data[["aream2_deter"]]))
