ggwebgl_scene_version <- function() {
  2L
}

ggwebgl_coordinate_system <- function(dimension) {
  if (identical(tolower(as.character(dimension)[[1L]] %||% "2d"), "3d")) {
    "cartesian3d"
  } else {
    "cartesian2d"
  }
}

ggwebgl_enrich_scene_render <- function(render, webgl) {
  webgl <- normalise_webgl_options(webgl)
  explicit_fields <- attr(webgl, "explicit_fields", exact = TRUE) %||% character()
  surface_defaults_3d <- "surface" %in% (render$primitives %||% character()) &&
    !any(c("view", "dimension", "camera", "projection") %in% explicit_fields)
  if (isTRUE(surface_defaults_3d)) {
    webgl$view <- normalise_view(
      list(dimension = "3d", projection = "perspective", controller = "orbit"),
      dimension = "3d",
      projection = "perspective",
      controller = "orbit"
    )
    webgl$dimension <- "3d"
    webgl$projection <- "perspective"
    webgl$camera <- "orbit"
    webgl$depth_test <- TRUE
  }
  render$dimension <- webgl$view$dimension %||% webgl$dimension %||% "2d"
  render$coordinate_system <- render$coordinate_system %||% ggwebgl_coordinate_system(render$dimension)
  render$camera <- compact_list(list(
    mode = webgl$view$controller %||% webgl$camera %||% "orbit",
    controller = webgl$view$controller %||% webgl$camera %||% "orbit",
    projection = webgl$view$projection %||% webgl$projection %||% "orthographic",
    state = webgl$view$state %||% webgl$camera_state %||% list()
  ))
  render$depth_test <- isTRUE(webgl$depth_test)
  render$blend_mode <- webgl$blend_mode %||% "auto"
  render$selection <- webgl$selection %||% list(mode = "none", highlight = TRUE, emit = TRUE)
  if (!is.null(webgl$timeline)) {
    render$timeline <- webgl$timeline
  }
  render
}
