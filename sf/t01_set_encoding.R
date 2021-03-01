library(tidyverse)
library(sf)
library(units)
library(glue)

# ------------------------------------------------------------------------------
# パラメータ
# ------------------------------------------------------------------------------
target_layer  <- "data/summit_routes"

path_gsiline  <- glue("{target_layer}.shp")

path_walkarea <- glue("{target_layer}_walkarea.shp")
onesidewidth  <- set_units(1000L, "mm") # 根拠はない
as_walkarea   <- compose(
    st_union,
    partial(st_buffer, dist = onesidewidth)
)
st_write2 <- partial(
    st_write, 
    ... =,
    delete_dsn    = file.exists(..2),
    layer_options = c("ENCODING=UTF-8"),
)

path_changespeed_area <- glue("{target_layer}_speedchangearea.shp")
cs_attr <- sym("grp") # 変速歩行領域作成のためのグループ


# ------------------------------------------------------------------------------
# データの読み込み
# ------------------------------------------------------------------------------
gsiline <- read_sf(path_gsiline, options = c("ENCODING=UTF-8"))

# ------------------------------------------------------------------------------
# 全体の歩行領域の作成
# ------------------------------------------------------------------------------
road_area <- 
    gsiline %>%
    as_walkarea()
ret <- tibble(row_id = 1, geometry = road_area)
st_write2(ret, path_walkarea)

# ------------------------------------------------------------------------------
# グループごとの変速領域の作成
# ------------------------------------------------------------------------------
ret <-     
    gsiline %>%
    group_by(!!cs_attr) %>%
    summarise(geomtry = as_walkarea(geometry)) %>%
    ungroup()
st_write2(ret, path_changespeed_area)

