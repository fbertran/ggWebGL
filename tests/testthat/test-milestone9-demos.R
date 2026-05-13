locate_milestone9_file <- function(path_parts, installed_parts = path_parts[-1L]) {
  root <- normalizePath(file.path(testthat::test_path(), "..", ".."), winslash = "/", mustWork = FALSE)
  candidates <- c(
    do.call(file.path, as.list(c(root, path_parts))),
    do.call(system.file, c(as.list(installed_parts), package = "ggWebGL"))
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) {
    return(NA_character_)
  }
  candidates[[1L]]
}

load_milestone9_script <- function(path_parts, installed_parts = path_parts[-1L]) {
  path <- locate_milestone9_file(path_parts, installed_parts)
  if (is.na(path)) {
    skip(paste("Milestone 9 helper is unavailable:", paste(path_parts, collapse = "/")))
  }
  env <- new.env(parent = asNamespace("ggWebGL"))
  sys.source(path, envir = env)
  env
}

expect_no_private_submission_terms <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_false(grepl("SIGGRAPH|poster|submission|claim-to-evidence|selected figure", text, ignore.case = TRUE))
}

test_that("million-point embedding demo is deterministic and uses compact transport when dense", {
  env <- load_milestone9_script(
    c("inst", "examples", "htmlwidget", "million-point-embedding.R"),
    c("examples", "htmlwidget", "million-point-embedding.R")
  )

  first <- env$embedding_cloud_data(1000L)
  second <- env$embedding_cloud_data(1000L)
  expect_equal(first, second)
  expect_equal(nrow(first), 1000L)
  expect_true(all(c("x", "y", "cluster") %in% names(first)))
  expect_true(all(is.finite(first$x)))
  expect_true(all(is.finite(first$y)))

  widget <- env$embedding_widget(point_count = 1000L, transport_threshold = 500L, height = 260)
  expect_s3_class(widget, "htmlwidget")
  expect_equal(widget$x$webgl$shader, "density_splat")
  expect_equal(widget$x$render$point_count, 1000L)
  expect_equal(widget$x$render$transport$mode, "auto")
  expect_equal(widget$x$render$transport$compact_layers, 1L)
  expect_equal(widget$x$render$transport$compact_point_count, 1000L)
  expect_equal(widget$x$render$selection$mode, "brush")
})

test_that("surface and mesh gallery demos build renderer widgets", {
  env <- load_milestone9_script(
    c("inst", "examples", "htmlwidget", "surface-gallery.R"),
    c("examples", "htmlwidget", "surface-gallery.R")
  )

  surface <- env$surface_gallery_volcano_widget(height = 260)
  expect_s3_class(surface, "htmlwidget")
  expect_equal(surface$x$render$dimension, "3d")
  expect_gt(surface$x$render$surface_triangle_count, 0L)
  expect_equal(surface$x$render$panels[[1L]]$layers[[1L]]$type, "surface")

  mesh <- env$surface_gallery_mesh_widget(height = 260)
  expect_s3_class(mesh, "htmlwidget")
  expect_equal(mesh$x$render$dimension, "3d")
  expect_gt(mesh$x$render$mesh_triangle_count, 0L)
  expect_equal(mesh$x$render$panels[[1L]]$layers[[1L]]$type, "mesh")
})

test_that("workflow comparison keeps static and WebGL paths available", {
  env <- load_milestone9_script(
    c("inst", "examples", "htmlwidget", "workflow-comparison.R"),
    c("examples", "htmlwidget", "workflow-comparison.R")
  )

  pair <- env$workflow_comparison_pair(120L)
  expect_s3_class(pair$static, "ggplot")
  expect_s3_class(pair$webgl, "htmlwidget")
  expect_equal(pair$webgl$x$webgl$shader, "density_splat")
  expect_equal(pair$webgl$x$render$point_count, 120L)
})

test_that("interactive scene Shiny demo is guarded and source-only safe", {
  path <- locate_milestone9_file(
    c("inst", "examples", "shiny", "interactive-scene-demo.R"),
    c("examples", "shiny", "interactive-scene-demo.R")
  )
  expect_false(is.na(path))
  if (is.na(path)) {
    return(invisible())
  }
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_match(text, "requireNamespace\\(\"shiny\", quietly = TRUE\\)")
  expect_match(text, "ggWebGLOutput", fixed = TRUE)
  expect_match(text, "renderGgWebGL", fixed = TRUE)
  expect_match(text, "input\\$scene_hover")
  expect_match(text, "input\\$scene_selection")
  expect_match(text, "input\\$scene_camera")
  expect_match(text, "input\\$scene_time")
  expect_no_private_submission_terms(path)
})

test_that("scene-type benchmark helper emits stable manual metric rows", {
  env <- load_milestone9_script(
    c("inst", "benchmarks", "benchmark-scene-types.R"),
    c("benchmarks", "benchmark-scene-types.R")
  )

  columns <- env$benchmark_scene_columns()
  expect_true(all(c(
    "scene_id", "serialized_bytes", "artifact_bytes", "startup_latency_ms",
    "first_interactive_frame_ms", "selection_latency_ms", "median_fps",
    "p95_fps", "browser", "gpu_renderer", "pixel_width", "pixel_height",
    "artifact_html", "artifact_csv", "status"
  ) %in% columns))

  output_dir <- tempfile("ggwebgl-scene-bench-")
  dir.create(output_dir)
  metrics <- env$benchmark_scene_types(
    output_dir = output_dir,
    scenes = "embedding",
    point_count = 1000L,
    include_browser = FALSE,
    selfcontained = FALSE
  )
  expect_equal(nrow(metrics), 1L)
  expect_equal(metrics$scene_id, "embedding")
  expect_equal(metrics$status, "browser_skipped")
  expect_gt(metrics$serialized_bytes, 0)
  expect_true(file.exists(metrics$artifact_html))
  expect_true(file.exists(metrics$artifact_csv))
})

test_that("Milestone 9 public-facing sources avoid private submission wording", {
  paths <- c(
    locate_milestone9_file(c("inst", "examples", "htmlwidget", "million-point-embedding.R"), c("examples", "htmlwidget", "million-point-embedding.R")),
    locate_milestone9_file(c("inst", "examples", "htmlwidget", "surface-gallery.R"), c("examples", "htmlwidget", "surface-gallery.R")),
    locate_milestone9_file(c("inst", "examples", "htmlwidget", "workflow-comparison.R"), c("examples", "htmlwidget", "workflow-comparison.R")),
    locate_milestone9_file(c("inst", "examples", "shiny", "interactive-scene-demo.R"), c("examples", "shiny", "interactive-scene-demo.R")),
    locate_milestone9_file(c("inst", "benchmarks", "benchmark-scene-types.R"), c("benchmarks", "benchmark-scene-types.R")),
    locate_milestone9_file(c("vignettes", "surface-mesh-showcase.Rmd"), c("doc", "surface-mesh-showcase.Rmd")),
    locate_milestone9_file(c("vignettes", "interactive-benchmarks.Rmd"), c("doc", "interactive-benchmarks.Rmd"))
  )
  paths <- paths[!is.na(paths)]
  expect_gt(length(paths), 0L)
  for (path in paths) {
    expect_no_private_submission_terms(path)
  }
})
