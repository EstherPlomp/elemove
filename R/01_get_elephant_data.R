#' ---
#' output: html_document
#' editor_options: 
#'   chunk_output_type: console
#' ---
#' 
#' # Getting Elephant Data
#' 
#' ## Load libraries
#' 
## -----------------------------------------------------------------------------
# load libs
library(move)
library(data.table)
library(sf)

#' 
#' ## Get elephant data from _Movebank_
#' 
## -----------------------------------------------------------------------------
message("acquiring elephant data")
# check if local data exists and then get if not
if (!file.exists("data/data_lines_elephants.gpkg")) {
  data <- getDataRepositoryData("doi:10.5441/001/1.403h24q5")

  # save as rdata
  save(data, file = "data/elephant_data.Rdata")
  message("acquired elephant data")
} else {
  message("elephant data already available")
}

# extract data from the move object
# which is the most labyrinthine object class ever

#' 
#' ## Extract useful data from `move` object
#' 
## -----------------------------------------------------------------------------
# get coordinates, id, and time from the movestack
# first split it because we know how lists work
# it behaves like a list
data_coords <- split(data)

# get data
data_coords <- Map(function(le, tag_id) {
  dt <- data.table(
    cbind(
      coordinates(le),
      timestamps(le)
    ),
    tag_id
  )
  setnames(dt, c("x", "y", "time", "id"))
}, data_coords, names(data_coords))

#' 
## -----------------------------------------------------------------------------
# remove data and clear garbage
rm(data)
gc()

#' 
#' ## Make elephant points into paths
#' 
## -----------------------------------------------------------------------------
# make multilinestring of elephant paths
geometry <- st_sfc(
  lapply(data_coords, function(x) {
    st_linestring(
      as.matrix(x[, c("x", "y")])
    )
  }),
  crs = 4326
)

# retransform
geometry <- st_transform(geometry, 32736)

#' 
#' ## Make `sf` data frame
#' 
## -----------------------------------------------------------------------------
# get data
data_sf <- mapply(
  function(df) {
    df[1, c("id")]
  },
  data_coords,
  SIMPLIFY = FALSE
)

# add geometry
data_sf <- rbindlist(data_sf)
data_sf[, geometry := geometry]

# make sf
data_sf <- st_sf(data_sf, crs = 32736)

# save
st_write(data_sf,
  dsn = "data/data_lines_elephants.gpkg",
  append = FALSE
)

message("elephant data converted to paths and saved")

