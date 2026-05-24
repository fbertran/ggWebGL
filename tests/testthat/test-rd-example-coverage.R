required_example_topics <- c(
  "as_ggwebgl_spec.Rd",
  "as_ggwebgl_spec.xgeo_state.Rd",
  "geom_line_webgl.Rd",
  "geom_path_webgl.Rd",
  "geom_path3d_webgl.Rd",
  "geom_point_webgl.Rd",
  "geom_raster_webgl.Rd",
  "geom_rect_webgl.Rd",
  "geom_segment_webgl.Rd",
  "geom_tile_webgl.Rd",
  "ggWebGL.Rd",
  "ggWebGLOutput.Rd",
  "ggplot_webgl.Rd",
  "ggwebgl_example_data.Rd",
  "ggwebgl_layer_lines.Rd",
  "ggwebgl_layer_points.Rd",
  "ggwebgl_layer_raster.Rd",
  "ggwebgl_spec.Rd",
  "renderGgWebGL.Rd",
  "theme_webgl.Rd"
)

rd_has_examples <- function(path) {
  text <- readLines(path, warn = FALSE)
  any(grepl("^\\\\examples", text))
}

locate_man_dir <- function() {
  candidates <- c(
    file.path(getwd(), "man"),
    file.path(
      normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE),
      "man"
    )
  )
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

test_that("exported help topics include runnable example sections", {
  man_dir <- locate_man_dir()

  if (is.na(man_dir)) {
    skip("man directory is unavailable in this test context.")
  }

  paths <- file.path(man_dir, required_example_topics)

  expect_true(all(file.exists(paths)))
  for (path in paths) {
    expect_true(
      rd_has_examples(path),
      info = basename(path)
    )
  }
})
