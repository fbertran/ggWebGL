locate_shapviz3d_renderer_example <- function() {
  path <- file.path(
    normalizePath(file.path(testthat::test_path(), "..", ".."), mustWork = TRUE),
    "inst",
    "examples",
    "htmlwidget",
    "downstream-shapviz3d-views.R"
  )
  if (!file.exists(path)) {
    return(NA_character_)
  }
  path
}

test_that("downstream shapViz3D renderer example is guarded and renderer-focused", {
  example_path <- locate_shapviz3d_renderer_example()

  if (is.na(example_path)) {
    skip("downstream shapViz3D example is unavailable in this installed-package test context.")
  }

  text <- paste(readLines(example_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("requireNamespace\\(\"shapViz3D\"", text))
  expect_true(grepl("density_splat", text, fixed = TRUE))
  expect_true(grepl("pan\", \"zoom\", \"hover", text, fixed = TRUE))
  expect_false(grepl("library\\(shapViz3D", text))
  expect_false(grepl("waterfall", text, ignore.case = TRUE))
})

test_that("downstream shapViz3D renderer example skips cleanly or returns widgets", {
  example_path <- locate_shapviz3d_renderer_example()

  if (is.na(example_path)) {
    skip("downstream shapViz3D example is unavailable in this installed-package test context.")
  }

  env <- new.env(parent = globalenv())
  expect_no_error(sys.source(example_path, envir = env))
  expect_true(exists("downstream_shapviz3d_widgets", envir = env))

  widgets <- env$downstream_shapviz3d_widgets()
  if (is.null(widgets)) {
    succeed()
    return(invisible())
  }

  expect_named(widgets, c("surface", "cloud"))
  expect_true(all(vapply(widgets, inherits, logical(1), what = "htmlwidget")))
  expect_true("raster" %in% widgets$surface$x$render$primitives)
  expect_true("points" %in% widgets$cloud$x$render$primitives)
})
