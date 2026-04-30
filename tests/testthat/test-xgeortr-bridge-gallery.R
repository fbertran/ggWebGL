locate_xgeortr_bridge_example <- function() {
  candidates <- c(
    file.path(getwd(), "inst", "examples", "htmlwidget", "xgeortr-bridge-gallery.R"),
    file.path(getwd(), "tests", "testthat", "..", "..", "inst", "examples", "htmlwidget", "xgeortr-bridge-gallery.R"),
    system.file("examples", "htmlwidget", "xgeortr-bridge-gallery.R", package = "ggWebGL")
  )
  candidates <- unique(normalizePath(candidates, winslash = "/", mustWork = FALSE))
  found <- candidates[file.exists(candidates)]

  if (!length(found)) {
    return(NA_character_)
  }

  found[[1L]]
}

test_that("optional XGeoRTR bridge example is renderer-native and guarded", {
  example_path <- locate_xgeortr_bridge_example()

  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  text <- paste(readLines(example_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("requireNamespace\\(\"XGeoRTR\"", text))
  expect_true(grepl("ggwebgl_layer_points", text, fixed = TRUE))
  expect_true(grepl("ggwebgl_layer_lines", text, fixed = TRUE))
  expect_true(grepl("ggwebgl_layer_vectors", text, fixed = TRUE))
  expect_true(grepl("ggwebgl_spec", text, fixed = TRUE))
  expect_true(grepl("zoom_region", text, fixed = TRUE))
  expect_true(grepl("viewport = zoom_region", text, fixed = TRUE))
  expect_false(grepl("geom_point_webgl", text, fixed = TRUE))
  expect_false(grepl("geom_line_webgl", text, fixed = TRUE))
})

test_that("XGeoRTR bridge example returns four named scenes when available", {
  example_path <- locate_xgeortr_bridge_example()

  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  env <- new.env(parent = globalenv())
  expect_no_error(sys.source(example_path, envir = env))
  expect_true(exists("ggwebgl_xgeortr_bridge_specs", envir = env))
  expect_true(exists("xgeortr_bridge_available", envir = env))

  if (!isTRUE(env$xgeortr_bridge_available())) {
    skip("XGeoRTR is unavailable for the optional bridge example.")
  }

  specs <- env$ggwebgl_xgeortr_bridge_specs()
  expect_named(specs, c("representative", "multiscale", "attribution", "structure"))

  representative_layers <- vapply(specs$representative$render$panels[[1L]]$layers, `[[`, character(1), "type")
  expect_true("points" %in% representative_layers)
  expect_true("vectors" %in% representative_layers)
  expect_gte(specs$representative$render$vector_count, 12L)
  expect_equal(specs$representative$render$grid, list(rows = 1L, cols = 1L))

  expect_equal(specs$multiscale$render$grid, list(rows = 1L, cols = 2L))
  expect_length(specs$multiscale$render$panels, 2L)
  expect_true(all(vapply(specs$multiscale$render$panels, function(panel) length(panel$layers) > 0L, logical(1))))
  expect_true("vectors" %in% specs$multiscale$render$primitives)
  zoom_box <- Filter(
    function(layer) identical(layer$geom %||% NULL, "xgeortr_bridge_zoom_box"),
    specs$multiscale$render$panels[[1L]]$layers
  )[[1L]]
  zoom_path <- zoom_box$paths[[1L]]
  expect_equal(range(zoom_path$x), specs$multiscale$render$panels[[2L]]$viewport$x)
  expect_equal(range(zoom_path$y), specs$multiscale$render$panels[[2L]]$viewport$y)

  attribution_layers <- vapply(specs$attribution$render$panels[[1L]]$layers, `[[`, character(1), "type")
  expect_true("points" %in% attribution_layers)

  attribution_demo <- env$build_xgeortr_bridge_state(seed = 20260424, n = 900L, balanced_groups = TRUE)
  expect_lte(length(unique(as.character(attribution_demo$plot_data$dominant_group))), 4L)

  structure_layers <- vapply(specs$structure$render$panels[[1L]]$layers, `[[`, character(1), "type")
  expect_true("points" %in% structure_layers)
  expect_true("lines" %in% structure_layers)
  expect_gte(specs$structure$render$path_count, 3L)
})

test_that("XGeoRTR bridge gallery exports HTML widgets when available", {
  example_path <- locate_xgeortr_bridge_example()

  expect_false(is.na(example_path))
  if (is.na(example_path)) {
    return(invisible())
  }

  env <- new.env(parent = globalenv())
  expect_no_error(sys.source(example_path, envir = env))

  if (!isTRUE(env$xgeortr_bridge_available())) {
    skip("XGeoRTR is unavailable for the optional bridge export.")
  }

  out_dir <- tempfile("ggwebgl-xgeortr-bridge-test-")
  files <- env$export_xgeortr_bridge_gallery(output_dir = out_dir, selfcontained = FALSE)

  expect_named(files, c("representative", "multiscale", "attribution", "structure"))
  expect_true(all(file.exists(unname(files))))
  expect_true(file.exists(attr(files, "index")))
})

test_that("pkgdown article list includes the XGeoRTR bridge vignette", {
  config_path <- testthat::test_path("..", "..", "inst", "_pkgdown.yml")

  if (!file.exists(config_path)) {
    skip("pkgdown config is unavailable in this installed-package test context.")
  }

  text <- paste(readLines(config_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("xgeortr-bridge", text, fixed = TRUE))
})
